import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/library_models.dart';
import 'package:flutter_application_1/services/library_local_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory temporaryDirectory;
  late LibraryLocalStore store;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'sip-library-store-test-',
    );
    store = LibraryLocalStore(
      databasePath:
          '${temporaryDirectory.path}${Platform.pathSeparator}library.db',
      factory: databaseFactoryFfi,
    );
  });

  tearDown(() async {
    await store.close();
    await temporaryDirectory.delete(recursive: true);
  });

  Future<void> initialize({int copies = 1}) async {
    await store.initialize(
      initialBooks: [
        Book(
          id: 10,
          title: 'Buku Uji',
          author: 'Pengarang Uji',
          category: 'Kategori Uji',
          copies: copies,
        ),
      ],
      initialMembers: [
        const Member(
          id: 20,
          name: 'Anggota Uji',
          phone: '081234567890',
          email: 'anggota@example.test',
        ),
      ],
    );
  }

  test('loans persist and stock availability changes exactly once', () async {
    await initialize();
    final firstSnapshot = await store.load();
    final loan = await store.createLoan(
      memberId: firstSnapshot.members.single.id,
      bookId: firstSnapshot.books.single.id,
      borrowedAt: DateTime(2026, 10, 19),
      dueAt: DateTime(2026, 10, 26),
      quantity: 1,
      ownerUserId: 'user-guru',
    );

    expect(
      () => store.createLoan(
        memberId: firstSnapshot.members.single.id,
        bookId: firstSnapshot.books.single.id,
        borrowedAt: DateTime(2026, 10, 19),
        dueAt: DateTime(2026, 10, 26),
        quantity: 1,
        ownerUserId: 'user-siswa',
      ),
      throwsFormatException,
    );

    final openAgain = LibraryLocalStore(
      databasePath:
          '${temporaryDirectory.path}${Platform.pathSeparator}library.db',
      factory: databaseFactoryFfi,
    );
    final persisted = await openAgain.load();
    expect(persisted.loans, hasLength(1));
    expect(persisted.loans.single.id, loan.id);
    expect(persisted.loans.single.status, 'Dipinjam');
    expect(persisted.loans.single.quantity, 1);

    final returned = await openAgain.returnLoan(
      loan.id,
      DateTime(2026, 10, 20),
    );
    expect(returned.status, 'Dikembalikan');
    expect(returned.returnedAt, DateTime(2026, 10, 20));
    await expectLater(
      openAgain.returnLoan(loan.id, DateTime(2026, 10, 21)),
      throwsStateError,
    );
    final finalSnapshot = await openAgain.load();
    expect(finalSnapshot.loans, hasLength(1));
    expect(finalSnapshot.loans.single.returnedAt, DateTime(2026, 10, 20));
    expect(finalSnapshot.books.single.copies, 1);
    await openAgain.close();
  });

  test('zero stock and invalid references are rejected', () async {
    await initialize(copies: 0);
    final snapshot = await store.load();
    await expectLater(
      store.createLoan(
        memberId: snapshot.members.single.id,
        bookId: snapshot.books.single.id,
        borrowedAt: DateTime(2026, 10, 19),
        dueAt: DateTime(2026, 10, 26),
        quantity: 1,
        ownerUserId: null,
      ),
      throwsFormatException,
    );
    await expectLater(
      store.createLoan(
        memberId: 999,
        bookId: snapshot.books.single.id,
        borrowedAt: DateTime(2026, 10, 19),
        dueAt: DateTime(2026, 10, 26),
        quantity: 1,
        ownerUserId: null,
      ),
      throwsStateError,
    );
  });

  test('seed data and CRUD changes survive store reopening', () async {
    await initialize();
    final added = await store.addBook(
      const Book(
        id: 0,
        title: 'Buku Tambahan',
        author: 'Pengarang',
        category: 'RPL',
        copies: 2,
      ),
    );
    await store.updateBook(
      Book(
        id: added.id,
        title: added.title,
        author: added.author,
        category: 'Informatika',
        copies: added.copies,
      ),
    );
    await store.addMember(
      const Member(
        id: 0,
        name: 'Anggota Tambahan',
        phone: '081200000000',
        email: 'baru@example.test',
      ),
    );
    await store.close();

    final reopened = LibraryLocalStore(
      databasePath:
          '${temporaryDirectory.path}${Platform.pathSeparator}library.db',
      factory: databaseFactoryFfi,
    );
    final snapshot = await reopened.initialize(
      initialBooks: const [],
      initialMembers: const [],
    );
    expect(snapshot.books, hasLength(2));
    expect(snapshot.books.last.category, 'Informatika');
    expect(snapshot.members, hasLength(2));
    await reopened.deleteBook(added.id);
    await reopened.deleteMember(snapshot.members.last.id);
    expect((await reopened.load()).books, hasLength(1));
    expect((await reopened.load()).members, hasLength(1));
    await reopened.close();
  });
}
