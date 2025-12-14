import 'package:flutter/material.dart';

class HolidayModel {
  final String date;
  final String title;
  final String description;
  final String type; // 'national' atau 'cuti_bersama'
  
  HolidayModel({
    required this.date,
    required this.title,
    required this.description,
    required this.type,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      date: json['date'] ?? json['tanggal'] ?? '',
      title: json['title'] ?? json['nama'] ?? '',
      description: json['description'] ?? json['deskripsi'] ?? '',
      type: json['type'] ?? 'national', // default national
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'title': title,
      'description': description,
      'type': type,
    };
  }

  // SHORT NAME untuk tampilan di kalender
  String get shortName {
    final lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('tahun baru') && lowerTitle.contains('masehi')) return 'Tahun Baru';
    if (lowerTitle.contains('isra mikraj')) return 'Isra Miraj';
    if (lowerTitle.contains('imlek')) return 'Imlek';
    if (lowerTitle.contains('nyepi')) return 'Nyepi';
    if (lowerTitle.contains('idul fitri') || lowerTitle.contains('lebaran')) return 'Idul Fitri';
    if (lowerTitle.contains('wafat yesus') || lowerTitle.contains('good friday')) return 'Wafat Yesus';
    if (lowerTitle.contains('paskah') || lowerTitle.contains('kebangkitan')) return 'Paskah';
    if (lowerTitle.contains('hari buruh')) return 'Hari Buruh';
    if (lowerTitle.contains('kenaikan yesus')) return 'Kenaikan Yesus';
    if (lowerTitle.contains('idul adha') || lowerTitle.contains('qurban')) return 'Idul Adha';
    if (lowerTitle.contains('waisak')) return 'Waisak';
    if (lowerTitle.contains('pancasila')) return 'Pancasila';
    if (lowerTitle.contains('muharam') || lowerTitle.contains('tahun baru islam')) return 'Tahun Baru Islam';
    if (lowerTitle.contains('kemerdekaan') || lowerTitle.contains('proklamasi')) return 'HUT RI';
    if (lowerTitle.contains('maulid nabi')) return 'Maulid Nabi';
    if (lowerTitle.contains('natal')) return 'Natal';
    if (lowerTitle.contains('cuti bersama')) return 'Cuti';
    
    // Default: ambil 2 kata pertama
    final words = title.split(' ');
    if (words.length >= 2) {
      return '${words[0]} ${words[1]}';
    }
    return title.length > 8 ? '${title.substring(0, 8)}..' : title;
  }

  // Warna berdasarkan jenis libur
  Color get color {
    final lowerTitle = title.toLowerCase();
    
    // Warna khusus berdasarkan event
    if (lowerTitle.contains('natal')) return const Color(0xFFD32F2F); // Merah Natal
    if (lowerTitle.contains('idul fitri') || lowerTitle.contains('lebaran')) return const Color(0xFF4CAF50); // Hijau Lebaran
    if (lowerTitle.contains('idul adha')) return const Color(0xFF8BC34A); // Hijau muda
    if (lowerTitle.contains('kemerdekaan') || lowerTitle.contains('proklamasi')) return const Color(0xFFF44336); // Merah putih
    if (lowerTitle.contains('nyepi') || lowerTitle.contains('waisak')) return const Color(0xFF9C27B0); // Ungu
    if (lowerTitle.contains('imlek')) return const Color(0xFFFF9800); // Oranye
    if (lowerTitle.contains('paskah')) return const Color(0xFF2196F3); // Biru Paskah
    if (lowerTitle.contains('tahun baru islam') || lowerTitle.contains('muharam')) return const Color(0xFF009688); // Teal
    if (lowerTitle.contains('isra mikraj') || lowerTitle.contains('maulid')) return const Color(0xFF795548); // Brown
    
    switch (type) {
      case 'national':
        return const Color(0xFFF44336); // Merah untuk libur nasional
      case 'cuti_bersama':
        return const Color(0xFFFF9800); // Oranye untuk cuti bersama
      default:
        return Colors.red;
    }
  }

  // Icon berdasarkan jenis libur
  IconData get icon {
    final lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('natal')) return Icons.star;
    if (lowerTitle.contains('idul fitri') || lowerTitle.contains('lebaran')) return Icons.mosque;
    if (lowerTitle.contains('idul adha')) return Icons.grass;
    if (lowerTitle.contains('kemerdekaan') || lowerTitle.contains('proklamasi')) return Icons.flag;
    if (lowerTitle.contains('nyepi')) return Icons.nights_stay;
    if (lowerTitle.contains('waisak')) return Icons.spa;
    if (lowerTitle.contains('imlek')) return Icons.festival;
    if (lowerTitle.contains('paskah')) return Icons.cruelty_free;
    if (lowerTitle.contains('tahun baru')) return Icons.celebration;
    if (lowerTitle.contains('hari buruh')) return Icons.work;
    if (lowerTitle.contains('pancasila')) return Icons.account_balance;
    
    switch (type) {
      case 'national':
        return Icons.flag;
      case 'cuti_bersama':
        return Icons.beach_access;
      default:
        return Icons.event;
    }
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HolidayModel &&
        other.date == date &&
        other.title == title;
  }

  @override
  int get hashCode => date.hashCode ^ title.hashCode;
}