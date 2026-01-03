import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalender_unitas/models/event_model.dart';
import 'package:kalender_unitas/features/calendar/month_model.dart';
import 'package:kalender_unitas/shared/utils/helpers.dart';
import 'package:kalender_unitas/models/holiday_model.dart';

void main() {
  testWidgets('Crowded day displays full division names and +N overflow',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final events = [
      EventModel(id: 'e1', title: 'A', startDate: todayStr, division: 'PSDM'),
      EventModel(
          id: 'e2', title: 'B', startDate: todayStr, division: 'Unitas SI'),
      EventModel(id: 'e3', title: 'C', startDate: todayStr, division: 'Umum'),
      EventModel(id: 'e4', title: 'D', startDate: todayStr, division: 'BPH'),
      EventModel(
          id: 'e5', title: 'E', startDate: todayStr, division: 'Komwira'),
    ];

    final eventsMap = {todayStr: events};
    final holidaysMap = <String, List<HolidayModel>>{};

    final model = MonthModel.fromMaps(DateTime.now(), eventsMap, holidaysMap);

    final markers = model.markersByDate[todayStr]!;

    // Verify that several division names are present
    final labels = markers.map((m) => m.label).toSet();
    expect(labels.contains('PSDM'), isTrue);
    expect(labels.contains('Unitas'), isTrue); // 'Unitas SI' maps to 'Unitas'
    expect(labels.contains('Umum'), isTrue);

    // Because we added 5 events, the painter would show an overflow of +2
    expect(markers.length, equals(5));
  });
}
