import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalender_unitas/screens/calendar_page.dart';

void main() {
  testWidgets(
      'Navbar left cluster (Today + Holidays) stays grouped on wide screens',
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

    final today = find.byKey(const Key('today_button'));
    final toggle = find.byKey(const Key('toggle_holidays'));
    final prev = find.byKey(const Key('prev_button'));

    expect(today, findsOneWidget);
    expect(toggle, findsOneWidget);
    expect(prev, findsOneWidget);

    final todayBox = tester.getTopLeft(today);
    final toggleBox = tester.getTopLeft(toggle);
    final prevBox = tester.getTopLeft(prev);

    // Today and toggle should be close together (less than 80px apart horizontally)
    expect((toggleBox.dx - todayBox.dx).abs() < 80, isTrue,
        reason: 'Left cluster buttons are spread too far apart');

    // Prev button (right cluster) should be significantly to the right of the toggle
    expect(prevBox.dx - toggleBox.dx > 120, isTrue,
        reason: 'Right cluster is too close; clusters not separated');

    // Ensure the right cluster does not hug the screen edge on wide screens
    final prevSize = tester.getSize(prev);
    const screenWidth = 1200.0;
    final prevRight = prevBox.dx + prevSize.width;
    expect(screenWidth - prevRight >= 40, isTrue,
        reason: 'Right cluster is hugging the screen edge');
  });
}
