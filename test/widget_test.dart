// File: test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kalender_unitas_sistem_informasi/main.dart'; // GANTI NAMA PACKAGE

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const MyApp());

    // Verify app starts
    expect(find.byType(MaterialApp), findsOneWidget);
  });
  
  testWidgets('Calendar page loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    // Wait for app to load
    await tester.pumpAndSettle();
    
    // Should find calendar text
    expect(find.text('Kalender'), findsOneWidget);
  });
}