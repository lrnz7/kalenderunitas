class EventModel {
  final String title;
  final String date;
  final String? category;
  final String? description;
  final String? division;

  EventModel({
    required this.title,
    required this.date,
    this.category,
    this.description,
    this.division,
  });

  int get year {
    try {
      return int.parse(date.split('-')[0]);
    } catch (e) {
      return 0;
    }
  }

  int get month {
    try {
      return int.parse(date.split('-')[1]);
    } catch (e) {
      return 0;
    }
  }

  int get day {
    try {
      return int.parse(date.split('-')[2]);
    } catch (e) {
      return 0;
    }
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      category: json['category'],
      description: json['description'],
      division: json['division'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'category': category,
      'description': description,
      'division': division,
    };
  }

  String get formattedDate {
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final month = parts[1];
        final day = parts[2];
        return '$day/$month/$year';
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
        other.title == title &&
        other.date == date &&
        other.category == category &&
        other.description == description &&
        other.division == division;
  }

  @override
  int get hashCode {
    return title.hashCode ^ date.hashCode ^ category.hashCode ^ description.hashCode ^ division.hashCode;
  }
}