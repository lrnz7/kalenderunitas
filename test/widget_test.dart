// File: test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kalender_unitas/main.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const MyApp());

    // Verify app starts
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Calendar page loads', (WidgetTester tester) async {
    // Render MainPage directly to avoid waiting on app-level futures
    await tester.pumpWidget(const MaterialApp(home: MainPage(isAdmin: false)));

    // Allow frame to build
    await tester.pumpAndSettle();

    // Should find calendar label in bottom nav
    expect(find.text('Kalender'), findsOneWidget);
  });
}
