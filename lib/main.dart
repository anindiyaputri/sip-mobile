import 'package:flutter/material.dart';

void main() {
  runApp(const SipMobileApp());
}

class SipMobileApp extends StatelessWidget {
  const SipMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SIP Mobile',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3157D5)),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const DashboardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3157D5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.local_library,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Selamat datang',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Masuk ke SIP Mobile untuk mengelola perpustakaan.',
                      style: TextStyle(color: Colors.black54, fontSize: 15),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'nama@email.com',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty || !email.contains('@')) {
                          return 'Masukkan alamat email yang valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _signIn(),
                      decoration: InputDecoration(
                        labelText: 'Kata sandi',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Tampilkan kata sandi'
                              : 'Sembunyikan kata sandi',
                          onPressed: () => setState(() {
                            _obscurePassword = !_obscurePassword;
                          }),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kata sandi wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _signIn,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: const Text('Masuk'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.copies,
  });

  final int id;
  final String title;
  final String author;
  final String category;
  final int copies;
}

class Member {
  const Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
  });

  final int id;
  final String name;
  final String phone;
  final String email;
}

class Loan {
  const Loan({
    required this.id,
    required this.bookId,
    required this.memberId,
    required this.bookTitle,
    required this.memberName,
    required this.borrowedAt,
    required this.dueAt,
    this.returnedAt,
  });

  final int id;
  final int bookId;
  final int memberId;
  final String bookTitle;
  final String memberName;
  final DateTime borrowedAt;
  final DateTime dueAt;
  final DateTime? returnedAt;
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  String _bookSearch = '';
  int _nextBookId = 4;
  int _nextMemberId = 3;
  int _nextLoanId = 3;

  late final List<Book> _books = [
    const Book(
      id: 1,
      title: 'Pemrograman Dasar',
      author: 'Abdul Kadir',
      category: 'Teknologi',
      copies: 4,
    ),
    const Book(
      id: 2,
      title: 'Jaringan Komputer',
      author: 'Siti Rahma',
      category: 'Teknologi',
      copies: 3,
    ),
    const Book(
      id: 3,
      title: 'Belajar Flutter',
      author: 'Budi Santoso',
      category: 'Teknologi',
      copies: 5,
    ),
  ];

  late final List<Member> _members = [
    const Member(
      id: 1,
      name: 'Andi Saputra',
      phone: '081234567890',
      email: 'andi@email.com',
    ),
    const Member(
      id: 2,
      name: 'Siti Rahma',
      phone: '081298765432',
      email: 'siti@email.com',
    ),
  ];

  late final List<Loan> _loans = [
    Loan(
      id: 1,
      bookId: 1,
      memberId: 1,
      bookTitle: 'Pemrograman Dasar',
      memberName: 'Andi Saputra',
      borrowedAt: DateTime.now().subtract(const Duration(days: 2)),
      dueAt: DateTime.now().add(const Duration(days: 5)),
    ),
    Loan(
      id: 2,
      bookId: 2,
      memberId: 2,
      bookTitle: 'Jaringan Komputer',
      memberName: 'Siti Rahma',
      borrowedAt: DateTime.now().subtract(const Duration(days: 1)),
      dueAt: DateTime.now().add(const Duration(days: 6)),
    ),
  ];

  int _activeLoansForBook(int bookId) => _loans
      .where((loan) => loan.bookId == bookId && loan.returnedAt == null)
      .length;

  int _availableCopies(Book book) => book.copies - _activeLoansForBook(book.id);

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _addLoan() async {
    final availableBooks = _books
        .where((book) => _availableCopies(book) > 0)
        .toList();
    if (_members.isEmpty || availableBooks.isEmpty) {
      _showMessage(
        _members.isEmpty
            ? 'Tambahkan anggota sebelum mencatat peminjaman.'
            : 'Tidak ada buku yang tersedia untuk dipinjam.',
      );
      return;
    }

    final loan = await _showLoanForm(context, availableBooks, _members);
    if (!mounted || loan == null) return;
    setState(() {
      _loans.add(
        Loan(
          id: _nextLoanId++,
          bookId: loan.bookId,
          memberId: loan.memberId,
          bookTitle: loan.bookTitle,
          memberName: loan.memberName,
          borrowedAt: loan.borrowedAt,
          dueAt: loan.dueAt,
        ),
      );
    });
  }

