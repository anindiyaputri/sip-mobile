import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pbkdf2Iterations = 120000;

enum UserRole {
  admin,
  guru,
  siswa;

  String get label => switch (this) {
    UserRole.admin => 'Admin',
    UserRole.guru => 'Guru',
    UserRole.siswa => 'Siswa',
  };
}

class UserAccount {
  const UserAccount({
    required this.id,
    required this.login,
    required this.role,
    this.memberId,
  });

  final String id;
  final String login;
  final UserRole role;
  final int? memberId;
}

class AuthenticatedSession {
  const AuthenticatedSession._(this.account);

  final UserAccount account;

  String get userId => account.id;
  String get login => account.login;
  UserRole get role => account.role;
  int? get memberId => account.memberId;
}

class UserAccountStore {
  const UserAccountStore({this.useIsolates = true});

  final bool useIsolates;
  static const _storageKey = 'sip_mobile_accounts_v1';

  Future<bool> hasAccounts() async => (await _readAccounts()).isNotEmpty;

  Future<AuthenticatedSession> authenticate(
    String login,
    String password,
  ) async {
    final normalizedLogin = _normalizeLogin(login);
    final accounts = await _readAccounts();
    _StoredAccount? account;
    for (final candidate in accounts) {
      if (_normalizeLogin(candidate.login) == normalizedLogin) {
        account = candidate;
        break;
      }
    }

    if (account == null ||
        !_matchesPassword(
          account,
          await _deriveAccountPassword(
            password,
            account.salt,
            useIsolate: useIsolates,
          ),
        )) {
      throw const FormatException(
        'Email/username atau kata sandi tidak valid.',
      );
    }

    return AuthenticatedSession._(account.publicAccount);
  }

  Future<UserAccount> createInitialAdmin({
    required String login,
    required String password,
  }) async {
    final accounts = await _readAccounts();
    if (accounts.isNotEmpty) {
      throw StateError('Akun Admin awal sudah dibuat.');
    }
    _validateCredentials(login, password);
    final account = await _newAccount(
      login: login,
      password: password,
      role: UserRole.admin,
      useIsolate: useIsolates,
    );
    await _writeAccounts([account]);
    return account.publicAccount;
  }

  Future<List<UserAccount>> listAccounts(AuthenticatedSession session) async {
    final accounts = await _readAccounts();
    _requireAdmin(session, accounts);
    return accounts.map((account) => account.publicAccount).toList();
  }

  Future<UserAccount> createAccount({
    required AuthenticatedSession session,
    required String login,
    required String password,
    required UserRole role,
    int? memberId,
  }) async {
    final accounts = await _readAccounts();
    _requireAdmin(session, accounts);
    _validateCredentials(login, password);
    if (accounts.any(
      (account) => _normalizeLogin(account.login) == _normalizeLogin(login),
    )) {
      throw const FormatException('Email/username sudah digunakan.');
    }
    if (memberId != null &&
        accounts.any((account) => account.memberId == memberId)) {
      throw const FormatException(
        'Anggota tersebut sudah ditautkan ke akun lain.',
      );
    }

    final account = await _newAccount(
      login: login,
      password: password,
      role: role,
      memberId: memberId,
      useIsolate: useIsolates,
    );
    await _writeAccounts([...accounts, account]);
    return account.publicAccount;
  }

