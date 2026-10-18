import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart' show DashboardPage;
import 'package:flutter_application_1/models/library_models.dart';
import 'package:flutter_application_1/models/loan_report.dart';
import 'package:flutter_application_1/models/user_profile.dart';
import 'package:flutter_application_1/pages/loan_reports_page.dart';
import 'package:flutter_application_1/services/loan_report_pdf_service.dart';
import 'package:flutter_application_1/services/user_account_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<AuthenticatedSession> createAdminSession() async {
    SharedPreferences.setMockInitialValues({});
    final accounts = const UserAccountStore(useIsolates: false);
    final admin = await accounts.createInitialAdmin(
      login: 'admin@email.com',
      password: 'password123',
    );
    return accounts.authenticate(admin.login, 'password123');
  }

  final loans = [
    Loan(
      id: 1,
      bookId: 10,
      memberId: 2,
      bookTitle: 'Buku Januari',
      memberName: 'Siswa Satu',
      borrowedAt: DateTime(2025, 1, 31, 23, 50),
      dueAt: DateTime(2025, 2, 7),
    ),
    Loan(
      id: 2,
      bookId: 11,
      memberId: 2,
      bookTitle: 'Buku Februari',
      memberName: 'Siswa Satu',
      borrowedAt: DateTime(2025, 2, 1, 0, 10),
      dueAt: DateTime(2025, 2, 5),
      returnedAt: DateTime(2025, 2, 6),
    ),
    Loan(
      id: 3,
      bookId: 12,
      memberId: 3,
      bookTitle: 'Buku Dikembalikan Januari',
      memberName: 'Siswa Dua',
      borrowedAt: DateTime(2024, 12, 30),
      dueAt: DateTime(2025, 1, 5),
      returnedAt: DateTime(2025, 1, 8),
    ),
  ];

  test('daily report includes loans and returns on the selected day', () {
    final report = LoanReportSnapshot(
      loans: loans,
      period: LoanReportPeriod.daily,
      selectedDate: DateTime(2025, 1, 8),
      status: LoanReportStatus.all,
      asOf: DateTime(2025, 1, 8),
    );

    expect(report.loans.map((loan) => loan.id), [3]);
    expect(report.borrowedCount, 0);
    expect(report.booksBorrowed, 0);
    expect(report.uniqueBorrowers, 0);
    expect(report.returnedCount, 1);
    expect(report.activeCount, 0);
    expect(report.overdueCount, 1);
  });

  test(
    'monthly report uses calendar boundaries and counts unique borrowers',
    () {
      final report = LoanReportSnapshot(
        loans: loans,
        period: LoanReportPeriod.monthly,
        selectedDate: DateTime(2025, 2, 19),
        status: LoanReportStatus.all,
        asOf: DateTime(2025, 2, 19),
      );

      expect(report.loans.map((loan) => loan.id), [2]);
      expect(report.borrowedCount, 1);
      expect(report.booksBorrowed, 1);
      expect(report.uniqueBorrowers, 1);
      expect(report.returnedCount, 1);
      expect(report.activeCount, 0);
      expect(report.overdueCount, 1);
    },
  );

  test('status filter selects overdue returned transactions', () {
    final report = LoanReportSnapshot(
      loans: loans,
      period: LoanReportPeriod.monthly,
      selectedDate: DateTime(2025, 1),
      status: LoanReportStatus.overdue,
      asOf: DateTime(2025, 1, 31),
    );

    expect(report.loans.map((loan) => loan.id), [3]);
  });

  test('PDF is generated for populated and empty reports', () async {
    final adminSession = await createAdminSession();
    final service = LoanReportPdfService();
    final populated = await service.createPdf(
      LoanReportSnapshot(
        loans: loans,
        period: LoanReportPeriod.monthly,
        selectedDate: DateTime(2025, 2),
        status: LoanReportStatus.all,
        asOf: DateTime(2025, 2, 19),
      ),
      session: adminSession,
    );
    final empty = await service.createPdf(
      LoanReportSnapshot(
        loans: const [],
        period: LoanReportPeriod.daily,
        selectedDate: DateTime(2025, 3, 4),
        status: LoanReportStatus.all,
        asOf: DateTime(2025, 3, 4),
      ),
      session: adminSession,
    );

    expect(utf8.decode(populated.take(5).toList()), '%PDF-');
    expect(utf8.decode(empty.take(5).toList()), '%PDF-');
    expect(populated.length, greaterThan(1000));
    expect(empty.length, greaterThan(1000));
  });

  test('PDF generation handles a multi-page transaction table', () async {
    final adminSession = await createAdminSession();
    final manyLoans = List.generate(
      80,
      (index) => Loan(
        id: index + 1,
        bookId: index + 1,
        memberId: index + 1,
        bookTitle: 'Judul Buku ${index + 1} untuk laporan beberapa halaman',
        memberName: 'Anggota ${index + 1}',
        borrowedAt: DateTime(2025, 3, 10),
        dueAt: DateTime(2025, 3, 20),
      ),
    );
    final bytes = await LoanReportPdfService().createPdf(
      LoanReportSnapshot(
        loans: manyLoans,
        period: LoanReportPeriod.monthly,
        selectedDate: DateTime(2025, 3),
        status: LoanReportStatus.all,
        asOf: DateTime(2025, 3, 10),
      ),
      session: adminSession,
    );

    expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
    expect(bytes.length, greaterThan(5000));
  });

  test('only Admin sessions can generate PDF reports', () async {
    final admin = await createAdminSession();
    final accounts = const UserAccountStore(useIsolates: false);
    final teacher = await accounts.createAccount(
      session: admin,
      login: 'guru.report',
      password: 'teacher-pass-123',
      role: UserRole.guru,
    );
    final student = await accounts.createAccount(
      session: admin,
      login: 'siswa.report',
      password: 'student-pass-123',
      role: UserRole.siswa,
    );
    final report = LoanReportSnapshot(
      loans: loans,
      period: LoanReportPeriod.monthly,
      selectedDate: DateTime(2025, 2),
      status: LoanReportStatus.all,
    );
    final service = LoanReportPdfService();

    for (final account in [teacher, student]) {
      final session = await accounts.authenticate(
        account.login,
        account.role == UserRole.guru ? 'teacher-pass-123' : 'student-pass-123',
      );
      await expectLater(
        service.createPdf(report, session: session),
        throwsStateError,
      );
    }
  });

  testWidgets('reports page switches period and opens its date selector', (
    WidgetTester tester,
  ) async {
    final adminSession = await createAdminSession();
    await tester.pumpWidget(
      MaterialApp(
        home: LoanReportsPage(session: adminSession, loans: const []),
      ),
    );

    expect(find.text('Ringkasan Harian'), findsOneWidget);
    expect(
      find.text('Tidak ada transaksi untuk periode dan filter ini.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Bulanan'));
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan Bulanan'), findsOneWidget);
    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pumpAndSettle();
    expect(find.text('Pilih bulan dan tahun'), findsOneWidget);
    expect(find.text('Bulan'), findsOneWidget);
    expect(find.text('Tahun'), findsOneWidget);
    await tester.tap(find.text('Batal'));
  });

  testWidgets('Laporan is available from the main navigation', (
    WidgetTester tester,
  ) async {
    final adminSession = await createAdminSession();
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardPage(
          session: adminSession,
          accountStore: const UserAccountStore(useIsolates: false),
          userProfile: UserProfile(
            id: adminSession.userId,
            email: adminSession.login,
            role: adminSession.role.label,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Laporan').last);
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan Harian'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Cetak PDF'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Cetak PDF'), findsOneWidget);
    expect(find.text('Bagikan PDF'), findsOneWidget);
  });
}
