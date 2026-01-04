import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kalender_unitas/screens/calendar_page.dart';

void main() {
  testWidgets('Calendar page builds and shows month label on narrow screen',
      (tester) async {
    // Narrow mobile-like width
    final mq = const MediaQueryData(size: Size(280, 800));

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

    // There should be an AppBar.
    expect(find.byType(AppBar), findsOneWidget);

    // The invisible month text should not exist anymore (we removed the label)
    final label = DateFormat.MMMM().format(DateTime.now());
    expect(find.text(label), findsNothing);

    // Ensure original navigation icons exist: prev/next month chevrons and year chevrons are NOT present
    expect(find.byKey(const Key('prev_button')), findsOneWidget);
    expect(find.byKey(const Key('next_button')), findsOneWidget);
    expect(find.byKey(const Key('prev_year_button')), findsNothing);
    expect(find.byKey(const Key('next_year_button')), findsNothing);

    // Verify the month dropdown shows the full month name (not abbreviated)
    final selectedMonthUpper =
        DateFormat.MMMM().format(DateTime.now()).toUpperCase();
    expect(find.text(selectedMonthUpper), findsOneWidget);

    // Open month dropdown and select a different month to ensure it triggers a change
    final currentMonth = DateTime.now().month;
    final targetMonth = currentMonth % 12 + 1;
    final targetLabel = DateFormat.MMMM().format(DateTime(2000, targetMonth));

    await tester.tap(find.byKey(const Key('month_dropdown')));
    await tester.pumpAndSettle();

    // Tap the target month in the dropdown
    await tester.tap(find.text(targetLabel).last);
    await tester.pumpAndSettle();

    // The selected (displayed) month should now match the target and be uppercased
    final displayed = find.text(targetLabel.toUpperCase());
    expect(displayed, findsWidgets);
  });
}
