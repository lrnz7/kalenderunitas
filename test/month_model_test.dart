import 'package:flutter_test/flutter_test.dart';
import 'package:kalender_unitas/features/calendar/month_model.dart';
import 'package:kalender_unitas/models/event_model.dart';
import 'package:kalender_unitas/models/holiday_model.dart';

void main() {
  test(
      'MonthModel.fromMaps produces 42 days and includes first/last month days',
      () {
    final focused = DateTime(2025, 5, 1);

    // Create maps with an event spanning multiple days inside May 2025
    final ev = EventModel(
      id: 'e1',
      title: 'Test Event',
      startDate: '2025-05-05',
      endDate: '2025-05-07',
    );

    final eventsMap = <String, List<EventModel>>{
      '2025-05-05': [ev],
      '2025-05-06': [ev],
      '2025-05-07': [ev],
    };

    final holiday = HolidayModel(
      date: '2025-05-01',
      title: 'Labor Day',
      description: 'Test',
      type: 'national',
    );

    final holidaysMap = <String, List<HolidayModel>>{
      '2025-05-01': [holiday],
    };

    final model = MonthModel.fromMaps(focused, eventsMap, holidaysMap);

    // 7x6 grid
    expect(model.days.length, 42);

    // Ensure the first day of the calendar contains the first day of the month
    final containsFirst =
        model.days.any((d) => d.year == 2025 && d.month == 5 && d.day == 1);
    expect(containsFirst, isTrue);

    // Ensure event keys were mapped into the model
    expect(model.eventsByDate.containsKey('2025-05-05'), isTrue);
    expect(model.eventsByDate['2025-05-05']!.first.title, 'Test Event');

    // Ensure holiday present
    expect(model.holidaysByDate.containsKey('2025-05-01'), isTrue);
    expect(model.holidaysByDate['2025-05-01']!.first.title, 'Labor Day');

    // Multi-day span markers should be precomputed: start/middle/end
    expect(model.spansByDate.containsKey('2025-05-05'), isTrue);
    expect(model.spansByDate.containsKey('2025-05-06'), isTrue);
    expect(model.spansByDate.containsKey('2025-05-07'), isTrue);

    final startMarker = model.spansByDate['2025-05-05']!.first;
    final middleMarker = model.spansByDate['2025-05-06']!.first;
    final endMarker = model.spansByDate['2025-05-07']!.first;

    expect(startMarker.type, DaySpanType.start);
    expect(middleMarker.type, DaySpanType.middle);
    expect(endMarker.type, DaySpanType.end);
  });
}
