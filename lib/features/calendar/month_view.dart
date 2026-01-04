import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../../models/event_model.dart';
import '../../models/holiday_model.dart';
import '../../shared/utils/helpers.dart';
import 'month_model.dart';

typedef DayTapCallback = void Function(DateTime day);

/// MonthView renders a single month's grid using a CustomPainter.
///
/// Important guardrails:
/// - This widget is intentionally simple and immutable; the authoritative
///   month data comes from `MonthModel` and is prepared *outside* of build
///   and paint paths. Do not perform data computation, async loading, or
///   mapping inside `build()` or the painter; this prevents jank during
///   scroll and keeps rendering deterministic.
/// - The rendering uses `CustomPainter` and a fixed layout. Avoid introducing
///   nested scroll views or wrapping this widget in additional scrollable
///   parents. That can interfere with the vertical PageView used for month
///   navigation and violate the performance guardrails.
/// - If you need to change visuals, modify the painter without adding
///   stateful animations that trigger rebuilds per frame.
class MonthView extends StatelessWidget {
  final MonthModel model;
  final bool showHolidays;
  final DayTapCallback? onDayTap;

  const MonthView(
      {Key? key, required this.model, this.showHolidays = true, this.onDayTap})
      : super(key: key);

  bool _isCurrentMonth(DateTime day) => day.month == model.month;

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.day == now.day && day.month == now.month && day.year == now.year;
  }

  // Data accessors are intentionally minimal; painting uses model.markersByDate and holidaysByDate directly.
  List<EventModel> _getEventsForDay(DateTime day) =>
      model.eventsByDate[DateFormat('yyyy-MM-dd').format(day)] ?? [];
  List<HolidayModel> _getHolidaysForDay(DateTime day) =>
      model.holidaysByDate[DateFormat('yyyy-MM-dd').format(day)] ?? [];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          if (onDayTap == null) return;
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final local = details.localPosition;

          const horizontalPadding = 12.0;
          const verticalPadding = 12.0;
          const spacing = 8.0;

          final contentWidth = size.width - horizontalPadding * 2 - spacing * 6;
          final contentHeight = size.height - verticalPadding * 2 - spacing * 5;

          final cellWidth = contentWidth / 7.0;
          final cellHeight = contentHeight / 6.0;

          final dx = local.dx - horizontalPadding;
          final dy = local.dy - verticalPadding;

          if (dx < 0 || dy < 0) return;

          final col = (dx / (cellWidth + spacing)).floor();
          final row = (dy / (cellHeight + spacing)).floor();

          if (col < 0 || col >= 7 || row < 0 || row >= 6) return;

          final index = row * 7 + col;
          if (index >= 0 && index < model.days.length) {
            onDayTap?.call(model.days[index]);
          }
        },
        child: CustomPaint(
          size: Size.infinite,
          painter: _MonthPainter(model: model, showHolidays: showHolidays),
        ),
      );
    });
  }
}

class _MonthPainter extends CustomPainter {
  final MonthModel model;
  final bool showHolidays;

  _MonthPainter({required this.model, this.showHolidays = true});

  static const double _horizontalPadding = 12.0;
  static const double _verticalPadding = 12.0;
  static const double _spacing = 8.0;

  final Paint _bgPaint = Paint();
  final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  // Cache for computed TextPainters to avoid repeated layout work per frame.
  // Keyed by label + rounded maxWidth + color value so we reuse layouts when
  // rendering many cells of the same size.
  final Map<String, TextPainter> _markerPainterCache = {};
  String? _cacheModelKey;

  TextPainter _getFittedMarkerPainter(
      String text, double maxWidth, TextStyle baseStyle, Color color) {
    final roundedW = maxWidth.round();
    final key = '${text}_${roundedW}_${color.value}_${baseStyle.fontSize}';
    final cached = _markerPainterCache[key];
    if (cached != null) return cached;

    // Try stepping down from base font size to a sensible minimum.
    double startSize = (baseStyle.fontSize ?? 11.0);
    const double minSize = 8.0;
    TextPainter tp;

    for (double fs = startSize; fs >= minSize; fs -= 0.5) {
      final ts = baseStyle.copyWith(fontSize: fs, color: color);
      tp = TextPainter(
        text: TextSpan(text: text.toUpperCase(), style: ts),
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(minWidth: 0, maxWidth: maxWidth);

      if (tp.width <= maxWidth || fs == minSize) {
        _markerPainterCache[key] = tp;
        return tp;
      }
    }

    // Fallback (shouldn't happen due to loop above)
    tp = TextPainter(
      text: TextSpan(
          text: text.toUpperCase(),
          style: baseStyle.copyWith(fontSize: minSize, color: color)),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(minWidth: 0, maxWidth: maxWidth);

    _markerPainterCache[key] = tp;
    return tp;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final contentWidth = size.width - _horizontalPadding * 2 - _spacing * 6;
    final contentHeight = size.height - _verticalPadding * 2 - _spacing * 5;

    final cellWidth = contentWidth / 7.0;
    final cellHeight = contentHeight / 6.0;

    final dayNumberStyle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );

    final holidayStyle = const TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.bold,
    );

    final markerTextStyle = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );

    final plusTextStyle = const TextStyle(
      fontSize: 10,
      color: Colors.grey,
    );

    final formatter = DateFormat('yyyy-MM-dd');

