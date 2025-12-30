import 'package:flutter/material.dart';

class RoleColors {
  static const bph = Colors.blue;
  static const psdm = Colors.green;
  static const komwira = Colors.yellow;
  static const p3m = Colors.red;
  static const unitas = Color(0xFF00BCD4);
}

class DivisionUtils {
  /// Returns the display name for a stored division value.
  /// For "Unitas SI" we want to show "Unitas" to users.
  static String displayName(String? division) {
    if (division == null) return '';
    final low = division.toLowerCase();
    if (low == 'unitas si' || low == 'unitas') return 'Unitas';
    return division;
  }

  /// Returns a color associated with a division. Falls back to grey.
  static Color colorFor(String? division) {
    if (division == null) return Colors.grey;
    switch (division.toLowerCase()) {
      case 'bph':
        return const Color(0xFF0066CC);
      case 'psdm':
        return const Color(0xFF00A86B);
      case 'komwira':
        return const Color(0xFFFFD700);
      case 'pppm':
      case 'p3m':
      case 'p3pm':
        return const Color(0xFFFF0000);
      case 'umum':
        return const Color(0xFF9C27B0);
      case 'unitas si':
      case 'unitas':
        return RoleColors.unitas;
      default:
        return const Color(0xFF666666);
    }
  }
}

class CategoryUtils {
  /// Normalize or display-friendly name for categories
  static String displayName(String? category) {
    if (category == null) return '';
    return category;
  }

  /// Color used for category chips/labels
  static Color colorFor(String? category) {
    if (category == null) return Colors.grey;
    switch (category.toLowerCase()) {
      case 'akademik':
        return const Color(0xFF0097A7); // teal
      case 'kampus':
        return const Color(0xFFFF9800); // orange
      case 'event umum':
        return const Color(0xFF607D8B); // blue-grey
      case 'organisasi':
        return const Color(0xFF7B1FA2); // purple
      default:
        return const Color(0xFF666666);
    }
  }
}
