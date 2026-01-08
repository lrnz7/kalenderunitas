import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalender_unitas/screens/calendar_page.dart';

void main() {
  testWidgets('Center cluster is horizontally centered on wide screens',
      (WidgetTester tester) async {
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(1200, 800)),
      child: MaterialApp(
        home: CalendarPage(
            isAdmin: false,
            disableRealtimeIndicator: true,
            testEvents: [],
            testHolidays: []),
      ),
    ));

    await tester.pumpAndSettle();

    final prev = find.byKey(const Key('prev_button'));
    final next = find.byKey(const Key('next_button'));

    expect(prev, findsOneWidget);
    expect(next, findsOneWidget);

    // Compute combined bounding rect of center cluster (prev..next)
    final prevTopLeft = tester.getTopLeft(prev);
    final nextBottomRight = tester.getBottomRight(next);

    final combinedCenterX = (prevTopLeft.dx + nextBottomRight.dx) / 2.0;

    final appBar = find.byType(AppBar);
    final appBarSize = tester.getSize(appBar);
    final appBarCenterX = appBarSize.width / 2.0;

    expect((combinedCenterX - appBarCenterX).abs() < 8.0, isTrue,
        reason:
            'Center cluster is not centered (diff: ${(combinedCenterX - appBarCenterX).abs()})');

    // Also ensure the center cluster does not visually merge with the right zone
    final nextRight = tester.getBottomRight(next).dx;
    final yearLeft =
        tester.getTopLeft(find.byKey(const Key('year_dropdown'))).dx;
    expect(yearLeft - nextRight >= 40, isTrue,
        reason:
            'Center cluster is too close to right zone; found gap ${yearLeft - nextRight}');
  });

  testWidgets('Navbar does not overflow on narrow screens',
      (WidgetTester tester) async {
    // Very narrow width to force potential overflow
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(260, 600)),
      child: MaterialApp(
        home: CalendarPage(
            isAdmin: false,
            disableRealtimeIndicator: true,
            testEvents: [],
            testHolidays: []),
      ),
    ));

    await tester.pumpAndSettle();

    // If layout overflow occurs it will typically throw during build/pump; reaching here implies success
    expect(find.byKey(const Key('prev_button')), findsOneWidget);
    expect(find.byKey(const Key('month_dropdown')), findsOneWidget);
    expect(find.byKey(const Key('next_button')), findsOneWidget);
  });
}
