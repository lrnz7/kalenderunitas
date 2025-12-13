import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';

class DataLoader {
  static const String storageKey = 'events_storage_v1';
  static const String googleScriptUrl = "https://script.google.com/macros/s/AKfycbxnLKDPg2s6T2ug0vAKLVsOOqDzl1g3-1KirRKPl7xKSPbkX7K1jbeLOA_VYUvcBKMO/exec";
  static bool useOnline = true;
  
  // Load events: coba online dulu, fallback ke lokal
  static Future<List<EventModel>> loadEvents() async {
    print("📡 Loading events...");
    
    if (useOnline) {
      try {
        print("🔄 Trying online sync...");
        final onlineEvents = await _loadFromGoogleSheets();
        if (onlineEvents.isNotEmpty) {
          print("✅ Online sync successful: ${onlineEvents.length} events");
          await _saveToLocal(onlineEvents);
          return onlineEvents;
        } else {
          print("ℹ️ No events online, checking local...");
        }
      } catch (e) {
        print("❌ Online load failed: $e");
      }
    }
    
    // Fallback ke lokal
    final localEvents = await _loadFromLocal();
    print("📱 Using local data: ${localEvents.length} events");
    return localEvents;
  }
  
  static Future<List<EventModel>> _loadFromGoogleSheets() async {
    try {
      print("🌐 Fetching from Google Sheets...");
      final response = await http.get(
        Uri.parse(googleScriptUrl),
      ).timeout(const Duration(seconds: 10));
      
      print("📡 Response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        print("📡 Response body: ${response.body}");
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final List<dynamic> eventsData = data['data'];
          print("📊 Events data count: ${eventsData.length}");
          
          final events = eventsData.map((e) {
            print("📝 Processing event: ${e['title']}");
            return EventModel.fromJson(e);
          }).toList();
          
          return events;
        } else {
          print("❌ API error: ${data['error']}");
        }
      } else {
        print("❌ HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Google Sheets error: $e");
    }
    return [];
  }
  
  static Future<List<EventModel>> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(storageKey);
      
      print("📱 Checking local storage...");
      print("📱 Has data: ${saved != null}");
      print("📱 Data length: ${saved?.length ?? 0}");
      
      if (saved != null && saved.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(saved);
        print("📱 Decoded events count: ${decoded.length}");
        
        final events = decoded.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
        return events;
      }
    } catch (e) {
      print("❌ Local load error: $e");
    }
    return [];
  }
  
  static Future<void> _saveToLocal(List<EventModel> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(events.map((e) => e.toJson()).toList());
      await prefs.setString(storageKey, encoded);
      print("💾 Saved ${events.length} events locally");
      print("💾 Data length: ${encoded.length} chars");
    } catch (e) {
      print("❌ Local save error: $e");
    }
  }
  
  // Add event: kirim ke Google Sheets DAN simpan lokal
  static Future<void> addEvent(EventModel newEvent, {String createdBy = "Admin"}) async {
    print("\n" + "="*50);
    print("➕ ADD EVENT STARTED");
    print("="*50);
    print("📝 Title: ${newEvent.title}");
    print("📅 Date: ${newEvent.date}");
    print("🏷️ Category: ${newEvent.category}");
    print("🏢 Division: ${newEvent.division}");
    print("📋 Description: ${newEvent.description}");
    print("👤 Created By: $createdBy");
    
    // Kirim ke Google Sheets
    if (useOnline) {
      try {
        print("\n🔄 Syncing to Google Sheets...");
        print("🌐 URL: $googleScriptUrl");
        
        final Map<String, String> body = {
          'action': 'addEvent',
          'title': newEvent.title,
          'date': newEvent.date,
          'category': newEvent.category ?? '',
          'division': newEvent.division ?? '',
          'description': newEvent.description ?? '',
          'createdBy': createdBy,
        };
        
        print("📦 Request body: $body");
        
        final response = await http.post(
          Uri.parse(googleScriptUrl),
          body: body,
        ).timeout(const Duration(seconds: 15));
        
        print("📡 Response status: ${response.statusCode}");
        print("📡 Response body: ${response.body}");
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          if (responseData['success'] == true) {
            print("✅ Event synced to Google Sheets");
          } else {
            print("❌ API error: ${responseData['error']}");
          }
        } else {
          print("❌ HTTP error: ${response.statusCode}");
        }
      } catch (e) {
        print("❌ Online sync failed: $e");
      }
    }
    
    // Simpan ke lokal
    try {
      print("\n💾 Saving to local storage...");
      final prefs = await SharedPreferences.getInstance();
      final current = await _loadFromLocal();
      
      print("📱 Current local events before: ${current.length}");
      
      // Check if event already exists
      final exists = current.any((e) => 
        e.title == newEvent.title && 
        e.date == newEvent.date
      );
      
      if (exists) {
        print("⚠️ Event already exists locally, skipping...");
      } else {
        current.add(newEvent);
        current.sort((a, b) => a.date.compareTo(b.date));
        
        final encoded = jsonEncode(current.map((e) => e.toJson()).toList());
        await prefs.setString(storageKey, encoded);
        
        print("✅ Event saved locally");
        print("📱 New local events count: ${current.length}");
      }
    } catch (e) {
      print("❌ Local save failed: $e");
    }
    
    print("="*50);
    print("➕ ADD EVENT COMPLETED");
    print("="*50 + "\n");
  }
  
  // Refresh dengan data terbaru dari online
  static Future<void> refreshFromOnline() async {
    if (!useOnline) return;
    
    try {
      print("🔄 Refreshing from online...");
      final onlineEvents = await _loadFromGoogleSheets();
      if (onlineEvents.isNotEmpty) {
        await _saveToLocal(onlineEvents);
        print("✅ Refresh successful");
      } else {
        print("ℹ️ No data from online");
      }
    } catch (e) {
      print("❌ Refresh failed: $e");
    }
  }
  
  // Clear all local data (for debugging)
  static Future<void> clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
    print("🗑️ Local data cleared");
  }
  
  // Get local data count
  static Future<int> getLocalCount() async {
    final events = await _loadFromLocal();
    return events.length;
  }
}