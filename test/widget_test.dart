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

    await tester.tap(find.text('Pinjam Buku'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Sedang Dipinjam (2)'), findsOneWidget);
  });
}
