import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/user_account_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late UserAccountStore store;
  late AuthenticatedSession admin;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = const UserAccountStore(useIsolates: false);
    final account = await store.createInitialAdmin(
      login: 'admin@school.test',
      password: 'admin-pass-123',
    );
    admin = await store.authenticate(account.login, 'admin-pass-123');
  });

  test('account credentials persist roles and stable generated IDs', () async {
    final teacher = await store.createAccount(
      session: admin,
      login: 'teacher.one',
      password: 'teacher-pass-123',
      role: UserRole.guru,
      memberId: 7,
    );
    final student = await store.createAccount(
      session: admin,
      login: 'admin-looking-student',
      password: 'student-pass-123',
      role: UserRole.siswa,
      memberId: 8,
    );

    final authenticatedTeacher = await store.authenticate(
      ' TEACHER.ONE ',
      'teacher-pass-123',
    );
    final authenticatedStudent = await store.authenticate(
      student.login,
      'student-pass-123',
    );

    expect(teacher.id, isNot(student.id));
    expect(authenticatedTeacher.userId, teacher.id);
    expect(authenticatedTeacher.role, UserRole.guru);
    expect(authenticatedTeacher.memberId, 7);
    expect(authenticatedStudent.role, UserRole.siswa);
    expect(await store.hasAccounts(), isTrue);

    final preferences = await SharedPreferences.getInstance();
    final savedAccounts = preferences.getString('sip_mobile_accounts_v1');
    expect(savedAccounts, isNot(contains('teacher-pass-123')));
    expect(savedAccounts, contains(teacher.id));
  });

  test(
    'invalid credentials fail and first Admin cannot be provisioned twice',
    () async {
      await expectLater(
        store.authenticate('unknown.user', 'admin-pass-123'),
        throwsFormatException,
      );
      await expectLater(
        store.authenticate('admin@school.test', 'wrong-password'),
        throwsFormatException,
      );
      await expectLater(
        store.createInitialAdmin(
          login: 'another-admin',
          password: 'another-pass-123',
        ),
        throwsStateError,
      );
    },
  );

  test(
    'only current Admin may manage accounts and last Admin is protected',
    () async {
      final teacher = await store.createAccount(
        session: admin,
        login: 'teacher.two',
        password: 'teacher-pass-123',
        role: UserRole.guru,
      );
      final teacherSession = await store.authenticate(
        teacher.login,
        'teacher-pass-123',
      );

      await expectLater(store.listAccounts(teacherSession), throwsStateError);
      await expectLater(
        store.createAccount(
          session: teacherSession,
          login: 'blocked.user',
          password: 'blocked-pass-123',
          role: UserRole.siswa,
        ),
        throwsStateError,
      );
      await expectLater(
        store.deleteAccount(session: admin, userId: admin.userId),
        throwsStateError,
      );
      await expectLater(
        store.updateAccount(
          session: admin,
          userId: admin.userId,
          role: UserRole.siswa,
          memberId: null,
        ),
        throwsStateError,
      );
    },
  );

  test('linked member IDs cannot be assigned to multiple accounts', () async {
    await store.createAccount(
      session: admin,
      login: 'student.one',
      password: 'student-pass-123',
      role: UserRole.siswa,
      memberId: 12,
    );

    await expectLater(
      store.createAccount(
        session: admin,
        login: 'teacher.three',
        password: 'teacher-pass-123',
        role: UserRole.guru,
        memberId: 12,
      ),
      throwsFormatException,
    );
  });
}