  Future<void> updateAccount({
    required AuthenticatedSession session,
    required String userId,
    required UserRole role,
    required int? memberId,
    String? newPassword,
  }) async {
    final accounts = await _readAccounts();
    _requireAdmin(session, accounts);
    final index = accounts.indexWhere((account) => account.id == userId);
    if (index < 0) throw StateError('Akun tidak ditemukan.');
    if (session.userId == userId && role != UserRole.admin) {
      throw StateError(
        'Peran akun Admin yang sedang digunakan tidak dapat diubah.',
      );
    }
    if (memberId != null &&
        accounts.any(
          (account) => account.memberId == memberId && account.id != userId,
        )) {
      throw const FormatException(
        'Anggota tersebut sudah ditautkan ke akun lain.',
      );
    }
    if (accounts[index].role == UserRole.admin &&
        role != UserRole.admin &&
        accounts.where((account) => account.role == UserRole.admin).length ==
            1) {
      throw StateError('Minimal satu akun Admin harus tetap tersedia.');
    }

    var updated = accounts[index].withRoleAndMember(role, memberId);
    if (newPassword != null && newPassword.isNotEmpty) {
      _validatePassword(newPassword);
      updated = await updated.withPassword(
        newPassword,
        useIsolate: useIsolates,
      );
    }
    accounts[index] = updated;
    await _writeAccounts(accounts);
  }

  Future<void> deleteAccount({
    required AuthenticatedSession session,
    required String userId,
  }) async {
    final accounts = await _readAccounts();
    _requireAdmin(session, accounts);
    if (session.userId == userId) {
      throw StateError('Akun yang sedang digunakan tidak dapat dihapus.');
    }
    final index = accounts.indexWhere((account) => account.id == userId);
    if (index < 0) throw StateError('Akun tidak ditemukan.');
    if (accounts[index].role == UserRole.admin &&
        accounts.where((account) => account.role == UserRole.admin).length ==
            1) {
      throw StateError('Minimal satu akun Admin harus tetap tersedia.');
    }
    accounts.removeAt(index);
    await _writeAccounts(accounts);
  }

  Future<String?> userIdForMember(int memberId) async {
    for (final account in await _readAccounts()) {
      if (account.memberId == memberId) return account.id;
    }
    return null;
  }

  Future<_StoredAccount> _newAccount({
    required String login,
    required String password,
    required UserRole role,
    required bool useIsolate,
    int? memberId,
  }) async {
    final random = Random.secure();
    final salt = base64UrlEncode(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    final normalizedLogin = login.trim();
    return _StoredAccount(
      id: 'usr_${List<int>.generate(16, (_) => random.nextInt(256)).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join()}',
      login: normalizedLogin,
      role: role,
      memberId: memberId,
      salt: salt,
      passwordHash: await _deriveAccountPassword(
        password,
        salt,
        useIsolate: useIsolate,
      ),
    );
  }

  Future<List<_StoredAccount>> _readAccounts() async {
    final preferences = await SharedPreferences.getInstance();
    final json = preferences.getString(_storageKey);
    if (json == null) return [];

    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic> ||
        decoded['version'] != 1 ||
        decoded['accounts'] is! List) {
      throw const FormatException('Data akun lokal memiliki format salah.');
    }
    final accounts = (decoded['accounts'] as List).map((value) {
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Data akun lokal memiliki format salah.');
      }
      return _StoredAccount.fromJson(value);
    }).toList();
    final ids = accounts.map((account) => account.id).toSet();
    final logins = accounts
        .map((account) => _normalizeLogin(account.login))
        .toSet();
    if (ids.length != accounts.length || logins.length != accounts.length) {
      throw const FormatException(
        'Data akun lokal memiliki identitas duplikat.',
      );
    }
    return accounts;
  }

  Future<void> _writeAccounts(List<_StoredAccount> accounts) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _storageKey,
      jsonEncode({
        'version': 1,
        'accounts': accounts.map((account) => account.toJson()).toList(),
      }),
    );
    if (!saved) throw StateError('Data akun gagal disimpan di perangkat ini.');
  }

  void _requireAdmin(
    AuthenticatedSession session,
    List<_StoredAccount> accounts,
  ) {
    final currentAccount = accounts.where(
      (account) => account.id == session.userId,
    );
    if (session.role != UserRole.admin ||
        currentAccount.length != 1 ||
        currentAccount.single.role != UserRole.admin) {
      throw StateError('Akses hanya tersedia untuk Admin.');
    }
  }

  void _validateCredentials(String login, String password) {
    if (login.trim().isEmpty) {
      throw const FormatException('Email/username wajib diisi.');
    }
    _validatePassword(password);
  }

  void _validatePassword(String password) {
    if (password.length < 8) {
      throw const FormatException(
        'Kata sandi harus terdiri dari minimal 8 karakter.',
      );
    }
  }

  String _normalizeLogin(String login) => login.trim().toLowerCase();

  bool _matchesPassword(_StoredAccount account, String candidate) {
    final expectedBytes = base64Url.decode(account.passwordHash);
    final candidateBytes = base64Url.decode(candidate);
    if (expectedBytes.length != candidateBytes.length) return false;
    var difference = 0;
    for (var index = 0; index < expectedBytes.length; index++) {
      difference |= expectedBytes[index] ^ candidateBytes[index];
    }
    return difference == 0;
  }
}

