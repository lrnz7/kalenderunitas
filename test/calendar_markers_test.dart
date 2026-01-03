import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalender_unitas/features/calendar/month_model.dart';
import 'package:kalender_unitas/shared/utils/helpers.dart';
import 'package:kalender_unitas/models/event_model.dart';
import 'package:kalender_unitas/models/holiday_model.dart';

void main() {
  testWidgets('Date cell markers show division label (not title)',
      (WidgetTester tester) async {
    final today = DateTime.now();
    final todayStr = '${today.year.toString().padLeft(4, '0')}-'
        "${today.month.toString().padLeft(2, '0')}-"
        "${today.day.toString().padLeft(2, '0')}";

    final event = EventModel(
      id: 'e1',
      title: 'LDO - Pelatihan',
      startDate: todayStr,
      division: 'PSDM',
    );

    final eventsMap = {
      todayStr: [event]
    };
    final holidaysMap = <String, List<HolidayModel>>{};

    final model = MonthModel.fromMaps(today, eventsMap, holidaysMap);

    // Marker should show division label
    final markers = model.markersByDate[todayStr];
    expect(markers, isNotNull);
    expect(markers!.first.label, equals('PSDM'));
    // Should not contain the event title
    expect(markers.first.label.contains('LDO'), isFalse);
  });

  testWidgets('Holiday markers include title text',
      (WidgetTester tester) async {
    final today = DateTime.now();
    final todayStr = '${today.year.toString().padLeft(4, '0')}-'
        "${today.month.toString().padLeft(2, '0')}-"
        "${today.day.toString().padLeft(2, '0')}";

    final holiday = HolidayModel(
      date: todayStr,
      title: 'Kemerdekaan',
      description: '',
      type: 'national',
    );

    final eventsMap = <String, List<EventModel>>{};
    final holidaysMap = {
      todayStr: [holiday]
    };

    final model = MonthModel.fromMaps(today, eventsMap, holidaysMap);

    // Model contains the holiday and shortName
    final hols = model.holidaysByDate[todayStr];
    expect(hols, isNotNull);
    expect(hols!.first.shortName, equals(holiday.shortName));
  });

  testWidgets('Markers remain readable on small heights (no clipping)',
      (WidgetTester tester) async {
    final today = DateTime.now();
    final todayStr = '${today.year.toString().padLeft(4, '0')}-'
        "${today.month.toString().padLeft(2, '0')}-"
        "${today.day.toString().padLeft(2, '0')}";

    final event = EventModel(
      id: 'e2',
      title: 'Long Title Event',
      startDate: todayStr,
      division: 'PSDM',
    );

    final eventsMap = {
      todayStr: [event]
    };
    final holidaysMap = <String, List<HolidayModel>>{};

    final model = MonthModel.fromMaps(today, eventsMap, holidaysMap);

    // Ensure marker label is the full division label (not truncated by UI)
    final markers = model.markersByDate[todayStr];
    expect(markers, isNotNull);
    expect(markers!.first.label, equals('PSDM'));
  });

  testWidgets('Event marker uses division color', (WidgetTester tester) async {
    final today = DateTime.now();
    final todayStr = '${today.year.toString().padLeft(4, '0')}-'
        "${today.month.toString().padLeft(2, '0')}-"
        "${today.day.toString().padLeft(2, '0')}";

    final event = EventModel(
      id: 'e3',
      title: 'Colored Event',
      startDate: todayStr,
      division: 'PSDM',
    );

    final eventsMap = {
      todayStr: [event]
    };
    final holidaysMap = <String, List<HolidayModel>>{};

    final model = MonthModel.fromMaps(today, eventsMap, holidaysMap);

    final markers = model.markersByDate[todayStr]!;
    expect(markers.first.color, equals(DivisionUtils.colorFor('PSDM')));
  });
}
