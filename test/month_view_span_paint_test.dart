import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalender_unitas/features/calendar/month_view.dart';
import 'package:kalender_unitas/features/calendar/month_model.dart';
import 'package:kalender_unitas/models/event_model.dart';

void main() {
  testWidgets('Span markers are painted on middle days (debug hook)',
      (WidgetTester tester) async {
    final focused = DateTime(2025, 5, 1);

    final ev = EventModel(
      id: 's1',
      title: 'Span Test',
      startDate: '2025-05-05',
      endDate: '2025-05-07',
      division: 'UMUM',
    );

    // Only persist event on start date (no fake expansion)
    final eventsMap = <String, List<EventModel>>{
      '2025-05-05': [ev],
    };

    final model = MonthModel.fromMaps(focused, eventsMap, {});

    // Sanity: ensure model contains a span-derived marker on the middle day
    final midMarkers = model.markersByDate['2025-05-06'];
    expect(midMarkers, isNotNull);
    expect(midMarkers!.any((m) => m.isSpan && m.division == 'UMUM'), isTrue,
        reason: 'Model should contain a span-derived marker on 2025-05-06');

    // Clear debug hook and pump widget
    MonthView.debugPaintedSpans.clear();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 700, height: 600, child: MonthView(model: model)),
      ),
    ));

    // Allow a frame to draw
    await tester.pumpAndSettle();

    // Debug info: if empty, provide the captured list for debugging
    expect(MonthView.debugPaintedSpans.isNotEmpty, isTrue,
        reason: 'No spans painted; debug: ${MonthView.debugPaintedSpans}');

    // Expect that the mid date (2025-05-06) had a span painted
    expect(MonthView.debugPaintedSpans.contains('2025-05-06:UMUM'), isTrue);
  });
}
