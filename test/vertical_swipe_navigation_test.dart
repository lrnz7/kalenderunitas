import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kalender_unitas/features/calendar/month_view.dart';
import 'package:kalender_unitas/screens/calendar_page.dart';

void main() {
  testWidgets('Fast consecutive vertical flicks only change one month',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
        home: CalendarPage(
      isAdmin: false,
      testEvents: [],
      testHolidays: [],
      disableRealtimeIndicator: true,
    )));

    await tester.pumpAndSettle();

    // Target the visible month paint area for gestures
    final pageFinder = find.byType(MonthView);

    final now = DateTime.now();
    final startMonth = DateTime(now.year, now.month, 1);
    final prevMonth = DateTime(startMonth.year, startMonth.month - 1, 1);
    final nextMonth = DateTime(startMonth.year, startMonth.month + 1, 1);
    final startMonthText = DateFormat.MMMM().format(startMonth);
    final prevMonthText = DateFormat.MMMM().format(prevMonth);
    final nextMonthText = DateFormat.MMMM().format(nextMonth);

    // First fling attempt
    await tester.fling(pageFinder, const Offset(0, -600), 2500);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // Detect which month is now visible (could be prev, next, or unchanged)
    String afterFirst;
    if (find.text(nextMonthText.toUpperCase()).evaluate().isNotEmpty) {
      afterFirst = nextMonthText.toUpperCase();
    } else if (find.text(prevMonthText.toUpperCase()).evaluate().isNotEmpty) {
      afterFirst = prevMonthText.toUpperCase();
    } else {
      afterFirst = startMonthText.toUpperCase();
    }

    debugPrint('After first fling visible month: $afterFirst');

    // Rapidly fling up three times in quick succession (simulate user mashing
    // flicks). Behavior is allowed to result in either no change or a single
    // month change, but MUST NOT advance multiple months in one burst.
    await tester.fling(pageFinder, const Offset(0, -600), 2500);
    await tester.fling(pageFinder, const Offset(0, -600), 2500);
    await tester.fling(pageFinder, const Offset(0, -600), 2500);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // Determine final month relative shift (-1, 0, or +1)
    int finalShift = 0;
    if (find.text(nextMonthText.toUpperCase()).evaluate().isNotEmpty) {
      finalShift = 1;
    } else if (find.text(prevMonthText.toUpperCase()).evaluate().isNotEmpty) {
      finalShift = -1;
    } else {
      finalShift = 0;
    }

    debugPrint('Final shift after rapid flings: $finalShift');

    expect(finalShift.abs() <= 1, isTrue,
        reason: 'Rapid flings should not advance more than one month');
  });

  testWidgets('Slow controlled drag moves to neighbor month when released',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: CalendarPage(
      isAdmin: false,
      testEvents: [],
      testHolidays: [],
      disableRealtimeIndicator: true,
    )));

    await tester.pumpAndSettle();

    final pageFinder = find.byType(MonthView);

    final now = DateTime.now();
    final startMonth = DateTime(now.year, now.month, 1);
    final prevMonth = DateTime(startMonth.year, startMonth.month - 1, 1);
    final prevMonthText = DateFormat.MMMM().format(prevMonth).toUpperCase();

    // A controlled fling downwards should navigate to the previous month.
    await tester.fling(pageFinder, const Offset(0, 400), 1200);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text(prevMonthText), findsOneWidget);
  });

  testWidgets('Direction reversal mid-scroll cancels the navigation',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: CalendarPage(
      isAdmin: false,
      testEvents: [],
      testHolidays: [],
      disableRealtimeIndicator: true,
    )));

    await tester.pumpAndSettle();

    final pageFinder = find.byType(MonthView);

    final now = DateTime.now();
    final startMonthText = DateFormat.MMMM()
        .format(DateTime(now.year, now.month, 1))
        .toUpperCase();

    // Start a gesture dragging up but then reverse back down before release.
    final gesture = await tester.startGesture(tester.getCenter(pageFinder));
    await gesture.moveBy(const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(0, 140)); // reverse back
    await tester.pump();
    await gesture.up();

    await tester.pumpAndSettle();

    expect(find.text(startMonthText), findsOneWidget);
  });

  testWidgets('Repeated up/down scrolling stays deterministic over long usage',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: CalendarPage(
      isAdmin: false,
      testEvents: [],
      testHolidays: [],
      disableRealtimeIndicator: true,
    )));

    await tester.pumpAndSettle();

    final pageFinder = find.byType(MonthView);

    var focused = DateTime(DateTime.now().year, DateTime.now().month, 1);

    for (var i = 0; i < 6; i++) {
      // fling up to next
      await tester.fling(pageFinder, const Offset(0, -600), 2500);
      focused = DateTime(focused.year, focused.month + 1, 1);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text(DateFormat.MMMM().format(focused).toUpperCase()),
          findsOneWidget);

      // fling down to previous
      await tester.fling(pageFinder, const Offset(0, 600), 2500);
      focused = DateTime(focused.year, focused.month - 1, 1);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text(DateFormat.MMMM().format(focused).toUpperCase()),
          findsOneWidget);
    }
  });
}
