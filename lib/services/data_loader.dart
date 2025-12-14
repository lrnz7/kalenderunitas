import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class DataLoader {
  static const String storageKey = 'events_storage_v3'; // Update key
  static bool _firebaseInitialized = false;

  // Load events dengan cache
  static Future<List<EventModel>> loadEvents() async {
    print('📱 Loading events with cache...');
    
    final List<EventModel> allEvents = [];
    
    // 1. Coba dari Firestore (online) - HANYA ambil data penting
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

  // Optimized: Load events by date range
  static Future<List<EventModel>> loadEventsByYear(int year) async {
    print('📅 Loading events for year $year');
    
    try {
      final firestore = FirebaseFirestore.instance;
      final startDate = '$year-01-01';
      final endDate = '${year+1}-01-01';
      
      final snapshot = await firestore
          .collection('events')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThan: endDate)
          .limit(100)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return EventModel.fromJson(data).copyWith(id: doc.id);
      }).toList();
    } catch (e) {
      print('⚠️ Firestore yearly load failed: $e');
      final allEvents = await loadEvents();
      return allEvents.where((event) => event.year == year).toList();
    }
  }

  // Add event
  static Future<String> addEvent(EventModel newEvent, {String? createdBy}) async {
    print('💾 Saving event: ${newEvent.title}');
    
    String? docId;
    
    // 1. Simpan ke Firestore
    try {
      final firestore = FirebaseFirestore.instance;
      final docRef = await firestore.collection('events').add({
        ...newEvent.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy ?? 'admin',
        'synced': true,
      });
      docId = docRef.id;
      print('✅ Event synced to Firestore with ID: $docId');
    } catch (e) {
      print('⚠️ Firestore sync failed: $e');
      docId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    // 2. Simpan ke local
    final prefs = await SharedPreferences.getInstance();
    final current = await _loadFromLocal();
    final eventWithId = newEvent.copyWith(id: docId!);
    current.add(eventWithId);
    await _saveToLocal(current);
    
    return docId;
  }

  // Update event
  static Future<void> updateEvent(String eventId, EventModel updatedEvent) async {
    print('🔄 Updating event: ${updatedEvent.title}');
    
    if (!eventId.startsWith('local_')) {
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('events').doc(eventId).update({
          ...updatedEvent.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('⚠️ Firestore update failed: $e');
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    final current = await _loadFromLocal();
    final index = current.indexWhere((event) => event.id == eventId);
    
    if (index != -1) {
      current[index] = updatedEvent.copyWith(id: eventId);
      await _saveToLocal(current);
    }
  }

  // Delete event
  static Future<void> deleteEvent(String eventId) async {
    print('🗑️ Deleting event ID: $eventId');
    
    if (!eventId.startsWith('local_')) {
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('events').doc(eventId).delete();
      } catch (e) {
        print('⚠️ Firestore delete failed: $e');
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    final current = await _loadFromLocal();
    current.removeWhere((event) => event.id == eventId);
    await _saveToLocal(current);
  }

  // === PRIVATE METHODS ===

  static Future<List<EventModel>> _loadFromFirestore() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('events')
          .orderBy('date')
          .limit(200) // Limit untuk performance
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return EventModel.fromJson(data).copyWith(id: doc.id);
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
      return data.map((e) {
        final map = e as Map<String, dynamic>;
        return EventModel.fromJson(map).copyWith(id: 'asset_${map['id'] ?? '1'}');
      }).toList();
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
}