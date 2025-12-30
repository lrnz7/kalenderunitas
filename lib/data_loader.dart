// lib/data_loader.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kalender_unitas/models/event_model.dart';

class DataLoader {
  static const String storageKey = 'events_storage_v1';

  // Load events: cek SharedPreferences dulu, kalau kosong fallback ke assets/events.json
  static Future<List<EventModel>> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(storageKey);

    if (saved != null && saved.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(saved);
        return decoded
            .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // kalau parsing gagal, fallback ke assets
      }
    }

    // fallback: load default events from assets
    final jsonText = await rootBundle.loadString('assets/events.json');
    final List<dynamic> data = jsonDecode(jsonText);
    final events = data
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // simpan ke prefs sekali supaya selanjutnya dibaca dari prefs
    await prefs.setString(
        storageKey, jsonEncode(events.map((e) => e.toJson()).toList()));

    return events;
  }

  // Add one event and persist
  static Future<void> addEvent(EventModel newEvent) async {
    final prefs = await SharedPreferences.getInstance();

    // load current (from prefs if exist, else from assets)
    final current = await loadEvents();

    // append
    current.add(newEvent);

    // encode and save
    final encoded = jsonEncode(current.map((e) => e.toJson()).toList());
    await prefs.setString(storageKey, encoded);
  }

  // Overwrite all events (helper)
  static Future<void> saveAllEvents(List<EventModel> events) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(events.map((e) => e.toJson()).toList());
    await prefs.setString(storageKey, encoded);
  }
}
