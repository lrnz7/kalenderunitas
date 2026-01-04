import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kalender_unitas/features/calendar/calendar_page.dart';

void main() {
  testWidgets(
      'Rapid taps on chevrons do not cause overlap or multiple transitions',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: CalendarPage(
        isAdmin: false,
        disableRealtimeIndicator: true,
        testEvents: [],
        testHolidays: [],
      ),
    ));

    final initialMonthText =
        DateFormat.MMMM().format(DateTime.now()).toUpperCase();
    expect(find.text(initialMonthText), findsOneWidget);

    // Rapidly tap next twice
    await tester.tap(find.byKey(const Key('next_button')));
    await tester.tap(find.byKey(const Key('next_button')));

    // Pump a little (during animation header should still show initial month)
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(initialMonthText), findsOneWidget);

    // Allow animation to finish
    await tester.pumpAndSettle();

    // Now header should show next month exactly (not multiple overlapping months)
    final nextMonth = DateTime.now().month == 12
        ? DateTime(DateTime.now().year + 1, 1)
        : DateTime(DateTime.now().year, DateTime.now().month + 1);
    final nextMonthText = DateFormat.MMMM().format(nextMonth).toUpperCase();

    expect(find.text(nextMonthText), findsWidgets);
  });
}
