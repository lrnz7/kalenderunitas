import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/data_loader.dart';
import '../models/event_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<EventModel> _events = [];
  List<EventModel> _filteredEvents = [];
  Set<String> _selectedDivisions = {};
  bool _isLoading = true;
  
  StreamSubscription<QuerySnapshot>? _firestoreSubscription;

  final List<String> _availableDivisions = [
    'BPH',
    'PSDM',
    'Komwira',
    'PPPM',
    'Umum'
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _setupRealTimeListener();
  }

  void _setupRealTimeListener() {
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('events')
        .orderBy('date')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      final events = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EventModel.fromJson(data);
      }).toList();
      
      setState(() {
        _events = events;
        _filteredEvents = events;
        _isLoading = false;
      });
      
      _saveToLocal(events);
    }, onError: (error) {
      print('❌ Real-time listener error: $error');
      _loadEvents();
    });
  }
  
  Future<void> _saveToLocal(List<EventModel> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(events.map((e) => e.toJson()).toList());
      await prefs.setString('events_storage_v1', encoded);
    } catch (e) {
      print('⚠️ Error saving to local: $e');
    }
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    print("🔄 HomePage: Loading events...");
    setState(() {
      _isLoading = true;
    });
    
    final events = await DataLoader.loadEvents();
    print("✅ HomePage: Loaded ${events.length} events");
    
    setState(() {
      _events = events;
      _filteredEvents = events;
      _isLoading = false;
    });
  }

  void _filterEvents() {
    if (_selectedDivisions.isEmpty) {
      setState(() {
        _filteredEvents = _events;
      });
      return;
    }

    setState(() {
      _filteredEvents = _events
          .where((event) => _selectedDivisions.contains(event.division))
          .toList();
    });
  }

  void _showDivisionFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Divisi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0066CC),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._availableDivisions.map((division) {
                    final isSelected = _selectedDivisions.contains(division);
                    return CheckboxListTile(
                      title: Text(division),
                      value: isSelected,
                      onChanged: (value) {
                        setModalState(() {
                          if (value == true) {
                            _selectedDivisions.add(division);
                          } else {
                            _selectedDivisions.remove(division);
                          }
                        });
                      },
                      activeColor: const Color(0xFF0066CC),
                    );
                  }),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedDivisions.clear();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFF0066CC)),
                          ),
                          child: const Text('HAPUS FILTER'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _filterEvents();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0066CC),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('TERAPKAN'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getDivisionColor(String? division) {
    switch (division?.toLowerCase()) {
      case 'bph':
        return const Color(0xFF0066CC);
      case 'psdm':
        return const Color(0xFF00A86B);
      case 'komwira':
        return const Color(0xFFFFD700);
      case 'pppm':
        return const Color(0xFFFF0000);
      case 'umum':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF666666);
    }
  }

  void _showEventDetail(EventModel event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    event.date,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              if (event.division != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getDivisionColor(event.division),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Divisi: ${event.division!}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
              if (event.category != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Kategori: ${event.category!}',
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
              if (event.description != null && event.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Deskripsi:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description!,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('TUTUP'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Event'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0066CC),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() => _isLoading = true);
              await _loadEvents();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data diperbarui'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('events').snapshots(),
            builder: (context, snapshot) {
              final isConnected = snapshot.connectionState == ConnectionState.active;
              return Icon(
                isConnected ? Icons.cloud_done : Icons.cloud_off,
                color: isConnected ? Colors.green : Colors.grey,
                size: 20,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_selectedDivisions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.grey[50],
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt, size: 16, color: Color(0xFF0066CC)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _selectedDivisions.map((division) {
                              return Chip(
                                label: Text(division),
                                backgroundColor: _getDivisionColor(division).withOpacity(0.1),
                                labelStyle: TextStyle(
                                  color: _getDivisionColor(division),
                                  fontSize: 12,
                                ),
                                deleteIcon: const Icon(Icons.close, size: 14),
                                onDeleted: () {
                                  setState(() {
                                    _selectedDivisions.remove(division);
                                    _filterEvents();
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadEvents,
                    child: _filteredEvents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.event_busy,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Tidak ada event',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                if (_selectedDivisions.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedDivisions.clear();
                                        _filterEvents();
                                      });
                                    },
                                    child: const Text('Hapus filter'),
                                  ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _loadEvents,
                                  child: const Text('Refresh Data'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredEvents.length,
                            itemBuilder: (context, index) {
                              final event = _filteredEvents[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  leading: Container(
                                    width: 4,
                                    decoration: BoxDecoration(
                                      color: _getDivisionColor(event.division),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  title: Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            event.date,
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                          if (event.division != null) ...[
                                            const SizedBox(width: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getDivisionColor(event.division)
                                                    .withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                event.division!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: _getDivisionColor(event.division),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (event.category != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Kategori: ${event.category!}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
                                  ),
                                  onTap: () => _showEventDetail(event),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showDivisionFilter,
        backgroundColor: const Color(0xFF0066CC),
        child: const Icon(Icons.filter_list, color: Colors.white),
      ),
    );
  }
}