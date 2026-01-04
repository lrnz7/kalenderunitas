import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalender_unitas/features/calendar/month_model.dart';
import 'package:kalender_unitas/features/calendar/month_view.dart';
import 'package:kalender_unitas/models/event_model.dart';

void main() {
  testWidgets('MonthView renders without throwing for narrow width',
      (tester) async {
    // Create a single event with a long division name that previously
    // caused truncation to verify painting path works under narrow width.
    final now = DateTime.now();
    final event = EventModel(
      id: 'e1',
      title: 'Test Event',
      description: 'desc',
      startDate:
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      division: 'Unitas SI',
    );

    final eventsMap = <String, List<EventModel>>{
      // Use today's date as key
      '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}':
          [event]
    };

    final model = MonthModel.fromMaps(DateTime.now(), eventsMap, {});

    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: 300, // narrow width
          height: 520,
          child: MonthView(model: model),
        ),
      ),
    ));

    await tester.pumpAndSettle();

    // Ensure the CustomPaint exists and no exceptions thrown during paint.
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
