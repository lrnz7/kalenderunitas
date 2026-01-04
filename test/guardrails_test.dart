import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kalender_unitas/screens/calendar_page.dart';
import 'package:kalender_unitas/features/calendar/month_model.dart';

void main() {
  testWidgets('Page recenters to page 1 after navigation and unlocks lock',
      (tester) async {
    MonthModel.debugResetFromMapsCalls();

    await tester.pumpWidget(MaterialApp(
        home: CalendarPage(
      isAdmin: false,
      testEvents: [],
      testHolidays: [],
      disableRealtimeIndicator: true,
    )));

    await tester.pumpAndSettle();

    // initial models prepared (prev/current/next)
    expect(MonthModel.debugFromMapsCalls(), greaterThanOrEqualTo(1));

    final state = tester.state(find.byType(CalendarPage));

    // Ensure initial page is 1
    expect((state as dynamic).debugCurrentPage(), equals(1.0));
    expect((state as dynamic).debugIsTransitioning(), isFalse);

    // Navigate to next month via fling
    final monthFinder = find.byType(PageView);
    await tester.fling(find.byType(PageView), const Offset(0, -600), 2500);
    await tester.pump(const Duration(milliseconds: 200));

    // While animating transition lock should be held true
    expect((state as dynamic).debugIsTransitioning(), isTrue);

    await tester.pumpAndSettle();

    // After settle page should be recentered and lock cleared
    expect((state as dynamic).debugCurrentPage(), equals(1.0));
    expect((state as dynamic).debugIsTransitioning(), isFalse);

    // MonthModel.fromMaps should have been called an additional ~3 times
    expect(MonthModel.debugFromMapsCalls(), greaterThanOrEqualTo(4));
  });

  testWidgets('No multi-month skips per gesture burst (stress)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: CalendarPage(
      isAdmin: false,
      testEvents: [],
      testHolidays: [],
      disableRealtimeIndicator: true,
    )));

    await tester.pumpAndSettle();

    final pageFinder = find.byType(PageView);

    // Simulate rapid burst of flings
    await tester.fling(pageFinder, const Offset(0, -600), 2500);
    await tester.fling(pageFinder, const Offset(0, -600), 2500);
    await tester.fling(pageFinder, const Offset(0, -600), 2500);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // After the burst, ensure the visible month is only shifted by at most one
    final header = find
        .descendant(of: find.byType(AppBar), matching: find.byType(Text))
        .first;
    final headerText = (tester.widget<Text>(header)).data ?? '';

    // Count how many months away from now the header is (approx)
    final now = DateTime.now();
    final headerMonth = headerText.toLowerCase().contains(DateFormat.MMMM()
            .format(now.add(const Duration(days: 31)))
            .toLowerCase())
        ? 1
        : 0;

    expect(headerMonth.abs() <= 1, isTrue);
  });

  testWidgets('Transition lock prevents overlapping month commits',
      (tester) async {
    MonthModel.debugResetFromMapsCalls();

    await tester.pumpWidget(MaterialApp(
        home: CalendarPage(
      isAdmin: false,
      testEvents: [],
      testHolidays: [],
      disableRealtimeIndicator: true,
    )));

    await tester.pumpAndSettle();

    final state = tester.state(find.byType(CalendarPage));

    // Rapidly tap next twice
    await tester.tap(find.byKey(const Key('next_button')));
    await tester.tap(find.byKey(const Key('next_button')));

    await tester.pump(const Duration(milliseconds: 100));

    // During the animation the transition lock should be engaged
    expect((state as dynamic).debugIsTransitioning(), isTrue);

    await tester.pumpAndSettle();

    // After settle lock should be cleared and only about +1 month change happened
    expect((state as dynamic).debugIsTransitioning(), isFalse);
    expect(MonthModel.debugFromMapsCalls(), greaterThanOrEqualTo(4));
  });
}
