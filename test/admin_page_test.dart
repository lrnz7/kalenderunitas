import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalender_unitas/screens/admin_page.dart';

void main() {
  testWidgets('Admin create-event dropdown contains Unitas SI',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminPage()));

    // Tap the dropdown to open menu
    // The second DropdownButtonFormField is the Divisi field
    final dropdownFinder = find.byType(DropdownButtonFormField<String>).at(1);
    expect(dropdownFinder, findsOneWidget);

    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    // Now the menu items should be visible, including "Unitas SI"
    expect(find.text('Unitas SI'), findsWidgets);
  });
}
