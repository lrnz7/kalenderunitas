import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kalender_unitas/features/calendar/calendar_page.dart';

void main() {
  testWidgets('Adjacent month navigation animates (chevron)',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: CalendarPage(
        isAdmin: false,
        disableRealtimeIndicator: true,
        testEvents: [],
        testHolidays: [],
      ),
    ));

    // initial month shown in dropdown
    final initialMonthText = DateFormat.MMMM().format(DateTime.now());
    expect(find.text(initialMonthText), findsOneWidget);

    // Tap next chevron to go to adjacent month
    await tester.tap(find.byKey(const Key('next_button')));

    // Pump a short time to simulate mid-animation; header should not yet show new month
    await tester.pump(const Duration(milliseconds: 100));

    final nextMonth = DateTime.now().month == 12
        ? DateTime(DateTime.now().year + 1, 1)
        : DateTime(DateTime.now().year, DateTime.now().month + 1);
    final nextMonthText = DateFormat.MMMM().format(nextMonth);

    // During animation, header should still show initial month
    expect(find.text(initialMonthText), findsOneWidget);

    // Allow animation to finish
    await tester.pumpAndSettle();

    // Now header should reflect the next month
    expect(find.text(nextMonthText), findsOneWidget);
  });

  testWidgets('Non-adjacent jump is instant (dropdown month/year)',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: CalendarPage(
        isAdmin: false,
        disableRealtimeIndicator: true,
        testEvents: [],
        testHolidays: [],
      ),
    ));

    final now = DateTime.now();
    final target = DateTime(now.year, now.month + 3, 1);

    final targetMonthName =
        DateFormat.MMMM().format(DateTime(2020, target.month));

    // Open month dropdown and select target month
    await tester.tap(find.byKey(const Key('month_dropdown')));
    await tester.pumpAndSettle();

    await tester.tap(find.text(targetMonthName).last);

    // Process the selection (should be instant)
    await tester.pump();

    // Header should now show the target month (at least one match)
    expect(find.text(targetMonthName), findsWidgets);
  });
}
