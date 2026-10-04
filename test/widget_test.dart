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
}
