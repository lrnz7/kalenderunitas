import 'package:flutter/foundation.dart';

class EventModel {
  final String id;
  final String title;
  final String startDate; // yyyy-MM-dd (always present)
  final String?
      endDate; // nullable; if present and > startDate -> multi-day series
  final String? category;
  final String? description;
  final String? division;

  EventModel({
    required this.id,
    required this.title,
    required this.startDate,
    this.endDate,
    this.category,
    this.description,
    this.division,
  });

  // Convenience helpers
  DateTime get startDateTime {
    final parts = startDate.split('-');
    try {
      return DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (e) {
      return DateTime.now();
    }
  }

  DateTime? get endDateTime {
    if (endDate == null || endDate!.isEmpty) return null;
    final parts = endDate!.split('-');
    try {
      return DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (e) {
      return null;
    }
  }

  bool get isMultiDay {
    final end = endDateTime;
    return end != null && !end.isAtSameMomentAs(startDateTime);
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    // Support older payload that used 'date' as a single-day string
    String start = '';
    String? end;

    if (json.containsKey('startDate')) {
      start = _normalizeDateString((json['startDate'] ?? '').toString());
      end = json.containsKey('endDate')
          ? _normalizeDateString((json['endDate'] ?? '').toString())
          : null;
    } else if (json.containsKey('date')) {
      start = _normalizeDateString((json['date'] ?? '').toString());
      end = null;
    }

    // Fallback to today if parsing failed
    if (start.isEmpty) {
      final now = DateTime.now();
      start =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }

    return EventModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      startDate: start,
      endDate: end,
      category: json['category']?.toString(),
      description: json['description']?.toString(),
      division: json['division']?.toString(),
    );
  }

  static String _normalizeDateString(String dateStr) {
    // Convert to standard format yyyy-MM-dd
    try {
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          return '${parts[2].padLeft(4, '0')}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
        }
      } else if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          return '${parts[0].padLeft(4, '0')}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error normalizing date: $dateStr');
    }

    // Return empty string if invalid (caller will fallback)
    return '';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      // Keep legacy 'date' for backward compatibility (use startDate)
      'date': startDate,
      'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      'category': category,
      'description': description,
      'division': division,
    };
  }

  // Copy with method for editing
  EventModel copyWith({
    String? id,
    String? title,
    String? startDate,
    String? endDate,
    String? category,
    String? description,
    String? division,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      description: description ?? this.description,
      division: division ?? this.division,
    );
  }

  String get formattedDate {
    // Single day: dd/MM/yyyy
    // Multi-day: dd/MM - dd/MM yyyy (if same month/year) or dd/MM/yyyy - dd/MM/yyyy
    try {
      final s = startDate.split('-');
      final start = '${s[2]}/${s[1]}/${s[0]}';
      if (!isMultiDay) return start;
      final e = endDate!.split('-');
      final end = '${e[2]}/${e[1]}/${e[0]}';
      // If same month/year, show compact
      if (s[0] == e[0] && s[1] == e[1]) {
        return '${s[2]}-${e[2]}/${s[1]}/${s[0]}';
      }
      return '$start - $end';
    } catch (e) {
      return startDate;
    }
  }

  bool get isPast {
    try {
      final now = DateTime.now();
      final eventEnd = endDateTime ?? startDateTime;
      return eventEnd.isBefore(DateTime(now.year, now.month, now.day));
    } catch (e) {
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventModel &&
        other.id == id &&
        other.title == title &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        startDate.hashCode ^
        (endDate?.hashCode ?? 0);
  }
}
