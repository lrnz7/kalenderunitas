class EventModel {
  final String id;
  final String title;
  final String date;
  final String? category;
  final String? description;
  final String? division;

  EventModel({
    required this.id,
    required this.title,
    required this.date,
    this.category,
    this.description,
    this.division,
  });

  // Helper getters dengan ERROR HANDLING
  int get year {
    try {
      return int.parse(_getDatePart(0));
    } catch (e) {
      print('⚠️ Error parsing year from date: $date');
      return DateTime.now().year;
    }
  }

  int get month {
    try {
      return int.parse(_getDatePart(1));
    } catch (e) {
      print('⚠️ Error parsing month from date: $date');
      return DateTime.now().month;
    }
  }

  int get day {
    try {
      return int.parse(_getDatePart(2));
    } catch (e) {
      print('⚠️ Error parsing day from date: $date');
      return DateTime.now().day;
    }
  }

  String _getDatePart(int index) {
    // Support multiple date formats
    String normalizedDate = date;
    
    // Convert from "dd/MM/yyyy" to "yyyy-MM-dd" if needed
    if (date.contains('/')) {
      final parts = date.split('/');
      if (parts.length == 3) {
        normalizedDate = '${parts[2]}-${parts[1]}-${parts[0]}';
      }
    }
    
    final parts = normalizedDate.split('-');
    if (parts.length == 3) {
      return parts[index].trim();
    }
    
    // Fallback
    final now = DateTime.now();
    return index == 0 ? now.year.toString() : 
           index == 1 ? now.month.toString() : 
           now.day.toString();
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      date: _normalizeDateString(json['date']?.toString() ?? ''),
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
      print('⚠️ Error normalizing date: $dateStr');
    }
    
    // Return today if invalid
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'category': category,
      'description': description,
      'division': division,
    };
  }

  // Copy with method for editing
  EventModel copyWith({
    String? id,
    String? title,
    String? date,
    String? category,
    String? description,
    String? division,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
      division: division ?? this.division,
    );
  }

  String get formattedDate {
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (e) {
      // ignore
    }
    return date;
  }

  bool get isPast {
    try {
      final now = DateTime.now();
      final eventDate = DateTime(year, month, day);
      return eventDate.isBefore(DateTime(now.year, now.month, now.day));
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
        other.date == date;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ date.hashCode;
  }
}