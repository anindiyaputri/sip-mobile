import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../models/library_models.dart';

class LibrarySnapshot {
  LibrarySnapshot({
    required List<Book> books,
    required List<Member> members,
    required List<Loan> loans,
  }) : books = List.unmodifiable(books),
       members = List.unmodifiable(members),
       loans = List.unmodifiable(loans);

  final List<Book> books;
  final List<Member> members;
  final List<Loan> loans;
}

class LibraryLocalStore {
  LibraryLocalStore({this.databasePath, this.factory});

  static const databaseName = 'sip_mobile_library.db';
  static const _databaseVersion = 1;
  static const _seedVersionKey = 'catalog_seed_version';
  static const _seedVersion = '1';

  final String? databasePath;
  final DatabaseFactory? factory;
  Future<Database>? _databaseFuture;

  DatabaseFactory get _databaseFactory => factory ?? databaseFactory;

  Future<Database> get _database => _databaseFuture ??= _openDatabase();

  Future<Database> _openDatabase() async {
    final path =
        databasePath ??
        '${await _databaseFactory.getDatabasesPath()}'
            '${Platform.pathSeparator}$databaseName';
    return _databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE books (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              author TEXT NOT NULL,
              category TEXT NOT NULL,
              copies INTEGER NOT NULL CHECK (copies >= 0)
            )
          ''');
          await database.execute('''
            CREATE TABLE members (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              phone TEXT NOT NULL,
              email TEXT NOT NULL COLLATE NOCASE UNIQUE
            )
          ''');
          await database.execute('''
            CREATE TABLE loans (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              book_id INTEGER NOT NULL REFERENCES books(id) ON DELETE RESTRICT,
              member_id INTEGER NOT NULL REFERENCES members(id) ON DELETE RESTRICT,
              book_title TEXT NOT NULL,
              member_name TEXT NOT NULL,
              borrowed_at TEXT NOT NULL,
              due_at TEXT NOT NULL,
              quantity INTEGER NOT NULL CHECK (quantity > 0),
              status TEXT NOT NULL CHECK (status IN ('Dipinjam', 'Dikembalikan')),
              returned_at TEXT,
              owner_user_id TEXT,
              CHECK (
                (status = 'Dipinjam' AND returned_at IS NULL) OR
                (status = 'Dikembalikan' AND returned_at IS NOT NULL)
              )
            )
          ''');
          await database.execute('''
            CREATE TABLE app_metadata (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
          await database.execute(
            'CREATE INDEX loans_member_id_idx ON loans(member_id)',
          );
          await database.execute(
            'CREATE INDEX loans_book_id_idx ON loans(book_id)',
          );
          await database.execute(
            'CREATE INDEX loans_borrowed_at_idx ON loans(borrowed_at)',
          );
          await database.execute(
            'CREATE INDEX loans_returned_at_idx ON loans(returned_at)',
          );
        },
      ),
    );
  }

  Future<LibrarySnapshot> initialize({
    required List<Book> initialBooks,
    required List<Member> initialMembers,
  }) async {
    final database = await _database;
    await database.transaction((transaction) async {
      final seed = await transaction.query(
        'app_metadata',
        where: 'key = ?',
        whereArgs: [_seedVersionKey],
        limit: 1,
      );
      if (seed.isNotEmpty) return;

      for (final book in initialBooks) {
        await transaction.insert('books', _bookValues(book));
      }
      for (final member in initialMembers) {
        await transaction.insert('members', _memberValues(member));
      }
      await transaction.insert('app_metadata', {
        'key': _seedVersionKey,
        'value': _seedVersion,
      });
    });
    return load();
  }

  Future<LibrarySnapshot> load() async {
    final database = await _database;
    final books = await database.query('books', orderBy: 'id');
    final members = await database.query('members', orderBy: 'id');
    final loans = await database.query('loans', orderBy: 'id');
    return LibrarySnapshot(
      books: books.map(_bookFromRow).toList(),
      members: members.map(_memberFromRow).toList(),
      loans: loans.map(_loanFromRow).toList(),
    );
  }

  Future<Book> addBook(Book book) async {
    final database = await _database;
    final id = await database.insert('books', _bookValues(book));
    return Book(
      id: id,
      title: book.title,
      author: book.author,
      category: book.category,
      copies: book.copies,
    );
  }

  Future<void> updateBook(Book book) async {
    final database = await _database;
    await database.transaction((transaction) async {
      final count = Sqflite.firstIntValue(
        await transaction.rawQuery(
          'SELECT COALESCE(SUM(quantity), 0) FROM loans WHERE book_id = ? AND status = ?',
          [book.id, 'Dipinjam'],
        ),
      )!;
      if (book.copies < count) {
        throw const FormatException(
          'Jumlah eksemplar tidak dapat kurang dari buku yang sedang dipinjam.',
        );
      }
      final changed = await transaction.update(
        'books',
        _bookValues(book),
        where: 'id = ?',
        whereArgs: [book.id],
      );
      if (changed != 1) throw StateError('Buku tidak ditemukan.');
    });
  }

  Future<void> deleteBook(int bookId) async {
    final database = await _database;
    final relatedLoans = await database.query(
      'loans',
      columns: ['id'],
      where: 'book_id = ?',
      whereArgs: [bookId],
      limit: 1,
    );
    if (relatedLoans.isNotEmpty) {
      throw StateError(
        'Buku yang memiliki riwayat transaksi tidak dapat dihapus.',
      );
    }
    final deleted = await database.delete(
      'books',
      where: 'id = ?',
      whereArgs: [bookId],
    );
    if (deleted != 1) throw StateError('Buku tidak ditemukan.');
  }

  Future<Member> addMember(Member member) async {
    final database = await _database;
    final id = await database.insert('members', _memberValues(member));
    return Member(
      id: id,
      name: member.name,
      phone: member.phone,
      email: member.email,
    );
  }

  Future<void> updateMember(Member member) async {
    final database = await _database;
    final changed = await database.update(
      'members',
      _memberValues(member),
      where: 'id = ?',
      whereArgs: [member.id],
    );
    if (changed != 1) throw StateError('Anggota tidak ditemukan.');
  }

  Future<void> deleteMember(int memberId) async {
    final database = await _database;
    final relatedLoans = await database.query(
      'loans',
      columns: ['id'],
      where: 'member_id = ?',
      whereArgs: [memberId],
      limit: 1,
    );
    if (relatedLoans.isNotEmpty) {
      throw StateError(
        'Anggota yang memiliki riwayat transaksi tidak dapat dihapus.',
      );
    }
    final deleted = await database.delete(
      'members',
      where: 'id = ?',
      whereArgs: [memberId],
    );
    if (deleted != 1) throw StateError('Anggota tidak ditemukan.');
  }

  Future<Loan> createLoan({
    required int memberId,
    required int bookId,
    required DateTime borrowedAt,
    required DateTime dueAt,
    required int quantity,
    required String? ownerUserId,
  }) async {
    if (quantity < 1) {
      throw const FormatException('Jumlah buku minimal satu.');
    }
    if (!dueAt.isAfter(borrowedAt)) {
      throw const FormatException(
        'Batas pengembalian harus setelah tanggal pinjam.',
      );
    }
    final database = await _database;
    return database.transaction((transaction) async {
      final bookRows = await transaction.query(
        'books',
        where: 'id = ?',
        whereArgs: [bookId],
        limit: 1,
      );
      if (bookRows.isEmpty) throw StateError('Buku tidak ditemukan.');
      final memberRows = await transaction.query(
        'members',
        where: 'id = ?',
        whereArgs: [memberId],
        limit: 1,
      );
      if (memberRows.isEmpty) throw StateError('Anggota tidak ditemukan.');
      final book = _bookFromRow(bookRows.single);
      final activeQuantity = Sqflite.firstIntValue(
        await transaction.rawQuery(
          'SELECT COALESCE(SUM(quantity), 0) FROM loans WHERE book_id = ? AND status = ?',
          [bookId, 'Dipinjam'],
        ),
      )!;
      if (activeQuantity + quantity > book.copies) {
        throw const FormatException(
          'Buku tidak tersedia karena stok sudah habis.',
        );
      }
      final member = _memberFromRow(memberRows.single);
      final id = await transaction.insert('loans', {
        'book_id': book.id,
        'member_id': member.id,
        'book_title': book.title,
        'member_name': member.name,
        'borrowed_at': borrowedAt.toIso8601String(),
        'due_at': dueAt.toIso8601String(),
        'quantity': quantity,
        'status': 'Dipinjam',
        'owner_user_id': ownerUserId,
      });
      return Loan(
        id: id,
        bookId: book.id,
        memberId: member.id,
        bookTitle: book.title,
        memberName: member.name,
        borrowedAt: borrowedAt,
        dueAt: dueAt,
        quantity: quantity,
        ownerUserId: ownerUserId,
      );
    });
  }

  Future<Loan> returnLoan(int loanId, DateTime returnedAt) async {
    final database = await _database;
    return database.transaction((transaction) async {
      final rows = await transaction.query(
        'loans',
        where: 'id = ?',
        whereArgs: [loanId],
        limit: 1,
      );
      if (rows.isEmpty) throw StateError('Transaksi tidak ditemukan.');
      final current = rows.single;
      if (current['status'] != 'Dipinjam' || current['returned_at'] != null) {
        throw StateError('Transaksi ini sudah dikembalikan.');
      }
      final changed = await transaction.update(
        'loans',
        {'returned_at': returnedAt.toIso8601String(), 'status': 'Dikembalikan'},
        where: 'id = ? AND status = ? AND returned_at IS NULL',
        whereArgs: [loanId, 'Dipinjam'],
      );
      if (changed != 1) {
        throw StateError('Transaksi sudah diproses oleh proses lain.');
      }
      return _loanFromRow({
        ...current,
        'returned_at': returnedAt.toIso8601String(),
        'status': 'Dikembalikan',
      });
    });
  }

  Future<void> close() async {
    final future = _databaseFuture;
    _databaseFuture = null;
    if (future != null) await (await future).close();
  }

  Future<void> resetForTesting() async {
    await close();
    final path =
        databasePath ??
        '${await _databaseFactory.getDatabasesPath()}'
            '${Platform.pathSeparator}$databaseName';
    await _databaseFactory.deleteDatabase(path);
  }

  Map<String, Object?> _bookValues(Book book) => {
    'title': book.title.trim(),
    'author': book.author.trim(),
    'category': book.category.trim(),
    'copies': book.copies,
  };

  Map<String, Object?> _memberValues(Member member) => {
    'name': member.name.trim(),
    'phone': member.phone.trim(),
    'email': member.email.trim(),
  };

  Book _bookFromRow(Map<String, Object?> row) => Book(
    id: row['id']! as int,
    title: row['title']! as String,
    author: row['author']! as String,
    category: row['category']! as String,
    copies: row['copies']! as int,
  );

  Member _memberFromRow(Map<String, Object?> row) => Member(
    id: row['id']! as int,
    name: row['name']! as String,
    phone: row['phone']! as String,
    email: row['email']! as String,
  );

  Loan _loanFromRow(Map<String, Object?> row) => Loan(
    id: row['id']! as int,
    bookId: row['book_id']! as int,
    memberId: row['member_id']! as int,
    bookTitle: row['book_title']! as String,
    memberName: row['member_name']! as String,
    borrowedAt: DateTime.parse(row['borrowed_at']! as String),
    dueAt: DateTime.parse(row['due_at']! as String),
    quantity: row['quantity']! as int,
    returnedAt: row['returned_at'] == null
        ? null
        : DateTime.parse(row['returned_at']! as String),
    ownerUserId: row['owner_user_id'] as String?,
  );
}
