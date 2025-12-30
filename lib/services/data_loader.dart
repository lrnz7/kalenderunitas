import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kalender_unitas/models/event_model.dart';
import 'package:kalender_unitas/models/holiday_model.dart';

class DataLoader {
  static const String eventsStorageKey = 'events_storage_v3';
  static const String holidaysStorageKey = 'holidays_storage_v1';

  // ==================== EVENTS ====================

  static Future<List<EventModel>> loadEvents() async {
    debugPrint('📱 Loading events...');

    final List<EventModel> allEvents = [];

    // 1. Coba dari Firestore (online)
    try {
      final firestoreEvents = await _loadEventsFromFirestore();
      if (firestoreEvents.isNotEmpty) {
        allEvents.addAll(firestoreEvents);
        debugPrint('✅ Loaded ${firestoreEvents.length} events from Firestore');

        // Simpan ke local untuk offline
        await _saveEventsToLocal(allEvents);
        return allEvents;
      }
    } catch (e) {
      debugPrint('⚠️ Firestore load failed: $e');
    }

    // 2. Coba dari local storage
    try {
      final localEvents = await _loadEventsFromLocal();
      if (localEvents.isNotEmpty) {
        allEvents.addAll(localEvents);
        debugPrint('📱 Loaded ${localEvents.length} events from local storage');
      }
    } catch (e) {
      debugPrint('⚠️ Local storage load failed: $e');
    }

    // 3. Fallback ke assets
    if (allEvents.isEmpty) {
      try {
        final assetEvents = await _loadEventsFromAssets();
        allEvents.addAll(assetEvents);
        debugPrint('📦 Loaded ${assetEvents.length} events from assets');
        await _saveEventsToLocal(allEvents);
      } catch (e) {
        debugPrint('⚠️ Assets load failed: $e');
      }
    }

    return allEvents;
  }

  // ==================== HOLIDAYS ====================

  static Future<List<HolidayModel>> loadHolidays() async {
    debugPrint('🎉 Loading holidays...');

    final List<HolidayModel> allHolidays = [];

    // 1. Coba dari local storage (cached)
    try {
      final localHolidays = await _loadHolidaysFromLocal();
      if (localHolidays.isNotEmpty) {
        allHolidays.addAll(localHolidays);
        debugPrint(
            '📱 Loaded ${localHolidays.length} holidays from local storage');
        return allHolidays;
      }
    } catch (e) {
      debugPrint('⚠️ Local holidays load failed: $e');
    }

    // 2. Load dari assets (JSON)
    try {
      final assetHolidays = await _loadHolidaysFromAssets();
      allHolidays.addAll(assetHolidays);
      debugPrint('🎊 Loaded ${assetHolidays.length} holidays from assets');
      await _saveHolidaysToLocal(allHolidays);
    } catch (e) {
      debugPrint('⚠️ Assets holidays load failed: $e');
    }

    return allHolidays;
  }

  // ==================== PRIVATE METHODS ====================

