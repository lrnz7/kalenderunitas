import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalender_unitas/models/event_model.dart';
import 'package:kalender_unitas/screens/calendar_page.dart';

void main() {
  testWidgets('Crowded day displays full division names and +N overflow',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final events = [
      EventModel(id: 'e1', title: 'A', startDate: today, division: 'PSDM'),
      EventModel(id: 'e2', title: 'B', startDate: today, division: 'Unitas SI'),
      EventModel(id: 'e3', title: 'C', startDate: today, division: 'Umum'),
      EventModel(id: 'e4', title: 'D', startDate: today, division: 'BPH'),
      EventModel(id: 'e5', title: 'E', startDate: today, division: 'Komwira'),
    ];

    await tester.pumpWidget(MaterialApp(
        home: CalendarPage(
            isAdmin: false,
            testEvents: events,
            testHolidays: [],
            disableRealtimeIndicator: true)));

    // Allow build
    await tester.pumpAndSettle();

    // Verify that several division names are present
    // Several matches may exist (legend + cell), assert at least one
    expect(find.text('PSDM'), findsWidgets);
    expect(find.text('Unitas'), findsWidgets); // 'Unitas SI' maps to 'Unitas'
    expect(find.text('Umum'), findsWidgets);

    // Because we added 5 events, we should see an overflow indicator +2
    expect(find.text('+2'), findsOneWidget);
  });
}
