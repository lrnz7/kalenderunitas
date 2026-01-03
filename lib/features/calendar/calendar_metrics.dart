import 'package:flutter/material.dart';

/// Immutable metrics computed once per device size/orientation to avoid any
/// layout negotiations during PageView animation or grid swipes.
class CalendarMetrics {
  final double gridHeight;
  final double cellHeight;
  final double cellWidth;
  final double childAspectRatio;
  final double markerFontSize;
  final double eventBarHeight;

  const CalendarMetrics({
    required this.gridHeight,
    required this.cellHeight,
    required this.cellWidth,
    required this.childAspectRatio,
    required this.markerFontSize,
    required this.eventBarHeight,
  });

  /// Create conservative metrics from MediaQuery size. This should be called
  /// once per build and then passed into pages; it avoids LayoutBuilder usage
  /// inside the page which can force synchronous layout during swipes.
  factory CalendarMetrics.fromMediaQuery(MediaQueryData mq) {
    const int rows = 6;
    const int cols = 7;
    const double horizontalPadding = 24.0; // matching CalendarPage paddings
    const double gridSpacing = 4.0;
    const double minCellHeight = 56.0;

    // Reserve vertical space for app chrome, headers and footers. This is a
    // conservative fixed deduction so grid height doesn't change while swiping.
    final reservedVertical = kToolbarHeight + 140.0; // heuristic reserve

    final totalHeight = mq.size.height;
    final totalWidth = mq.size.width;

    final gridHeight = (totalHeight - reservedVertical)
        .clamp(minCellHeight * rows, totalHeight * 0.75);

    final cellHeight = (gridHeight - (gridSpacing * (rows - 1))) / rows;
    final cellWidth =
        (totalWidth - horizontalPadding - (gridSpacing * (cols - 1))) / cols;

    final childAspectRatio = cellWidth / (cellHeight > 0 ? cellHeight : 1.0);

    final markerFontSize = (cellHeight * 0.14).clamp(9.0, 12.0);

    final eventBarHeight = (cellHeight * 0.18).clamp(6.0, 12.0);

    return CalendarMetrics(
      gridHeight: gridHeight,
      cellHeight: cellHeight,
      cellWidth: cellWidth,
      childAspectRatio: childAspectRatio,
      markerFontSize: markerFontSize,
      eventBarHeight: eventBarHeight,
    );
  }
}
