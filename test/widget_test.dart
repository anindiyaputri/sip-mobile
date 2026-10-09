// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('login opens the dashboard after valid input', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SipMobileApp());

    expect(find.text('Selamat datang'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'admin@email.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Sistem Informasi Perpustakaan'), findsOneWidget);
    expect(find.text('Ringkasan'), findsOneWidget);
    expect(find.text('Menu Utama'), findsNothing);
    expect(find.text('Data Buku'), findsNothing);
    expect(find.text('Data Anggota'), findsNothing);
    expect(find.text('Peminjaman'), findsNothing);
    expect(find.text('Pengembalian'), findsNothing);
    expect(find.text('Buku Sedang Dipinjam'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Buku'), findsOneWidget);
    expect(find.text('Anggota'), findsWidgets);
    expect(find.text('Transaksi'), findsOneWidget);
  });

  testWidgets('menus add books and process loan returns', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SipMobileApp());
    await tester.enterText(find.byType(TextFormField).at(0), 'admin@email.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buku').last);
    await tester.pumpAndSettle();
    expect(find.text('Data Buku'), findsOneWidget);
    await tester.tap(find.text('Tambah Buku'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Buku Tes');
    await tester.enterText(find.byType(TextFormField).at(1), 'Penulis Tes');
    await tester.enterText(find.byType(TextFormField).at(2), 'Umum');
    await tester.enterText(find.byType(TextFormField).at(3), '2');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Buku Tes'), findsOneWidget);

    await tester.tap(find.text('Transaksi').last);
    await tester.pumpAndSettle();
    expect(find.text('Sedang Dipinjam (2)'), findsOneWidget);
    await tester.tap(find.byTooltip('Proses pengembalian').first);
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Pengembalian (1)'), findsOneWidget);
    expect(find.text('Sedang Dipinjam (1)'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pinjam Buku'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Sedang Dipinjam (2)'), findsOneWidget);
  });

  testWidgets('profile shows entered email and confirms logout', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SipMobileApp());
    await tester.enterText(find.byType(TextFormField).at(0), 'petugas@sip.id');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    expect(find.text('Nama belum diisi'), findsNWidgets(2));
    expect(find.text('Nomor telepon belum diisi'), findsOneWidget);
    expect(find.text('petugas@sip.id'), findsNWidgets(2));
    expect(find.text('Peran pengguna'), findsNothing);
    await tester.scrollUntilVisible(find.text('Edit Profil'), 240);
    expect(find.text('Edit Profil'), findsOneWidget);
    expect(find.text('Pengaturan Akun'), findsOneWidget);
    expect(find.text('Tentang SIP Mobile'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Versi Aplikasi'), 240);
    expect(find.text('1.0.0+1'), findsOneWidget);

    await tester.scrollUntilVisible(find.byType(OutlinedButton), 240);
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(find.text('Keluar dari akun?'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Profil'), findsWidgets);

    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar').last);
    await tester.pumpAndSettle();
    expect(find.text('Selamat datang'), findsOneWidget);
  });

  testWidgets('profile email follows each locally validated login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SipMobileApp());

    Future<void> loginWith(String email) async {
      await tester.enterText(find.byType(TextFormField).at(0), email);
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();
    }

    Future<void> logout() async {
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byType(OutlinedButton), 240);
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keluar').last);
      await tester.pumpAndSettle();
    }

    await loginWith('pertama@sip.id');
    await tester.tap(find.text('Buku').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anggota').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transaksi').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    expect(find.text('pertama@sip.id'), findsNWidgets(2));

    await logout();
    expect(find.text('Selamat datang'), findsOneWidget);

    await loginWith('kedua@sip.id');
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    expect(find.text('kedua@sip.id'), findsNWidgets(2));
    expect(find.text('pertama@sip.id'), findsNothing);
  });

  testWidgets(
    'edit profile updates session details without changing email or role',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SipMobileApp());
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'profile@sip.id',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Edit Profil'), 240);
      await tester.tap(find.text('Edit Profil'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('Nama lengkap wajib diisi'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('profile_name_field')),
        'Dewi Putri',
      );
      await tester.enterText(
        find.byKey(const Key('profile_phone_field')),
        '+628123456789',
      );
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, 1000));
      await tester.pumpAndSettle();
      expect(find.text('Dewi Putri'), findsWidgets);
      await tester.scrollUntilVisible(find.text('+628123456789'), 240);
      expect(find.text('+628123456789'), findsOneWidget);
      expect(find.text('profile@sip.id'), findsWidgets);
      expect(find.text('Peran pengguna'), findsNothing);
      expect(
        find.text(
          'Profil diperbarui untuk sesi ini; perubahan belum tersimpan permanen.',
        ),
        findsOneWidget,
      );
    },
  );
}
