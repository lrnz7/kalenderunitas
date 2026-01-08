import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalender_unitas/screens/calendar_page.dart';

void main() {
  testWidgets('debug nav centers', (tester) async {
    final mq = const MediaQueryData(size: Size(320, 800));
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: mq,
        child: CalendarPage(isAdmin: true, testEvents: [], testHolidays: [], disableRealtimeIndicator: true),
      ),
    ));
    await tester.pumpAndSettle();

    final prev = find.byKey(const Key('prev_button'));
    final month = find.byKey(const Key('month_dropdown'));
    final flag = find.byTooltip('Tampilkan hari libur');

    final prevCenter = tester.getCenter(prev);
    final monthCenter = tester.getCenter(month);
    final flagCenter = tester.getCenter(flag);

    print('prevCenter: $prevCenter');
    print('monthCenter: $monthCenter');
    print('flagCenter: $flagCenter');

    final prevSize = tester.getSize(prev);
    final monthSize = tester.getSize(month);
    final flagSize = tester.getSize(flag);

    print('prevSize: $prevSize');
    print('monthSize: $monthSize');
    print('flagSize: $flagSize');

    expect(true, true);
  });
}