  void _returnLoan(Loan loan) {
    setState(() {
      final index = _loans.indexWhere((item) => item.id == loan.id);
      if (index != -1) {
        final current = _loans[index];
        _loans[index] = Loan(
          id: current.id,
          bookId: current.bookId,
          memberId: current.memberId,
          bookTitle: current.bookTitle,
          memberName: current.memberName,
          borrowedAt: current.borrowedAt,
          dueAt: current.dueAt,
          returnedAt: DateTime.now(),
        );
      }
    });
    _showMessage('${loan.bookTitle} berhasil dikembalikan.');
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 1:
        return BooksPage(
          books: _books,
          availableCopies: _availableCopies,
          searchQuery: _bookSearch,
          onAdd: _addBook,
          onEdit: _editBook,
          onDelete: _deleteBook,
        );
      case 2:
        return MembersPage(
          members: _members,
          onAdd: _addMember,
          onEdit: _editMember,
          onDelete: _deleteMember,
        );
      case 3:
        return LoansPage(loans: _loans, onAdd: _addLoan, onReturn: _returnLoan);
      default:
        return DashboardContent(
          books: _books,
          members: _members,
          loans: _loans,
          onSelectTab: _selectTab,
          onSearch: (query) => setState(() => _bookSearch = query),
          onNotification: () => _showMessage('Belum ada notifikasi baru.'),
        );
    }
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _addBook() async {
    final book = await _showBookForm(context);
    if (!mounted || book == null) return;
    setState(() {
      _books.add(
        Book(
          id: _nextBookId++,
          title: book.title,
          author: book.author,
          category: book.category,
          copies: book.copies,
        ),
      );
    });
  }

  Future<void> _editBook(Book existing) async {
    final updated = await _showBookForm(context, existing: existing);
    if (!mounted || updated == null) return;
    setState(() {
      final index = _books.indexWhere((book) => book.id == existing.id);
      if (index != -1) {
        _books[index] = Book(
          id: existing.id,
          title: updated.title,
          author: updated.author,
          category: updated.category,
          copies: updated.copies < _activeLoansForBook(existing.id)
              ? _activeLoansForBook(existing.id)
              : updated.copies,
        );
      }
    });
  }

  void _deleteBook(Book book) {
    if (_activeLoansForBook(book.id) > 0) {
      _showMessage('Buku yang masih dipinjam tidak dapat dihapus.');
      return;
    }
    setState(() => _books.removeWhere((item) => item.id == book.id));
  }

  Future<void> _addMember() async {
    final member = await _showMemberForm(context);
    if (!mounted || member == null) return;
    setState(() {
      _members.add(
        Member(
          id: _nextMemberId++,
          name: member.name,
          phone: member.phone,
          email: member.email,
        ),
      );
    });
  }

  Future<void> _editMember(Member existing) async {
    final updated = await _showMemberForm(context, existing: existing);
    if (!mounted || updated == null) return;
    setState(() {
      final index = _members.indexWhere((member) => member.id == existing.id);
      if (index != -1) {
        _members[index] = Member(
          id: existing.id,
          name: updated.name,
          phone: updated.phone,
          email: updated.email,
        );
      }
    });
  }

  void _deleteMember(Member member) {
    final hasActiveLoan = _loans.any(
      (loan) => loan.memberId == member.id && loan.returnedAt == null,
    );
    if (hasActiveLoan) {
      _showMessage('Anggota yang masih memiliki pinjaman tidak dapat dihapus.');
      return;
    }
    setState(() => _members.removeWhere((item) => item.id == member.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Buku',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Anggota',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz),
            selectedIcon: Icon(Icons.swap_horiz),
            label: 'Transaksi',
          ),
        ],
      ),
    );
  }
}

// =====================================================
// DASHBOARD
// =====================================================

class DashboardContent extends StatelessWidget {
  const DashboardContent({
    super.key,
    required this.books,
    required this.members,
    required this.loans,
    required this.onSelectTab,
    required this.onSearch,
    required this.onNotification,
  });

  final List<Book> books;
  final List<Member> members;
  final List<Loan> loans;
  final ValueChanged<int> onSelectTab;
  final ValueChanged<String> onSearch;
  final VoidCallback onNotification;

