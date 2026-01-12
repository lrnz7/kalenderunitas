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

  // Increase painter's per-row height by this multiplier (20-30% recommended)
  // This affects only visual painting; layout/tap handling remains unchanged.
  static const double _heightMultiplier = 1.25;

  // Event bar indicator constants (fixed sizes and offsets to ensure deterministic painting)
  static const double _barHeight = 3.5; // px
  static const double _barHeightSmall = 2.5; // px when vertical space tight
  static const double _barSpacing = 2.0; // vertical gap between bars
  static const int _maxVisibleBars = 3; // show up to 3 bars
  static const double _barWidthPercent = 0.65; // 65% of cell width
  static const double _barWidthPercentSmall = 0.6; // smaller percent when tight
  static const double _barBottomMargin =
      12.0; // px margin from bottom of cell to bars
  static const double _overflowBoxWidth = 18.0;
  static const double _overflowBoxHeight = 14.0;
  static const double _overflowFontSize = 8.0;

  // Holiday badge constants (top-left small badge)
  static const double _holidayBadgeWidth = 26.0;
  static const double _holidayBadgeHeight = 16.0;
  static const double _holidayBadgeLeft = 6.0;
  static const double _holidayBadgeTop = 6.0;
  static const double _holidayBadgeFontSize = 9.0;

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

      // Holiday visual: center icon + display name, with optional subtle tint.
      if (holiday != null && showHolidays) {
        // Optional subtle full-cell tint using holiday color (alpha <=5%)
        final tintPaint = Paint()..color = holiday.color.withAlpha((0.05 * 255).round());
        canvas.drawRRect(rrect, tintPaint);

        // Reserve space above bars: estimate bars top using worst-case bars group height.
        final double maxBarsGroupHeight = _maxVisibleBars * _barHeight + (_maxVisibleBars - 1) * _barSpacing;
        final double barsTopEstimate = y + cellHeight - _barBottomMargin - maxBarsGroupHeight - 2.0;

        // Icon & label sizes (fixed defaults)
        double iconSize = 14.0; // smaller than day number (16)
        double labelFontSize = 12.0;
        const double gap = 4.0;

        double groupHeight = iconSize + gap + labelFontSize;

        // Ensure group fits between date area and barsTopEstimate. Calculate min allowed top due to date number.
        final double minIconTop = dy + dayPainter.height + 4.0;
        double avail = barsTopEstimate - minIconTop - 4.0;

        if (avail < groupHeight) {
          // Shrink icon and label if absolutely necessary, but keep legible
          final double scale = (avail > 0) ? (avail / groupHeight) : 0.8;
          final double clampedScale = scale.clamp(0.7, 1.0);
          iconSize = (iconSize * clampedScale).clamp(10.0, iconSize);
          labelFontSize = (labelFontSize * clampedScale).clamp(10.0, labelFontSize);
          groupHeight = iconSize + gap + labelFontSize;
        }

        // Compute group top to be slightly above center of the upper area
        final double upperCenter = y + (barsTopEstimate - y) / 2.0 - 6.0;
        double groupTop = upperCenter - groupHeight / 2.0;
        if (groupTop < minIconTop) groupTop = minIconTop;
        if (groupTop + groupHeight > barsTopEstimate) groupTop = barsTopEstimate - groupHeight;

        // Draw centered icon (use holiday.icon glyph)
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

        final iconX = x + (cellWidth - iconTp.width) / 2.0;
        final iconY = groupTop + (iconSize - iconTp.height) / 2.0;
        iconTp.paint(canvas, Offset(iconX, iconY));

        // Holiday display name: Title Case, human-readable, max 12 chars with ellipsis
        String label = holiday.shortName.trim();
        if (label.isEmpty) label = holiday.title.trim();
        // Convert to Title Case
        label = label.split(RegExp(r'\s+')).map((w) => w.isEmpty ? w : (w[0].toUpperCase() + w.substring(1).toLowerCase())).join(' ');

        final labelTp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w600,
              color: holiday.color,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
          maxLines: 1,
          ellipsis: '\u2026',
          textScaleFactor: 1.0,
        )..layout(minWidth: 0, maxWidth: cellWidth * 0.9);

        // Truncate by max chars if needed (ensure ellipsis will be applied by layout)
        if (label.length > 12) {
          label = label.substring(0, 12);
        }

        final labelX = x + (cellWidth - labelTp.width) / 2.0;
        final labelY = groupTop + iconSize + gap + (labelFontSize - labelTp.height) / 2.0;
        labelTp.paint(canvas, Offset(labelX, labelY));
      }

      // Pre-read markers for this cell (used for event bar indicators)
      final markers = model.markersByDate[key] ?? [];

      // Convert markers into unique division colors (preserve order, dedupe by division)
      final seenDivisions = <String>{};
      final uniqueColors = <Color>[];
      for (var m in markers) {
        final divKey = (m.division ?? '');
        if (!seenDivisions.contains(divKey)) {
          seenDivisions.add(divKey);
          uniqueColors.add(m.color);
        }
      }

      if (uniqueColors.isNotEmpty) {
        final int distinct = uniqueColors.length;
        final int visible =
            distinct > _maxVisibleBars ? _maxVisibleBars : distinct;

        double barH = _barHeight;
        double barW = cellWidth * _barWidthPercent;
        double spacing = _barSpacing;

        // If vertical space is tight, shrink bars slightly (do NOT shrink text or holiday icon)
        if (cellHeight < 48.0) {
          barH = _barHeightSmall;
          barW = cellWidth * _barWidthPercentSmall;
          spacing = 1.0;
        }

        final double groupHeight = visible * barH + (visible - 1) * spacing;
        final double startTop = y + cellHeight - _barBottomMargin - groupHeight;
        final double left = x + (cellWidth - barW) / 2.0;

        // Paint up to _maxVisibleBars thin horizontal rounded bars
        for (var bi = 0; bi < visible; bi++) {
          final cy = startTop + bi * (barH + spacing);
          final r = RRect.fromRectAndRadius(
              Rect.fromLTWH(left, cy, barW, barH), Radius.circular(barH / 2.0));
          final paint = Paint()..color = uniqueColors[bi];
          canvas.drawRRect(r, paint);
        }

        // Overflow indicator: small neutral +N box to the right of bars group
        if (distinct > _maxVisibleBars) {
          final overflowCount = distinct - _maxVisibleBars;
          final double overflowLeft = x + (cellWidth + barW) / 2.0 + 6.0;
          final double overflowTop =
              startTop + (groupHeight - _overflowBoxHeight) / 2.0;

          final overflowR = RRect.fromRectAndRadius(
              Rect.fromLTWH(overflowLeft, overflowTop, _overflowBoxWidth,
                  _overflowBoxHeight),
              const Radius.circular(4));
          canvas.drawRRect(overflowR, Paint()..color = Colors.grey[300]!);

          final overflowTp = TextPainter(
            text: TextSpan(
              text: '+$overflowCount',
              style: TextStyle(
                  fontSize: _overflowFontSize, color: Colors.grey[600]),
            ),
            textDirection: ui.TextDirection.ltr,
            maxLines: 1,
            textScaleFactor: 1.0,
          )..layout(minWidth: 0, maxWidth: _overflowBoxWidth - 2);

          final double tx =
              overflowLeft + (_overflowBoxWidth - overflowTp.width) / 2.0;
          final double ty = overflowTop +
              (_overflowBoxHeight - overflowTp.height) / 2.0 -
              1.0;
          overflowTp.paint(canvas, Offset(tx, ty));
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
