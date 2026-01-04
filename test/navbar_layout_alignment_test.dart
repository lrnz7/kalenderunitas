import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalender_unitas/screens/calendar_page.dart';

void main() {
  testWidgets('Navbar items are vertically aligned and consistent (narrow)',
      (tester) async {
    final mq = const MediaQueryData(size: Size(320, 800));
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: mq,
        child: CalendarPage(
            isAdmin: true,
            testEvents: [],
            testHolidays: [],
            disableRealtimeIndicator: true),
      ),
    ));
    await tester.pumpAndSettle();

    final prev = find.byKey(const Key('prev_button'));
    final next = find.byKey(const Key('next_button'));
    final month = find.byKey(const Key('month_dropdown'));
    final flag = find.byTooltip('Tampilkan hari libur');

    expect(prev, findsOneWidget);
    expect(next, findsOneWidget);
    expect(month, findsOneWidget);
    expect(flag, findsOneWidget);

    final prevCenter = tester.getCenter(prev);
    final nextCenter = tester.getCenter(next);
    final monthCenter = tester.getCenter(month);
    final flagCenter = tester.getCenter(flag);

    // All vertical centers should be approximately equal (aligned)
    expect((prevCenter.dy - monthCenter.dy).abs() < 2.0, true);
    expect((nextCenter.dy - monthCenter.dy).abs() < 2.0, true);
    expect((flagCenter.dy - monthCenter.dy).abs() < 2.0, true);

    // Sizes should be consistent for nav chevrons
    final prevSize = tester.getSize(prev);
    final nextSize = tester.getSize(next);
    expect(prevSize, equals(nextSize));

    // Check horizontal spacing is consistent between items (approx)
    final prevRight = tester.getRect(prev).right;
    final monthLeft = tester.getRect(month).left;
    final gap1 = (monthLeft - prevRight).abs();

    final monthRight = tester.getRect(month).right;
    final nextLeft = tester.getRect(next).left;
    final gap2 = (nextLeft - monthRight).abs();

    // Gaps should be roughly similar
    expect((gap1 - gap2).abs() < 8.0, true);
  });

  testWidgets('Navbar items are vertically aligned and consistent (wide)',
      (tester) async {
    final mq = const MediaQueryData(size: Size(1024, 800));
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: mq,
        child: CalendarPage(
            isAdmin: true,
            testEvents: [],
            testHolidays: [],
            disableRealtimeIndicator: true),
      ),
    ));
    await tester.pumpAndSettle();

    final prev = find.byKey(const Key('prev_button'));
    final next = find.byKey(const Key('next_button'));
    final month = find.byKey(const Key('month_dropdown'));

    final prevCenter = tester.getCenter(prev);
    final nextCenter = tester.getCenter(next);
    final monthCenter = tester.getCenter(month);

    expect((prevCenter.dy - monthCenter.dy).abs() < 2.0, true);
    expect((nextCenter.dy - monthCenter.dy).abs() < 2.0, true);
  });
}