  // --- EVENTS ---
  static Future<List<EventModel>> _loadEventsFromFirestore() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot =
          await firestore.collection('events').orderBy('date').limit(200).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return EventModel.fromJson(data).copyWith(id: doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Firestore error: $e');
      return [];
    }
  }

  static Future<List<EventModel>> _loadEventsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(eventsStorageKey);

    if (saved == null || saved.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(saved);
      return decoded
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Local storage parse error: $e');
      return [];
    }
  }

  static Future<List<EventModel>> _loadEventsFromAssets() async {
    try {
      final jsonText = await rootBundle.loadString('assets/events.json');
      final List<dynamic> data = jsonDecode(jsonText);
      return data.map((e) {
        final map = e as Map<String, dynamic>;
        return EventModel.fromJson(map)
            .copyWith(id: 'asset_${map['id'] ?? '1'}');
      }).toList();
    } catch (e) {
      debugPrint('Assets load error: $e');
      return [];
    }
  }

  static Future<void> _saveEventsToLocal(List<EventModel> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(events.map((e) => e.toJson()).toList());
      await prefs.setString(eventsStorageKey, encoded);
    } catch (e) {
      debugPrint('Save to local error: $e');
    }
  }

  // --- HOLIDAYS ---
  static Future<List<HolidayModel>> _loadHolidaysFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(holidaysStorageKey);

    if (saved == null || saved.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(saved);
      return decoded
          .map((e) => HolidayModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Local holidays parse error: $e');
      return [];
    }
  }

  static Future<List<HolidayModel>> _loadHolidaysFromAssets() async {
    try {
      final jsonText = await rootBundle.loadString('assets/holidays.json');
      final Map<String, dynamic> data = jsonDecode(jsonText);

      final List<HolidayModel> holidays = [];

      // Process hari_libur_nasional
      final List<dynamic> nationalHolidays = data['hari_libur_nasional'] ?? [];
      for (var holiday in nationalHolidays) {
        final Map<String, dynamic> holidayMap = holiday as Map<String, dynamic>;
        holidays.add(HolidayModel(
          date: holidayMap['tanggal'] ?? '',
          title: holidayMap['nama'] ?? '',
          description: holidayMap['deskripsi'] ?? '',
          type: 'national',
        ));
      }

      // Process cuti_bersama
      final List<dynamic> jointHolidays = data['cuti_bersama'] ?? [];
      for (var holiday in jointHolidays) {
        final Map<String, dynamic> holidayMap = holiday as Map<String, dynamic>;
        holidays.add(HolidayModel(
          date: holidayMap['tanggal'] ?? '',
          title: holidayMap['nama'] ?? '',
          description: holidayMap['deskripsi'] ?? '',
          type: 'cuti_bersama',
        ));
      }

      return holidays;
    } catch (e) {
      debugPrint('Assets holidays load error: $e');
      return [];
    }
  }

  static Future<void> _saveHolidaysToLocal(List<HolidayModel> holidays) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(holidays.map((e) => e.toJson()).toList());
      await prefs.setString(holidaysStorageKey, encoded);
    } catch (e) {
      debugPrint('Save holidays to local error: $e');
    }
  }

  // ==================== CRUD OPERATIONS ====================

  // Add event
  static Future<String> addEvent(EventModel newEvent,
      {String? createdBy}) async {
    debugPrint('💾 Saving event: ${newEvent.title}');

    String? docId;

    try {
      final firestore = FirebaseFirestore.instance;
      final docRef = await firestore.collection('events').add({
        ...newEvent.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy ?? 'admin',
        'synced': true,
      });
      docId = docRef.id;
      debugPrint('✅ Event synced to Firestore with ID: $docId');
    } catch (e) {
      debugPrint('⚠️ Firestore sync failed: $e');
      docId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    }

    final current = await _loadEventsFromLocal();
    final eventWithId = newEvent.copyWith(id: docId);
    current.add(eventWithId);
    await _saveEventsToLocal(current);

    return docId;
  }

  // Update event
  static Future<void> updateEvent(
      String eventId, EventModel updatedEvent) async {
    debugPrint('🔄 Updating event: ${updatedEvent.title}');

    if (!eventId.startsWith('local_')) {
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('events').doc(eventId).update({
          ...updatedEvent.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('⚠️ Firestore update failed: $e');
      }
    }

    final current = await _loadEventsFromLocal();
    final index = current.indexWhere((event) => event.id == eventId);

    if (index != -1) {
      current[index] = updatedEvent.copyWith(id: eventId);
      await _saveEventsToLocal(current);
    }
  }

  // Delete event
  static Future<void> deleteEvent(String eventId) async {
    debugPrint('🗑️ Deleting event ID: $eventId');

    if (!eventId.startsWith('local_')) {
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('events').doc(eventId).delete();
      } catch (e) {
        debugPrint('⚠️ Firestore delete failed: $e');
      }
    }

    final current = await _loadEventsFromLocal();
    current.removeWhere((event) => event.id == eventId);
    await _saveEventsToLocal(current);
  }

  // Debug method
  static Future<void> debugPrintData() async {
    final events = await loadEvents();
    final holidays = await loadHolidays();

    debugPrint('📊 Total events: ${events.length}');
    debugPrint('🎉 Total holidays: ${holidays.length}');
  }
}