class _StoredAccount {
  const _StoredAccount({
    required this.id,
    required this.login,
    required this.role,
    required this.salt,
    required this.passwordHash,
    this.memberId,
  });

  final String id;
  final String login;
  final UserRole role;
  final int? memberId;
  final String salt;
  final String passwordHash;

  UserAccount get publicAccount =>
      UserAccount(id: id, login: login, role: role, memberId: memberId);

  _StoredAccount withRoleAndMember(UserRole role, int? memberId) =>
      _StoredAccount(
        id: id,
        login: login,
        role: role,
        memberId: memberId,
        salt: salt,
        passwordHash: passwordHash,
      );

  Future<_StoredAccount> withPassword(
    String password, {
    required bool useIsolate,
  }) async {
    final random = Random.secure();
    final salt = base64UrlEncode(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    final hash = await _deriveAccountPassword(
      password,
      salt,
      useIsolate: useIsolate,
    );
    return _StoredAccount(
      id: id,
      login: login,
      role: role,
      memberId: memberId,
      salt: salt,
      passwordHash: hash,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'login': login,
    'role': role.name,
    'memberId': memberId,
    'salt': salt,
    'passwordHash': passwordHash,
  };

  factory _StoredAccount.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final login = json['login'];
    final roleName = json['role'];
    final memberId = json['memberId'];
    final salt = json['salt'];
    final passwordHash = json['passwordHash'];
    final role = UserRole.values.where((value) => value.name == roleName);
    if (id is! String ||
        id.isEmpty ||
        login is! String ||
        login.trim().isEmpty ||
        role.length != 1 ||
        (memberId != null && memberId is! int) ||
        salt is! String ||
        passwordHash is! String) {
      throw const FormatException('Data akun lokal memiliki format salah.');
    }
    return _StoredAccount(
      id: id,
      login: login,
      role: role.single,
      memberId: memberId as int?,
      salt: salt,
      passwordHash: passwordHash,
    );
  }
}

Future<String> _deriveAccountPassword(
  String password,
  String salt, {
  required bool useIsolate,
}) {
  if (!useIsolate) {
    return Future.value(
      _deriveAccountPasswordInIsolate(password, salt, _pbkdf2Iterations),
    );
  }
  return Isolate.run(
    () => _deriveAccountPasswordInIsolate(password, salt, _pbkdf2Iterations),
  );
}

String _deriveAccountPasswordInIsolate(
  String password,
  String salt,
  int iterations,
) {
  final hmac = Hmac(sha256, utf8.encode(password));
  final saltBytes = base64Url.decode(salt);
  var block = hmac.convert([...saltBytes, 0, 0, 0, 1]).bytes;
  final derived = List<int>.from(block);
  for (var iteration = 1; iteration < iterations; iteration++) {
    block = hmac.convert(block).bytes;
    for (var byte = 0; byte < derived.length; byte++) {
      derived[byte] ^= block[byte];
    }
  }
  return base64UrlEncode(derived);
}
