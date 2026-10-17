import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/user_profile.dart';
import 'package:flutter_application_1/pages/profile_page.dart';
import 'package:flutter_application_1/services/user_profile_local_store.dart';

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
  final _profileStore = UserProfileLocalStore();
  bool _obscurePassword = true;
  bool _isSigningIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_isSigningIn || !_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    setState(() => _isSigningIn = true);
    try {
      final userProfile = await _profileStore.loadForLogin(email);
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DashboardPage(userProfile: userProfile),
        ),
      );
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Data profil lokal gagal dimuat: $error')),
        );
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isKeyboardVisible) ...[
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3157D5),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white,
                            size: 29,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SIP Mobile',
                              style: TextStyle(
                                color: Color(0xFF17233D),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Sistem Informasi Perpustakaan',
                              style: TextStyle(
                                color: Color(0xFF77839A),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 38),
                  ] else
                    const SizedBox(height: 8),
                  Text(
                    'Selamat Datang Kembali',
                    style: TextStyle(
                      color: const Color(0xFF17233D),
                      fontSize: isKeyboardVisible ? 24 : 27,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masuk untuk mengelola perpustakaan Anda',
                    style: TextStyle(
                      color: Color(0xFF77839A),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: isKeyboardVisible ? 14 : 25),
                  Container(
                    padding: EdgeInsets.all(isKeyboardVisible ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE8EDF5)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A17233D),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: _loginInputDecoration(
                              label: 'Email',
                              hint: 'nama@email.com',
                              icon: Icons.email_outlined,
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty || !email.contains('@')) {
                                return 'Masukkan alamat email yang valid';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isKeyboardVisible ? 12 : 18),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _signIn(),
                            decoration: _loginInputDecoration(
                              label: 'Kata Sandi',
                              icon: Icons.lock_outline_rounded,
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
                          SizedBox(height: isKeyboardVisible ? 16 : 24),
                          FilledButton(
                            onPressed: _isSigningIn ? null : _signIn,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF3157D5),
                              foregroundColor: Colors.white,
                              minimumSize: Size.fromHeight(
                                isKeyboardVisible ? 50 : 54,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: _isSigningIn
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Masuk'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isKeyboardVisible) ...[
                    const SizedBox(height: 20),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_library_outlined,
                          color: Color(0xFF8A96AA),
                          size: 16,
                        ),
                        SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            'Kelola perpustakaan dengan lebih mudah',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF8A96AA),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _loginInputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
  }) {
    const borderColor = Color(0xFFE1E7F0);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 21),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFFAFBFE),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF3157D5), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.userProfile});

  final UserProfile userProfile;

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
  late UserProfile _userProfile;
  final _profileStore = UserProfileLocalStore();
  int _nextBookId = 32;
  int _nextMemberId = 3;
  int _nextLoanId = 3;

  late final List<Book> _books = [
    const Book(
      id: 1,
      title: 'Dasar-Dasar Teknik Jaringan Komputer dan Telekomunikasi untuk SMK/MAK Kelas X',
      author: 'Ibnu Indarwati, Arif Muttakin, Agung Puspita Bantala',
      category: 'TKJ • Teknik Komputer dan Jaringan',
      copies: 5,
    ),
    const Book(
      id: 2,
      title: 'Buku Panduan Guru Dasar-Dasar Teknik Jaringan Komputer dan Telekomunikasi untuk SMK/MAK Kelas X',
      author: 'Ibnu Indarwati, Arif Muttakin, Agung Puspita Bantala',
      category: 'TKJ • Panduan Guru',
      copies: 3,
    ),
    const Book(
      id: 3,
      title: 'Informatika untuk SMK/MAK Kelas X Semester 1',
      author: 'Kusmadi, Imam Badrudin, Bima Laksana Putra, Wiyana Eva Cuntaka',
      category: 'TKJ • Informatika',
      copies: 4,
    ),
    const Book(
      id: 4,
      title: 'Informatika untuk SMK/MAK Kelas X Semester 2',
      author: 'Kusmadi, Imam Badrudin, Lisna Nurrohmawati, Bima Laksana Putra',
      category: 'TKJ • Informatika',
      copies: 4,
    ),
    const Book(
      id: 5,
      title: 'Buku Panduan Guru Informatika untuk SMK/MAK Kelas X',
      author: 'Kusmadi, Imam Badrudin, Lisna Nurrohmawati, Bima Laksana Putra',
      category: 'TKJ • Panduan Guru Informatika',
      copies: 2,
    ),
    const Book(
      id: 6,
      title: 'Dasar-Dasar Pengembangan Perangkat Lunak dan Gim untuk SMK/MAK Kelas X',
      author: 'Marwondo, Rini Melati',
      category: 'RPL • Pengembangan Perangkat Lunak',
      copies: 5,
    ),
    const Book(
      id: 7,
      title: 'Buku Panduan Guru Dasar-Dasar Pengembangan Perangkat Lunak dan Gim untuk SMK/MAK Kelas X',
      author: 'Marwondo, Rini Melati',
      category: 'RPL • Panduan Guru',
      copies: 2,
    ),
    const Book(
      id: 8,
      title: 'Informatika untuk SMA/MA/SMK/MAK Kelas X (Edisi Revisi)',
      author: 'Mushthofa, Auzi Asfarian, Hanson Prihantoro Putro, Irya Wisnubhadra, Endang Purnama Giri, Dean Apriana Ramadhan, Wahyono',
      category: 'RPL • Informatika Dasar',
      copies: 4,
    ),
    const Book(
      id: 9,
      title: 'Panduan Guru Informatika untuk SMA/MA/SMK/MAK Kelas X (Edisi Revisi)',
      author: 'Auzi Asfarian, Mushthofa, Hanson Prihantoro Putro, Irya Wisnubhadra, Dean Apriana Ramadhan, Endang Purnama Giri, Wahyono',
      category: 'RPL • Panduan Guru Informatika',
      copies: 2,
    ),
    const Book(
      id: 10,
      title: 'Informatika untuk SMA/MA Kelas XI (Edisi Revisi)',
      author: 'Dela Chaerani, Solehkun Kodir, Idi Sumardi, Budi Permana',
      category: 'RPL • Informatika Lanjutan',
      copies: 3,
    ),
    const Book(
      id: 11,
      title: 'Panduan Guru Informatika untuk SMA/MA Kelas XI (Edisi Revisi)',
      author: 'Solehkun Kodir, Dela Chaerani, Idi Sumardi, Budi Permana',
      category: 'RPL • Panduan Guru Informatika',
      copies: 2,
    ),
    const Book(
      id: 12,
      title: 'Dasar - dasar Desain Komunikasi Visual untuk SMK/MAK Kelas X Semester 1',
      author: 'Maylinda Ambarwati',
      category: 'Multimedia • Desain Komunikasi Visual',
      copies: 4,
    ),
    const Book(
      id: 13,
      title: 'Dasar-Dasar Desain Komunikasi Visual untuk SMK/MAK Kelas X Semester 2',
      author: 'Maylinda Ambarwati, Dwi Kurnia Kuswahyuni',
      category: 'Multimedia • Desain Komunikasi Visual',
      copies: 4,
    ),
    const Book(
      id: 14,
      title: 'Buku Panduan Guru Dasar-Dasar Desain Komunikasi Visual untuk SMK/MAK Kelas X',
      author: 'Maylinda Ambarwati, Dwi Kurnia Kuswahyuni',
      category: 'Multimedia • Panduan Guru DKV',
      copies: 2,
    ),
    const Book(
      id: 15,
      title: 'Dasar-Dasar Animasi untuk SMK/MAK Kelas X',
      author: 'Nina Tri Daniati, Rida Mulyadi, Agus Nugroho',
      category: 'Multimedia • Animasi',
      copies: 4,
    ),
    const Book(
      id: 16,
      title: 'Buku Panduan Guru Dasar-Dasar Animasi untuk SMK/MAK Kelas X',
      author: 'Nina Tri Daniati, Rida Mulyadi, Agus Nugroho',
      category: 'Multimedia • Panduan Guru Animasi',
      copies: 2,
    ),
    const Book(
      id: 17,
      title: 'Animasi Kelas XI-XII',
      author: 'Nina Tri Daniati, Ignatius Dony Iswantoro',
      category: 'Multimedia • Animasi',
      copies: 3,
    ),
    const Book(
      id: 18,
      title: 'Model Buku Teks SMK Berbasis Soft Skills: Produksi dan Siaran Program Televisi untuk SMK/MAK Kelas XI',
      author: 'E. Oos M. Anwas, Supriyatno, Zaim Uchrowi, Anggraeni Dian Permatasari, Khoifa Najma Iftitah, Hari Setiawan, Ibnu Salman',
      category: 'Multimedia • Produksi Media Digital',
      copies: 3,
    ),
    const Book(
      id: 19,
      title: 'Model Buku Panduan Guru SMK Berbasis Soft Skills: Produksi dan Siaran Program Televisi untuk SMK/MAK Kelas XI',
      author: 'E. Oos M. Anwas, Supriyatno, Zaim Uchrowi, Anggraeni Dian Permatasari, Khoifa Najma Iftitah, Ibnu Salman',
      category: 'Multimedia • Panduan Guru Produksi Media',
      copies: 2,
    ),
    const Book(
      id: 20,
      title: 'Buku Panduan Guru Prakarya dan Kewirausahaan: Rekayasa untuk SMA/MA Kelas XI',
      author: 'Indra Samsudin, Hera Novia, Ahmad Aminudin',
      category: 'Pendukung • Kewirausahaan Rekayasa',
      copies: 2,
    ),
    const Book(
      id: 21,
      title: 'Informatika untuk SMA/MA Kelas XII',
      author: 'Budi Permana, R. Kurweni Ukar, Dela Chaerani, Solehkun Kodir',
      category: 'Pendukung • Informatika',
      copies: 3,
    ),
    const Book(
      id: 22,
      title: 'Buku Panduan Guru Informatika untuk SMA/MA Kelas XII',
      author: 'Budi Permana, Kurweni Ukar, Dela Chaerani, Solehkun Kodir',
      category: 'Pendukung • Panduan Guru Informatika',
      copies: 2,
    ),
    const Book(
      id: 23,
      title: 'Prakarya dan Kewirausahaan Semester 1 Kelas X',
      author: 'Hendriana Werdhaningsih, Alberta Haryudanti, Rinrin Jamrianti, Desta Wirmas',
      category: 'Pendukung • Kewirausahaan',
      copies: 3,
    ),
    const Book(
      id: 24,
      title: 'Prakarya dan Kewirausahaan Semester 2 Kelas X',
      author: 'Hendriana Werdhaningsih, Alberta Haryudanti, Rinrin Jamrianti, Desta Wirmas',
      category: 'Pendukung • Kewirausahaan',
      copies: 3,
    ),
    const Book(
      id: 25,
      title: 'Prakarya dan Kewirausahaan Kelas XII',
      author: 'Hendriana Werdhaningsih, Wawat Naswati, Desta Wirnas, Rinrin Jamriati',
      category: 'Pendukung • Kewirausahaan',
      copies: 3,
    ),
    const Book(
      id: 26,
      title: 'Buku Guru Prakarya dan Kewirausahaan Kelas X',
      author: 'Hendriana Werdhaningsih, Alberta Haryudanti, Rinrin Jamrianti, Desta Wirmas',
      category: 'Pendukung • Panduan Guru Kewirausahaan',
      copies: 2,
    ),
    const Book(
      id: 27,
      title: 'Buku Guru Prakarya dan Kewirausahaan Kelas XI',
      author: 'Indah Setyowati, Nurhayati, Miftakodin, Cahyadi, Heatiningsih',
      category: 'Pendukung • Panduan Guru Kewirausahaan',
      copies: 2,
    ),
    const Book(
      id: 28,
      title: 'Buku Guru Prakarya dan Kewirausahaan Kelas XII',
      author: 'Hendriana Werdhaningsih, Wawat Naswati, Desta Wirnas, Rinrin Jamriati',
      category: 'Pendukung • Panduan Guru Kewirausahaan',
      copies: 2,
    ),
    const Book(
      id: 29,
      title: 'Dasar-Dasar Desain dan Produksi Kriya untuk SMK/MAK Kelas X',
      author: 'Hendar Suhendar, Heri Hermawan, Setyowati',
      category: 'Multimedia • Produksi Kreatif',
      copies: 3,
    ),
    const Book(
      id: 30,
      title: 'Buku Panduan Guru Dasar-Dasar Desain dan Produksi Kriya untuk SMK/MAK Kelas X',
      author: 'Hendar Suhendar, Heri Hermawan, Setyowati',
      category: 'Multimedia • Panduan Guru Produksi Kreatif',
      copies: 2,
    ),
    const Book(
      id: 31,
      title: 'Buku Panduan Guru Prakarya dan Kewirausahaan: Rekayasa untuk SMA/MA Kelas XII',
      author: 'Hera Novia, Indra Samsudin, Ahmad Aminudin',
      category: 'Pendukung • Kewirausahaan Rekayasa',
      copies: 2,
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
      bookTitle: 'Dasar-Dasar Teknik Jaringan Komputer dan Telekomunikasi untuk SMK/MAK Kelas X',
      memberName: 'Andi Saputra',
      borrowedAt: DateTime.now().subtract(const Duration(days: 2)),
      dueAt: DateTime.now().add(const Duration(days: 5)),
    ),
    Loan(
      id: 2,
      bookId: 2,
      memberId: 2,
      bookTitle: 'Buku Panduan Guru Dasar-Dasar Teknik Jaringan Komputer dan Telekomunikasi untuk SMK/MAK Kelas X',
      memberName: 'Siti Rahma',
      borrowedAt: DateTime.now().subtract(const Duration(days: 1)),
      dueAt: DateTime.now().add(const Duration(days: 6)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _userProfile = widget.userProfile;
  }

  Future<bool> _saveProfile(UserProfile profile) async {
    final saved = await _profileStore.save(profile);
    if (!saved || !mounted) return saved;
    setState(() => _userProfile = profile);
    return true;
  }

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
      case 4:
        return ProfilePage(
          userProfile: _userProfile,
          onProfileUpdated: _saveProfile,
          onLogout: () {
            Navigator.of(context).pushAndRemoveUntil<void>(
              MaterialPageRoute<void>(builder: (_) => const LoginPage()),
              (route) => false,
            );
          },
        );
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
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
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
    final today = DateTime.now();
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

            // BUKU SEDANG DIPINJAM
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Text(
                    'Buku Sedang Dipinjam',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
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
                'Tidak ada buku yang sedang dipinjam saat ini.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.25,
                  color: Color(0xFF667085),
                ),
              )
            else
              ...activeLoans
                  .take(3)
                  .expand(
                    (loan) => [
                      BorrowedBookCard(
                        title: loan.bookTitle,
                        borrower: loan.memberName,
                        dueDate: _formatDashboardDate(loan.dueAt),
                        status: _isOverdueOn(loan.dueAt, today)
                            ? 'Terlambat'
                            : 'Dipinjam',
                      ),
                      const SizedBox(height: 9),
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
    final statusColor = status == 'Terlambat'
        ? const Color(0xFFB54708)
        : Theme.of(context).colorScheme.primary;
    final statusBackground = status == 'Terlambat'
        ? const Color(0xFFFFF1E8)
        : Theme.of(context).colorScheme.primaryContainer;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: const Color(0x1417233D),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE8EDF5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.menu_book_rounded,
                size: 21,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      borrower,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.25,
                        color: Color(0xFF647087),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Batas pengembalian: $dueDate',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        color: Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isOverdueOn(DateTime dueDate, DateTime currentDate) {
  final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final today = DateTime(currentDate.year, currentDate.month, currentDate.day);
  return dueDay.isBefore(today);
}

String _formatDashboardDate(DateTime date) {
  const monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
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
      appBar: AppBar(
        title: const Text(
          'Data Buku',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
        ),
      ),
      body: filteredBooks.isEmpty
          ? const Center(child: Text('Buku tidak ditemukan.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              itemCount: filteredBooks.length,
              itemBuilder: (context, index) {
                final book = filteredBooks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 9),
                  elevation: 1,
                  shadowColor: const Color(0x1417233D),
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFE8EDF5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(11, 10, 5, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          child: Icon(
                            Icons.menu_book_rounded,
                            size: 21,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  book.author,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.25,
                                    color: Color(0xFF647087),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  book.category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.25,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Tersedia ${availableCopies(book)} dari ${book.copies}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.25,
                                    color: Color(0xFF667085),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          tooltip: 'Tindakan buku',
                          onSelected: (action) {
                            if (action == 'edit') onEdit(book);
                            if (action == 'delete') onDelete(book);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Hapus'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Tambah Buku',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
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
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 9),
                  elevation: 1,
                  shadowColor: const Color(0x1417233D),
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFE8EDF5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(11, 10, 5, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          child: Icon(
                            Icons.person_rounded,
                            size: 21,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ID Anggota: ${member.id}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.25,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  member.phone,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.25,
                                    color: Color(0xFF647087),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  member.email,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.25,
                                    color: Color(0xFF647087),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          tooltip: 'Tindakan anggota',
                          onSelected: (action) {
                            if (action == 'edit') onEdit(member);
                            if (action == 'delete') onDelete(member);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Hapus'),
                            ),
                          ],
                        ),
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
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
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
              (loan) => _loanCard(context, loan, isReturned: false),
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
              (loan) => _loanCard(context, loan, isReturned: true),
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

  Widget _loanCard(
    BuildContext context,
    Loan loan, {
    required bool isReturned,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      elevation: 1,
      shadowColor: const Color(0x1417233D),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE8EDF5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 10, 5, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                isReturned ? Icons.assignment_return : Icons.menu_book_rounded,
                size: 21,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.bookTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loan.memberName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.25,
                        color: Color(0xFF647087),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Dipinjam: ${_formatDate(loan.borrowedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        color: Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isReturned
                          ? 'Dikembalikan: ${_formatDate(loan.returnedAt!)}'
                          : 'Batas pengembalian: ${_formatDate(loan.dueAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        color: Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isReturned ? 'Status: Dikembalikan' : 'Status: Dipinjam',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!isReturned)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                tooltip: 'Proses pengembalian',
                icon: const Icon(
                  Icons.assignment_turned_in_outlined,
                  color: Color(0xFF3157D5),
                ),
                onPressed: () => onReturn(loan),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

Future<Book?> _showBookForm(BuildContext context, {Book? existing}) async {
  return showDialog<Book>(
    context: context,
    builder: (_) => _BookFormDialog(existing: existing),
  );
}

Future<Member?> _showMemberForm(
  BuildContext context, {
  Member? existing,
}) async {
  return showDialog<Member>(
    context: context,
    builder: (_) => _MemberFormDialog(existing: existing),
  );
}

class _BookFormDialog extends StatefulWidget {
  const _BookFormDialog({this.existing});

  final Book? existing;

  @override
  State<_BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends State<_BookFormDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController authorController;
  late final TextEditingController categoryController;
  late final TextEditingController copiesController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.existing?.title ?? '');
    authorController = TextEditingController(
      text: widget.existing?.author ?? '',
    );
    categoryController = TextEditingController(
      text: widget.existing?.category ?? '',
    );
    copiesController = TextEditingController(
      text: widget.existing?.copies.toString() ?? '1',
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    categoryController.dispose();
    copiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Tambah Buku' : 'Edit Buku'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _formField(titleController, 'Judul buku'),
              _formField(authorController, 'Pengarang'),
              _formField(categoryController, 'Kategori'),
              _formField(
                copiesController,
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              Book(
                id: widget.existing?.id ?? 0,
                title: titleController.text.trim(),
                author: authorController.text.trim(),
                category: categoryController.text.trim(),
                copies: int.parse(copiesController.text.trim()),
              ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _MemberFormDialog extends StatefulWidget {
  const _MemberFormDialog({this.existing});

  final Member? existing;

  @override
  State<_MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends State<_MemberFormDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.existing?.name ?? '');
    phoneController = TextEditingController(text: widget.existing?.phone ?? '');
    emailController = TextEditingController(text: widget.existing?.email ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Tambah Anggota' : 'Edit Anggota'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _formField(nameController, 'Nama anggota'),
              _formField(phoneController, 'Nomor telepon'),
              _formField(
                emailController,
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              Member(
                id: widget.existing?.id ?? 0,
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                email: emailController.text.trim(),
              ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
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
                isExpanded: true,
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
