import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../models/holiday_model.dart';
import '../../shared/utils/helpers.dart';

enum DaySpanType { start, middle, end }

class DaySpanMarker {
  final String eventId;
  final DaySpanType type;
  final String division; // used for coloring
  final String? label; // shown only for start/end

  DaySpanMarker({
    required this.eventId,
    required this.type,
    required this.division,
    this.label,
  });
}

/// A lightweight, immutable marker representation intended for painting.
class EventMarker {
  final String eventId;
  final String division;
  final String label;
  final Color color;

  EventMarker({
    required this.eventId,
    required this.division,
    required this.label,
    required this.color,
  });
}

class MonthModel {
  final int year;
  final int month;
  final List<DateTime> days; // 42 fixed cells, starting from month grid start
  final Map<String, List<EventModel>> eventsByDate; // key yyyy-MM-dd
  final Map<String, List<HolidayModel>> holidaysByDate; // key yyyy-MM-dd
  // Precomputed multi-day span markers keyed by date string
  final Map<String, List<DaySpanMarker>> spansByDate;
  // Precomputed per-day event markers (immutable, ready for painting)
  final Map<String, List<EventMarker>> markersByDate;

  MonthModel({
    required this.year,
    required this.month,
    required this.days,
    required this.eventsByDate,
    required this.holidaysByDate,
    required this.spansByDate,
    required this.markersByDate,
  });

  String get key =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

  /// Build a MonthModel from global maps of events/holidays and a focused
  /// month. This performs all heavy work so the widget's build() remains cheap.
  factory MonthModel.fromMaps(
      DateTime focused,
      Map<String, List<EventModel>> eventsMap,
      Map<String, List<HolidayModel>> holidaysMap) {
    final year = focused.year;
    final month = focused.month;

    // compute first cell: first day of month, back up to Monday (weekday 1)
    final firstDayOfMonth = DateTime(year, month, 1);
    final startWeekday = firstDayOfMonth.weekday; // 1..7
    final daysBefore = startWeekday - 1; // 0..6
    final startDate = firstDayOfMonth.subtract(Duration(days: daysBefore));

    const totalDays = 42;
    final days = List<DateTime>.generate(
        totalDays, (i) => startDate.add(Duration(days: i)));

    final formatter = DateFormat('yyyy-MM-dd');
    final eventsByDate = <String, List<EventModel>>{};
    final holidaysByDate = <String, List<HolidayModel>>{};

    for (var day in days) {
      final key = formatter.format(day);
      if (eventsMap.containsKey(key)) {
        eventsByDate[key] = List.unmodifiable(eventsMap[key]!);
      }
      if (holidaysMap.containsKey(key)) {
        holidaysByDate[key] = List.unmodifiable(holidaysMap[key]!);
      }
    }

    // Precompute multi-day span markers so rendering logic remains cheap.
    final spansByDate = <String, List<DaySpanMarker>>{};

    // Collect unique events to avoid double processing
    final uniqueEvents = <String, EventModel>{};
    for (var list in eventsMap.values) {
      for (var e in list) {
        uniqueEvents[e.id] = e;
      }
    }

    for (var e in uniqueEvents.values) {
      if (!e.isMultiDay) continue;
      final start = e.startDateTime;
      final end = e.endDateTime!;

      for (var dt = start;
          !dt.isAfter(end);
          dt = dt.add(const Duration(days: 1))) {
        final key = formatter.format(dt);
        final type = dt.isAtSameMomentAs(start)
            ? DaySpanType.start
            : (dt.isAtSameMomentAs(end) ? DaySpanType.end : DaySpanType.middle);

        spansByDate.putIfAbsent(key, () => []).add(DaySpanMarker(
              eventId: e.id,
              type: type,
              division: e.division ?? '',
              label: (type == DaySpanType.start || type == DaySpanType.end)
                  ? e.division
                  : null,
            ));
      }
    }

    // Precompute simple event marker descriptors for painting.
    final markersByDate = <String, List<EventMarker>>{};
    for (var entry in eventsByDate.entries) {
      final key = entry.key;
      final list = entry.value
          .map((e) => EventMarker(
                eventId: e.id,
                division: e.division ?? '',
                label: DivisionUtils.displayName(e.division),
                color: DivisionUtils.colorFor(e.division),
              ))
          .toList(growable: false);
      markersByDate[key] = List.unmodifiable(list);
    }

    return MonthModel(
      year: year,
      month: month,
      days: days,
      eventsByDate: eventsByDate,
      holidaysByDate: holidaysByDate,
      spansByDate: spansByDate,
      markersByDate: markersByDate,
    );
  }
}