    for (var i = 0; i < model.days.length; i++) {
      final row = i ~/ 7;
      final col = i % 7;

      final x = _horizontalPadding + col * (cellWidth + _spacing);
      final y = _verticalPadding + row * (cellHeight + _spacing);

      final rect = Rect.fromLTWH(x, y, cellWidth, cellHeight);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

      final day = model.days[i];
      final key = formatter.format(day);

      final isToday = day.day == DateTime.now().day &&
          day.month == DateTime.now().month &&
          day.year == DateTime.now().year;
      final isCurrentMonth = day.month == model.month;

      // Background
      if (isToday) {
        _bgPaint.color = const Color.fromRGBO(0, 102, 204, 0.1);
      } else {
        _bgPaint.color = isCurrentMonth ? Colors.white : Colors.grey[100]!;
      }
      canvas.drawRRect(rrect, _bgPaint);

      // Border
      final holiday = model.holidaysByDate[key]?.first;
      if (isToday) {
        _borderPaint.color = const Color(0xFF0066CC);
      } else if (holiday != null && showHolidays) {
        _borderPaint.color = holiday.color.withAlpha((0.3 * 255).round());
      } else {
        _borderPaint.color =
            isCurrentMonth ? Colors.grey.shade200 : Colors.grey.shade100;
      }
      canvas.drawRRect(rrect, _borderPaint);

      // Day number (draw at top-right)
      final dayPainter = TextPainter(
        text: TextSpan(
            text: day.day.toString(),
            style: dayNumberStyle.copyWith(
                color: isCurrentMonth
                    ? (isToday
                        ? const Color(0xFF0066CC)
                        : (holiday != null && showHolidays
                            ? holiday.color
                            : (day.weekday == 7 ? Colors.red : Colors.black87)))
                    : Colors.grey[400])),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: cellWidth - 8);

      final dx = x + cellWidth - 8 - dayPainter.width;
      final dy = y + 8;
      dayPainter.paint(canvas, Offset(dx, dy));

      // Holiday (icon + shortName) centered top area
      if (holiday != null && showHolidays) {
        // layout values for icon + text
        const double iconSize = 12.0;
        const double iconSpacing = 4.0;

        // First layout the short name reserving space for the icon
        final maxHolidayWidth = (cellWidth - 6 - (iconSize + iconSpacing))
            .clamp(0.0, cellWidth - 6);
        final hs = TextPainter(
          text: TextSpan(
              text: holiday.shortName,
              style: holidayStyle.copyWith(color: holiday.color)),
          textAlign: TextAlign.center,
          textDirection: ui.TextDirection.ltr,
          maxLines: 2,
        )..layout(minWidth: 0, maxWidth: maxHolidayWidth);

        // Icon painter: render the IconData glyph using its font
        final iconTp = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(holiday.icon.codePoint),
            style: TextStyle(
              fontSize: iconSize,
              fontFamily: holiday.icon.fontFamily,
              color: holiday.color,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();

        // If combined width still exceeds available space, relayout the text tighter
        final combinedWidth = iconTp.width + iconSpacing + hs.width;
        if (combinedWidth > (cellWidth - 6)) {
          final adjustedMax = (cellWidth - 6 - iconTp.width - iconSpacing)
              .clamp(0.0, cellWidth - 6);
          hs.layout(minWidth: 0, maxWidth: adjustedMax);
        }

        final totalWidth = iconTp.width + iconSpacing + hs.width;
        final hx = x + (cellWidth - totalWidth) / 2;

        // Center vertically the icon and text within the holiday area
        final combinedHeight =
            iconTp.height > hs.height ? iconTp.height : hs.height;
        final hyText = y + 26 + (combinedHeight - hs.height) / 2;
        final hyIcon = y + 26 + (combinedHeight - iconTp.height) / 2;

        iconTp.paint(canvas, Offset(hx, hyIcon));
        hs.paint(canvas, Offset(hx + iconTp.width + iconSpacing, hyText));
      }

      // Event markers (paint up to 3 stacked from bottom)
      // Clear and re-use cached TextPainters only when model contents differ.
      if (_cacheModelKey != model.key) {
        _markerPainterCache.clear();
        _cacheModelKey = model.key;
      }

      final markers = model.markersByDate[key] ?? [];
      if (markers.isNotEmpty && !(holiday != null && showHolidays)) {
        final markerHeight = 18.0;
        final markerMargin = 6.0;
        for (var mIndex = 0; mIndex < markers.length && mIndex < 3; mIndex++) {
          final marker = markers[mIndex];

          final mx = x + 6;
          final my = y + cellHeight - 8 - (mIndex + 1) * (markerHeight + 4);
          final mWidth = cellWidth - 12;

          final mr = RRect.fromRectAndRadius(
              Rect.fromLTWH(mx, my, mWidth, markerHeight),
              const Radius.circular(4));

          final p = Paint()
            ..color = marker.color.withAlpha((0.18 * 255).round());
          canvas.drawRRect(mr, p);

          final border = Paint()
            ..style = PaintingStyle.stroke
            ..color = marker.color.withAlpha((0.4 * 255).round())
            ..strokeWidth = 0.6;
          canvas.drawRRect(mr, border);

          // Use cached, size-adaptive TextPainter so labels never truncate.
          final tp = _getFittedMarkerPainter(
              marker.label, mWidth - 12, markerTextStyle, marker.color);

          final tx = mx + 6;
          final ty = my + (markerHeight - tp.height) / 2;
          tp.paint(canvas, Offset(tx, ty));
        }

        if (markers.length > 3) {
          final extra = markers.length - 3;
          final tx = x + 6;
          final ty = y + cellHeight - 8 - (3) * (18.0 + 4) + 2;
          final plus = TextPainter(
            text: TextSpan(text: '+$extra', style: plusTextStyle),
            textDirection: ui.TextDirection.ltr,
          )..layout();
          plus.paint(canvas, Offset(tx, ty));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MonthPainter oldDelegate) {
    // Repaint only when model or holiday visibility changes
    return oldDelegate.model.key != model.key ||
        oldDelegate.showHolidays != showHolidays;
  }
}
