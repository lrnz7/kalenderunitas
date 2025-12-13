import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class DataLoader {
  static const String storageKey = 'events_storage_v1';
  static bool _firebaseInitialized = false;

  // Load events dengan fallback system
  static Future<List<EventModel>> loadEvents() async {
    print('📱 Loading events...');
    
    final List<EventModel> allEvents = [];
    
    // 1. Coba dari Firestore (online)
    try {
      final firestoreEvents = await _loadFromFirestore();
      if (firestoreEvents.isNotEmpty) {
        allEvents.addAll(firestoreEvents);
        print('✅ Loaded ${firestoreEvents.length} events from Firestore');
        
        // Simpan ke local untuk offline
        await _saveToLocal(allEvents);
        return allEvents;
      }
    } catch (e) {
      print('⚠️ Firestore load failed: $e');
    }
    
    // 2. Coba dari local storage
    try {
      final localEvents = await _loadFromLocal();
      if (localEvents.isNotEmpty) {
        allEvents.addAll(localEvents);
        print('📱 Loaded ${localEvents.length} events from local storage');
      }
    } catch (e) {
      print('⚠️ Local storage load failed: $e');
    }
    
    // 3. Fallback ke assets
    if (allEvents.isEmpty) {
      try {
        final assetEvents = await _loadFromAssets();
        allEvents.addAll(assetEvents);
        print('📦 Loaded ${assetEvents.length} events from assets');
        await _saveToLocal(allEvents);
      } catch (e) {
        print('⚠️ Assets load failed: $e');
      }
    }
    
    return allEvents;
  }

  // Add event
  static Future<void> addEvent(EventModel newEvent, {String? createdBy}) async {
    print('💾 Saving event: ${newEvent.title}');
    
    // 1. Simpan ke local (always work)
    final prefs = await SharedPreferences.getInstance();
    final current = await _loadFromLocal();
    current.add(newEvent);
    await _saveToLocal(current);
    
    // 2. Coba sync ke Firestore (if available)
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('events').add({
        ...newEvent.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy ?? 'admin',
        'synced': true,
      });
      print('✅ Event synced to Firestore');
    } catch (e) {
      print('⚠️ Firestore sync failed: $e');
      print('📱 Event saved locally only');
    }
  }

  // === PRIVATE HELPER METHODS ===

  static Future<List<EventModel>> _loadFromFirestore() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('events')
          .orderBy('date')
          .limit(100)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return EventModel.fromJson(data);
      }).toList();
    } catch (e) {
      print('Firestore error: $e');
      return [];
    }
  }

  static Future<List<EventModel>> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(storageKey);

    if (saved == null || saved.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(saved);
      return decoded.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Local storage parse error: $e');
      return [];
    }
  }

  static Future<List<EventModel>> _loadFromAssets() async {
    try {
      final jsonText = await rootBundle.loadString('assets/events.json');
      final List<dynamic> data = jsonDecode(jsonText);
      return data.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Assets load error: $e');
      return [];
    }
  }

  static Future<void> _saveToLocal(List<EventModel> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(events.map((e) => e.toJson()).toList());
      await prefs.setString(storageKey, encoded);
    } catch (e) {
      print('Save to local error: $e');
    }
  }

  // Debug method
  static Future<void> debugPrintData() async {
    final events = await loadEvents();
    print('📊 Total events: ${events.length}');
    for (var event in events) {
      print('  - ${event.title} (${event.date})');
    }
  }
}