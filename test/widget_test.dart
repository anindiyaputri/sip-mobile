// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/models/user_profile.dart';
import 'package:flutter_application_1/services/user_profile_photo_store.dart';
import 'package:flutter_application_1/services/user_profile_local_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('profile storage normalizes email and isolates accounts', () async {
    final store = UserProfileLocalStore();
    final saved = await store.save(
      const UserProfile(
        email: '  Akun@SIP.id ',
        name: 'Nama Akun',
        phone: '081234567890',
      ),
    );

    expect(saved, isTrue);
    final sameAccount = await store.load('akun@sip.id');
    expect(sameAccount.name, 'Nama Akun');
    expect(sameAccount.phone, '081234567890');

    final otherAccount = await store.load('akun-lain@sip.id');
    expect(otherAccount.name, isNull);
    expect(otherAccount.phone, isNull);
  });

  test(
    'admin login initializes the default name without replacing custom name',
    () async {
      final store = UserProfileLocalStore();

      final adminProfile = await store.loadForLogin('  ADMIN@gmail.com ');
      expect(adminProfile.email, 'ADMIN@gmail.com');
      expect(adminProfile.name, 'Admin');
      expect((await store.load('admin@gmail.com')).name, 'Admin');

      await store.save(
        const UserProfile(
          email: 'admin@gmail.com',
          name: 'Nama belum diisi',
          phone: '081234567890',
        ),
      );
      final placeholderProfile = await store.loadForLogin('admin@gmail.com');
      expect(placeholderProfile.name, 'Admin');
      expect(placeholderProfile.phone, '081234567890');

      await store.save(
        const UserProfile(email: 'admin@gmail.com', name: 'Nama Pilihan'),
      );
      final customizedProfile = await store.loadForLogin('admin@gmail.com');
      expect(customizedProfile.name, 'Nama Pilihan');
    },
  );

  test(
    'profile photo is copied locally and stays with the account profile',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'sip-profile-photo-test-',
      );
      try {
        final sourceFile = File(
          '${temporaryDirectory.path}${Platform.pathSeparator}selected.png',
        );
        await sourceFile.writeAsBytes([1, 2, 3, 4]);
        final photoStore = UserProfilePhotoStore(
          documentsDirectoryProvider: () async => temporaryDirectory,
        );
        final photoPath = await photoStore.savePickedImage(
          email: '  ADMIN@gmail.com ',
          sourcePath: sourceFile.path,
        );
        expect(photoPath, isNot(sourceFile.path));
        expect(await File(photoPath).readAsBytes(), [1, 2, 3, 4]);

        final replacementFile = File(
          '${temporaryDirectory.path}${Platform.pathSeparator}replacement.png',
        );
        await replacementFile.writeAsBytes([5, 6, 7, 8]);
        final replacementPath = await photoStore.savePickedImage(
          email: 'admin@gmail.com',
          sourcePath: replacementFile.path,
        );
        expect(replacementPath, isNot(photoPath));
        expect(await File(replacementPath).readAsBytes(), [5, 6, 7, 8]);

        final localStore = UserProfileLocalStore();
        await localStore.save(
          const UserProfile(email: 'admin@gmail.com', name: 'Admin'),
        );
        final profile = await localStore.loadForLogin('admin@gmail.com');
        final profileWithPhoto = profile.withProfilePhoto(replacementPath);
        expect(await localStore.save(profileWithPhoto), isTrue);

        final reloaded = await localStore.loadForLogin(' ADMIN@gmail.com ');
        expect(reloaded.name, 'Admin');
        expect(reloaded.photoPath, replacementPath);

        final edited = reloaded.withEditableDetails(
          name: 'Admin SIP',
          phone: '081234567890',
        );
        expect(edited.photoPath, replacementPath);
        expect(await localStore.save(edited), isTrue);
        expect(
          (await localStore.load('admin@gmail.com')).photoPath,
          replacementPath,
        );
      } finally {
        await temporaryDirectory.delete(recursive: true);
      }
    },
  );

  testWidgets('admin name is saved and shown on profile and account settings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SipMobileApp());
    await tester.enterText(
      find.byType(TextFormField).at(0),
      '  ADMIN@gmail.com ',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    expect(find.text('Admin'), findsNWidgets(2));
    expect(find.byKey(const Key('profile_photo_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('profile_photo_button')));
    await tester.pumpAndSettle();
    expect(find.text('Ambil foto menggunakan kamera'), findsOneWidget);
    expect(find.text('Pilih foto dari galeri'), findsOneWidget);
    Navigator.of(tester.element(find.text('Ambil foto menggunakan kamera')))
        .pop();
    await tester.pumpAndSettle();

    final savedProfile = await UserProfileLocalStore().load('admin@gmail.com');
    expect(savedProfile.name, 'Admin');

    await tester.scrollUntilVisible(
      find.byKey(const Key('profile_account_settings')),
      240,
    );
    await tester.tap(find.byKey(const Key('profile_account_settings')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('account_settings_name_field')),
          )
          .controller!
          .text,
      'Admin',
    );

    await tester.tap(find.byTooltip('Kembali ke Profil'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('profile_logout_button')),
      240,
    );
    await tester.tap(find.byKey(const Key('profile_logout_button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Keluar'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'admin@gmail.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    expect(find.text('Admin'), findsNWidgets(2));
  });

  testWidgets('login opens the dashboard after valid input', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SipMobileApp());

    expect(find.text('Selamat Datang Kembali'), findsOneWidget);
    expect(find.text('SIP Mobile'), findsOneWidget);
    expect(find.text('Sistem Informasi Perpustakaan'), findsOneWidget);
    expect(
      find.text('Masuk untuk mengelola perpustakaan Anda'),
      findsOneWidget,
    );
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
    await tester.scrollUntilVisible(
      find.byKey(const Key('profile_account_settings')),
      240,
    );
    expect(find.text('Edit Profil'), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.text('Pengaturan Akun'), findsOneWidget);
    expect(find.text('Tentang SIP Mobile'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Versi Aplikasi'), 240);
    expect(find.text('1.0.0+1'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('profile_logout_button')),
      240,
    );
    await tester.tap(find.byKey(const Key('profile_logout_button')));
    await tester.pumpAndSettle();
    expect(find.text('Keluar dari akun?'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Profil'), findsWidgets);

    await tester.scrollUntilVisible(
      find.byKey(const Key('profile_logout_button')),
      240,
    );
    await tester.tap(find.byKey(const Key('profile_logout_button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Keluar'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Selamat Datang Kembali'), findsOneWidget);
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
      await tester.scrollUntilVisible(
        find.byKey(const Key('profile_logout_button')),
        240,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('profile_logout_button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Keluar'),
        ),
      );
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
    expect(find.text('Selamat Datang Kembali'), findsOneWidget);

    await loginWith('kedua@sip.id');
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    expect(find.text('kedua@sip.id'), findsNWidgets(2));
    expect(find.text('pertama@sip.id'), findsNothing);
  });

  testWidgets(
    'account settings updates profile details and returns to profile page',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SipMobileApp());
      await tester.enterText(find.byType(TextFormField).at(0), 'akun@sip.id');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('profile_account_settings')),
        240,
      );
      await tester.ensureVisible(
        find.byKey(const Key('profile_account_settings')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('profile_account_settings')));
      await tester.pumpAndSettle();

      expect(find.text('Email Login'), findsOneWidget);
      expect(find.text('akun@sip.id'), findsOneWidget);
      expect(
        find.text('Email tidak dapat diubah melalui pengaturan ini.'),
        findsOneWidget,
      );
      expect(find.text('Pengaturan Akun'), findsOneWidget);
      expect(find.text('Data Profil'), findsOneWidget);
      expect(find.text('Edit Profil'), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('account_settings_name_field')),
            )
            .controller!
            .text,
        isEmpty,
      );

      await tester.enterText(
        find.byKey(const Key('account_settings_name_field')),
        'Nama Sementara',
      );
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('account_settings_name_field')),
            )
            .controller!
            .text,
        isEmpty,
      );

      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('Nama lengkap wajib diisi'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('account_settings_name_field')),
        'Rani Aulia',
      );
      await tester.tap(find.byKey(const Key('account_settings_phone_field')));
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.byKey(const Key('account_settings_phone_field')),
                matching: find.byType(EditableText),
              ),
            )
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.enterText(
        find.byKey(const Key('account_settings_phone_field')),
        '081234567890',
      );
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(
        find.text('Pengaturan akun disimpan di perangkat ini.'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Kembali ke Profil'));
      await tester.pumpAndSettle();
      expect(find.text('rani'), findsNothing);
      await tester.drag(find.byType(ListView).first, const Offset(0, 900));
      await tester.pumpAndSettle();
      expect(find.text('Rani Aulia'), findsWidgets);
      expect(find.text('akun@sip.id'), findsWidgets);
      await tester.scrollUntilVisible(find.text('081234567890'), 240);
      expect(find.text('081234567890'), findsOneWidget);

      final savedProfile = await UserProfileLocalStore().load('akun@sip.id');
      expect(savedProfile.name, 'Rani Aulia');
      expect(savedProfile.phone, '081234567890');

      await tester.scrollUntilVisible(
        find.byKey(const Key('profile_account_settings')),
        240,
      );
      await tester.tap(find.byKey(const Key('profile_account_settings')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('account_settings_name_field')),
            )
            .controller!
            .text,
        'Rani Aulia',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('account_settings_phone_field')),
            )
            .controller!
            .text,
        '081234567890',
      );
      await tester.tap(find.byTooltip('Kembali ke Profil'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('profile_logout_button')),
        240,
      );
      await tester.tap(find.byKey(const Key('profile_logout_button')));
      await tester.pumpAndSettle();
      expect(find.text('Keluar dari akun?'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Keluar'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Selamat Datang Kembali'), findsOneWidget);

      final profileAfterLogout = await UserProfileLocalStore().load(
        'akun@sip.id',
      );
      expect(profileAfterLogout.name, 'Rani Aulia');
      expect(profileAfterLogout.phone, '081234567890');

      await tester.enterText(find.byType(TextFormField).at(0), 'akun@sip.id');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      expect(find.text('Rani Aulia'), findsNWidgets(2));
      expect(find.text('081234567890'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('profile_account_settings')),
        240,
      );
      await tester.tap(find.byKey(const Key('profile_account_settings')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('account_settings_name_field')),
            )
            .controller!
            .text,
        'Rani Aulia',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('account_settings_phone_field')),
            )
            .controller!
            .text,
        '081234567890',
      );
    },
  );
}
