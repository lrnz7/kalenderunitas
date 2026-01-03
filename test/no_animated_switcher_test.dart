import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalender_unitas/features/calendar/calendar_page.dart';

void main() {
  testWidgets('AnimatedSwitcher not used for month navigation', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: CalendarPage(
        isAdmin: false,
        disableRealtimeIndicator: true,
        testEvents: [],
        testHolidays: [],
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.byType(AnimatedSwitcher), findsNothing);
  });
}