  @override
  Widget build(BuildContext context) {
    final activeLoans = loans.where((loan) => loan.returnedAt == null).toList();
    final totalCopies = books.fold<int>(0, (sum, book) => sum + book.copies);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3157D5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_library,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 12),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SIP Mobile',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Sistem Informasi Perpustakaan',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: onNotification,
                    icon: const Icon(Icons.notifications_none),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // WELCOME
            const Text(
              'Selamat Datang 👋',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            const Text(
              'Kelola perpustakaan dengan lebih mudah.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // SEARCH
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: onSearch,
                onSubmitted: (_) => onSelectTab(1),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search),
                  hintText: 'Cari judul, pengarang, atau kategori...',
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // RINGKASAN
            const Text(
              'Ringkasan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: StatisticCard(
                    icon: Icons.menu_book,
                    title: 'Total Buku',
                    value: '$totalCopies',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: StatisticCard(
                    icon: Icons.people,
                    title: 'Anggota',
                    value: '${members.length}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: StatisticCard(
                    icon: Icons.bookmark,
                    title: 'Dipinjam',
                    value: '${activeLoans.length}',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: StatisticCard(
                    icon: Icons.assignment_return,
                    title: 'Kembali',
                    value:
                        '${loans.where((loan) => loan.returnedAt != null).length}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),

            // MENU UTAMA
            const Text(
              'Menu Utama',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: MenuCard(
                    icon: Icons.menu_book,
                    title: 'Data Buku',
                    onTap: () => onSelectTab(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MenuCard(
                    icon: Icons.people,
                    title: 'Data Anggota',
                    onTap: () => onSelectTab(2),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: MenuCard(
                    icon: Icons.arrow_circle_up,
                    title: 'Peminjaman',
                    onTap: () => onSelectTab(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MenuCard(
                    icon: Icons.arrow_circle_down,
                    title: 'Pengembalian',
                    onTap: () => onSelectTab(3),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // BUKU SEDANG DIPINJAM
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Buku Sedang Dipinjam',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () => onSelectTab(3),
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (activeLoans.isEmpty)
              const Text(
                'Tidak ada buku yang sedang dipinjam.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...activeLoans
                  .take(5)
                  .expand(
                    (loan) => [
                      BorrowedBookCard(
                        title: loan.bookTitle,
                        borrower: loan.memberName,
                        dueDate: _formatDate(loan.dueAt),
                        status: 'Dipinjam',
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// STATISTIC CARD
// =====================================================

class StatisticCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const StatisticCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 25, color: const Color(0xFF3157D5)),

          const SizedBox(height: 12),

          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 3),

          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

// =====================================================
// MENU CARD
// =====================================================

class MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: const Color(0xFF3157D5)),

            const SizedBox(height: 10),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// BORROWED BOOK CARD
// =====================================================

class BorrowedBookCard extends StatelessWidget {
  final String title;
  final String borrower;
  final String dueDate;
  final String status;

  const BorrowedBookCard({
    super.key,
    required this.title,
    required this.borrower,
    required this.dueDate,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFE9EDFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book, color: Color(0xFF3157D5)),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  borrower,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 4),

                Text(
                  'Batas: $dueDate',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// BOOKS PAGE
// =====================================================

class BooksPage extends StatelessWidget {
  const BooksPage({
    super.key,
    required this.books,
    required this.availableCopies,
    required this.searchQuery,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Book> books;
  final int Function(Book) availableCopies;
  final String searchQuery;
  final VoidCallback onAdd;
  final ValueChanged<Book> onEdit;
  final ValueChanged<Book> onDelete;

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.trim().toLowerCase();
    final filteredBooks = books.where((book) {
      return query.isEmpty ||
          book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query) ||
          book.category.toLowerCase().contains(query);
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Data Buku')),
      body: filteredBooks.isEmpty
          ? const Center(child: Text('Buku tidak ditemukan.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: filteredBooks.length,
              itemBuilder: (context, index) {
                final book = filteredBooks[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.menu_book)),
                    title: Text(book.title),
                    subtitle: Text(
                      '${book.author} • ${book.category}\n'
                      'Tersedia ${availableCopies(book)} dari ${book.copies}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') onEdit(book);
                        if (action == 'delete') onDelete(book);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Buku'),
      ),
    );
  }
}

// =====================================================
// MEMBERS PAGE
// =====================================================

class MembersPage extends StatelessWidget {
  const MembersPage({
    super.key,
    required this.members,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Member> members;
  final VoidCallback onAdd;
  final ValueChanged<Member> onEdit;
  final ValueChanged<Member> onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Anggota')),
      body: members.isEmpty
          ? const Center(child: Text('Belum ada anggota.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(member.name),
                    subtitle: Text('${member.phone}\n${member.email}'),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') onEdit(member);
                        if (action == 'delete') onDelete(member);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah Anggota'),
      ),
    );
  }
}

// =====================================================
// LOANS PAGE
// =====================================================

class LoansPage extends StatelessWidget {
  const LoansPage({
    super.key,
    required this.loans,
    required this.onAdd,
    required this.onReturn,
  });

  final List<Loan> loans;
  final VoidCallback onAdd;
  final ValueChanged<Loan> onReturn;

  @override
  Widget build(BuildContext context) {
    final activeLoans = loans.where((loan) => loan.returnedAt == null).toList();
    final returnedLoans = loans
        .where((loan) => loan.returnedAt != null)
        .toList()
        .reversed
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sedang Dipinjam (${activeLoans.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (activeLoans.isEmpty)
            const Card(
              child: ListTile(title: Text('Tidak ada peminjaman aktif.')),
            )
          else
            ...activeLoans.map(
              (loan) => Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.menu_book)),
                  title: Text(loan.bookTitle),
                  subtitle: Text(
                    '${loan.memberName}\n'
                    'Batas pengembalian: ${_formatDate(loan.dueAt)}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Proses pengembalian',
                    icon: const Icon(
                      Icons.assignment_turned_in_outlined,
                      color: Color(0xFF3157D5),
                    ),
                    onPressed: () => onReturn(loan),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Riwayat Pengembalian (${returnedLoans.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (returnedLoans.isEmpty)
            const Card(
              child: ListTile(title: Text('Belum ada buku yang dikembalikan.')),
            )
          else
            ...returnedLoans.map(
              (loan) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.assignment_return),
                  ),
                  title: Text(loan.bookTitle),
                  subtitle: Text(
                    '${loan.memberName}\n'
                    'Dikembalikan: ${_formatDate(loan.returnedAt!)}',
                  ),
                  isThreeLine: true,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('Pinjam Buku'),
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

Future<Book?> _showBookForm(BuildContext context, {Book? existing}) async {
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController(text: existing?.title ?? '');
  final author = TextEditingController(text: existing?.author ?? '');
  final category = TextEditingController(text: existing?.category ?? '');
  final copies = TextEditingController(
    text: existing?.copies.toString() ?? '1',
  );
  try {
    return await showDialog<Book>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Tambah Buku' : 'Edit Buku'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _formField(title, 'Judul buku'),
                _formField(author, 'Pengarang'),
                _formField(category, 'Kategori'),
                _formField(
                  copies,
                  'Jumlah eksemplar',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final count = int.tryParse(value ?? '');
                    if (count == null || count < 1) {
                      return 'Masukkan jumlah minimal 1';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                dialogContext,
                Book(
                  id: existing?.id ?? 0,
                  title: title.text.trim(),
                  author: author.text.trim(),
                  category: category.text.trim(),
                  copies: int.parse(copies.text.trim()),
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  } finally {
    title.dispose();
    author.dispose();
    category.dispose();
    copies.dispose();
  }
}

Future<Member?> _showMemberForm(
  BuildContext context, {
  Member? existing,
}) async {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(text: existing?.name ?? '');
  final phone = TextEditingController(text: existing?.phone ?? '');
  final email = TextEditingController(text: existing?.email ?? '');
  try {
    return await showDialog<Member>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Tambah Anggota' : 'Edit Anggota'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _formField(name, 'Nama anggota'),
                _formField(phone, 'Nomor telepon'),
                _formField(
                  email,
                  'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (!(value ?? '').contains('@')) {
                      return 'Masukkan email yang valid';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                dialogContext,
                Member(
                  id: existing?.id ?? 0,
                  name: name.text.trim(),
                  phone: phone.text.trim(),
                  email: email.text.trim(),
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  } finally {
    name.dispose();
    phone.dispose();
    email.dispose();
  }
}

Future<Loan?> _showLoanForm(
  BuildContext context,
  List<Book> books,
  List<Member> members,
) async {
  final formKey = GlobalKey<FormState>();
  int? selectedBookId = books.first.id;
  int? selectedMemberId = members.first.id;
  final dueAt = DateTime.now().add(const Duration(days: 7));
  return showDialog<Loan>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Peminjaman Buku'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedBookId,
                decoration: const InputDecoration(labelText: 'Buku'),
                items: books
                    .map(
                      (book) => DropdownMenuItem(
                        value: book.id,
                        child: Text(
                          book.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => selectedBookId = value),
              ),
              DropdownButtonFormField<int>(
                initialValue: selectedMemberId,
                decoration: const InputDecoration(labelText: 'Anggota'),
                items: members
                    .map(
                      (member) => DropdownMenuItem(
                        value: member.id,
                        child: Text(
                          member.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => selectedMemberId = value),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Batas pengembalian: ${_formatDate(dueAt)}'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate() ||
                  selectedBookId == null ||
                  selectedMemberId == null) {
                return;
              }
              final book = books.firstWhere(
                (item) => item.id == selectedBookId,
              );
              final member = members.firstWhere(
                (item) => item.id == selectedMemberId,
              );
              Navigator.pop(
                dialogContext,
                Loan(
                  id: 0,
                  bookId: book.id,
                  memberId: member.id,
                  bookTitle: book.title,
                  memberName: member.name,
                  borrowedAt: DateTime.now(),
                  dueAt: dueAt,
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    ),
  );
}

Widget _formField(
  TextEditingController controller,
  String label, {
  TextInputType? keyboardType,
  String? Function(String?)? validator,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator:
          validator ??
          (value) =>
              value == null || value.trim().isEmpty ? 'Wajib diisi' : null,
    ),
  );
}
