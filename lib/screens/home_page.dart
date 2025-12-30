import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/data_loader.dart';
import '../models/event_model.dart';
import 'edit_event_page.dart';
import '../shared/utils/helpers.dart';

class HomePage extends StatefulWidget {
  final bool isAdmin;

  const HomePage({super.key, required this.isAdmin});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<EventModel> _allEvents = [];
  List<EventModel> _events = [];
  List<EventModel> _filteredEvents = [];
  final Set<String> _selectedDivisions = {};
  final Set<String> _selectedCategories = {};
  bool _isLoading = true;
  bool _showPastEvents = false;

  late final ScrollController _scrollController;

  StreamSubscription<QuerySnapshot>? _firestoreSubscription;

  final List<String> _availableDivisions = [
    'BPH',
    'PSDM',
    'Komwira',
    'PPPM',
    'Umum',
    'Unitas SI',
  ];

  final List<String> _availableCategories = [
    'Akademik',
    'Kampus',
    'Event Umum',
    'Organisasi',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadSettings();
  }

  void _setupRealTimeListener() {
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('events')
        .orderBy('date')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      debugPrint('📱 Real-time update: ${snapshot.docs.length} events');

      final events = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EventModel.fromJson(data).copyWith(id: doc.id);
      }).toList();

      setState(() {
        _allEvents = events;
        final visibleEvents =
            _showPastEvents ? events : events.where((e) => !e.isPast).toList();
        _events = visibleEvents;
        _isLoading = false;
      });

      _filterEvents();

      _saveToLocal(events);
    }, onError: (error) {
      debugPrint('❌ Real-time listener error: $error');
      _loadEvents();
    });
  }

  Future<void> _saveToLocal(List<EventModel> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(events.map((e) => e.toJson()).toList());
      await prefs.setString('events_storage_v2', encoded);
      debugPrint('💾 Saved ${events.length} events to local storage');
    } catch (e) {
      debugPrint('⚠️ Error saving to local: $e');
    }
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    debugPrint("🔄 HomePage: Loading events...");
    setState(() {
      _isLoading = true;
    });

    try {
      final events = await DataLoader.loadEvents();
      debugPrint("✅ HomePage: Loaded ${events.length} events");

      setState(() {
        _allEvents = events;
        _events =
            _showPastEvents ? events : events.where((e) => !e.isPast).toList();
        _isLoading = false;
      });
      _filterEvents();
    } catch (e) {
      debugPrint('❌ Error loading events: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load persisted settings (e.g., show past events) and then load events & listeners.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final show = prefs.getBool('show_past_events') ?? false;
    setState(() {
      _showPastEvents = show;
    });
    await _loadEvents();
    _setupRealTimeListener();
  }

  Future<void> _saveShowPastSetting(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_past_events', value);
    } catch (e) {
      debugPrint('⚠️ Error saving show_past_events pref: $e');
    }
  }

  void _filterEvents() {
    setState(() {
      _filteredEvents = _events.where((event) {
        // If no filters are active, include all events
        if (_selectedDivisions.isEmpty && _selectedCategories.isEmpty) {
          return true;
        }

        final evDivision = (event.division ?? '').toLowerCase();
        final evCategory = (event.category ?? '').toLowerCase();

        final selectedDivisionsLower =
            _selectedDivisions.map((s) => s.toLowerCase()).toSet();
        final selectedCategoriesLower =
            _selectedCategories.map((s) => s.toLowerCase()).toSet();

        // If both filters are present, event must match both
        if (selectedDivisionsLower.isNotEmpty &&
            selectedCategoriesLower.isNotEmpty) {
          final matchesDivision = selectedDivisionsLower.contains(evDivision);
          final matchesCategory = evCategory.isNotEmpty &&
              selectedCategoriesLower.contains(evCategory);
          return matchesDivision && matchesCategory;
        }

        // If only divisions filter is active
        if (selectedDivisionsLower.isNotEmpty) {
          return selectedDivisionsLower.contains(evDivision);
        }

        // If only categories filter is active
        if (selectedCategoriesLower.isNotEmpty) {
          return evCategory.isNotEmpty &&
              selectedCategoriesLower.contains(evCategory);
        }

        return true;
      }).toList();
    });
  }

  // Old single-dimension division filter (kept for backwards-compatibility)
  // ignore: unused_element
  void _showDivisionFilter() {
    _showFilters();
  }

  /// Combined filter modal for categories and divisions
  void _showFilters() {
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
                        'Filter Event',
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
                  const SizedBox(height: 12),

                  // Categories
                  const Text(
                    'Kategori',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ..._availableCategories.map((cat) {
                    final isSelected = _selectedCategories.contains(cat);
                    return CheckboxListTile(
                      title: Text(CategoryUtils.displayName(cat)),
                      value: isSelected,
                      onChanged: (value) {
                        setModalState(() {
                          if (value == true) {
                            _selectedCategories.add(cat);
                          } else {
                            _selectedCategories.remove(cat);
                          }
                        });
                      },
                      activeColor: const Color(0xFF0066CC),
                    );
                  }),

                  const SizedBox(height: 12),

                  // Divisions
                  const Text(
                    'Divisi',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ..._availableDivisions.map((division) {
                    final isSelected = _selectedDivisions.contains(division);
                    return CheckboxListTile(
                      title: Text(DivisionUtils.displayName(division)),
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

                  SwitchListTile(
                    title: const Text('Show Past Events'),
                    subtitle: const Text('Tampilkan event yang sudah lewat'),
                    value: _showPastEvents,
                    onChanged: (value) {
                      setModalState(() {});
                      setState(() {
                        _showPastEvents = value;
                        _events = _showPastEvents
                            ? _allEvents
                            : _allEvents.where((e) => !e.isPast).toList();
                        _filterEvents();
                      });
                      _saveShowPastSetting(value);
                    },
                    activeColor: const Color(0xFF0066CC),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedDivisions.clear();
                              _selectedCategories.clear();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFF0066CC)),
                            foregroundColor: const Color(0xFF0066CC),
                          ),
                          child: const Text(
                            'HAPUS FILTER',
                            style: TextStyle(color: Color(0xFF0066CC)),
                          ),
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
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'TERAPKAN',
                            style: TextStyle(color: Colors.white),
                          ),
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
    return DivisionUtils.colorFor(division);
  }

  void _showEventDetail(EventModel event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          event.title,
          style: const TextStyle(color: Color(0xFF0066CC)),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    event.formattedDate,
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
                      'Divisi: ${DivisionUtils.displayName(event.division)}',
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
              if (event.description != null &&
                  event.description!.isNotEmpty) ...[
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
              const SizedBox(height: 16),
              Text(
                'ID: ${event.id.substring(0, 8)}...',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('TUTUP'),
          ),
          if (widget.isAdmin) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _editEvent(event);
              },
              child: const Text(
                'EDIT',
                style: TextStyle(color: Color(0xFF0066CC)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteEvent(event);
              },
              child: const Text(
                'HAPUS',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _editEvent(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEventPage(
          event: event,
          onSave: (updatedEvent) async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              await DataLoader.updateEvent(event.id, updatedEvent);
              // Update local list to preserve scroll & filters without reloading
              final idx = _events.indexWhere((e) => e.id == event.id);
              if (idx != -1) {
                setState(() {
                  _events[idx] = updatedEvent.copyWith(id: event.id);
                });
                _filterEvents();
              }
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Event berhasil diperbarui!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            } catch (e) {
              debugPrint('❌ Error updating event: $e');
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _deleteEvent(EventModel event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Hapus Event',
          style: TextStyle(color: Colors.red),
        ),
        content: Text('Yakin ingin menghapus event "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await DataLoader.deleteEvent(event.id);
                await _loadEvents();
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Event berhasil dihapus!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                debugPrint('❌ Error deleting event: $e');
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('HAPUS'),
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
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilters,
            tooltip: 'Filter Event',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              setState(() => _isLoading = true);
              final messenger = ScaffoldMessenger.of(context);
              await _loadEvents();
              if (!mounted) return;
              messenger.showSnackBar(
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
              final isConnected =
                  snapshot.connectionState == ConnectionState.active;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: isConnected ? Colors.green : Colors.grey,
                  size: 20,
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF0066CC),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Memuat event...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (_selectedDivisions.isNotEmpty ||
                    _selectedCategories.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.grey[50],
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt,
                            size: 16, color: Color(0xFF0066CC)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              // Category chips first
                              ..._selectedCategories.map((category) {
                                final color = CategoryUtils.colorFor(category);
                                return Chip(
                                  label:
                                      Text(CategoryUtils.displayName(category)),
                                  backgroundColor:
                                      color.withAlpha((0.1 * 255).round()),
                                  labelStyle: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                  ),
                                  deleteIcon: const Icon(Icons.close, size: 14),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedCategories.remove(category);
                                      _filterEvents();
                                    });
                                  },
                                );
                              }),

                              // Division chips next
                              ..._selectedDivisions.map((division) {
                                return Chip(
                                  label:
                                      Text(DivisionUtils.displayName(division)),
                                  backgroundColor: _getDivisionColor(division)
                                      .withAlpha((0.1 * 255).round()),
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadEvents,
                    color: const Color(0xFF0066CC),
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
                                if (_selectedDivisions.isNotEmpty ||
                                    _selectedCategories.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedDivisions.clear();
                                        _selectedCategories.clear();
                                        _filterEvents();
                                      });
                                    },
                                    child: const Text(
                                      'Hapus filter',
                                      style:
                                          TextStyle(color: Color(0xFF0066CC)),
                                    ),
                                  ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _loadEvents,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0066CC),
                                  ),
                                  child: const Text('Refresh Data'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            key: const PageStorageKey('events_list'),
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredEvents.length,
                            itemBuilder: (context, index) {
                              final event = _filteredEvents[index];
                              return Dismissible(
                                key: Key(event.id),
                                direction: widget.isAdmin
                                    ? DismissDirection.endToStart
                                    : DismissDirection.none,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                confirmDismiss: widget.isAdmin
                                    ? (direction) async {
                                        if (direction ==
                                            DismissDirection.endToStart) {
                                          return await showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Hapus Event'),
                                              content: Text(
                                                  'Yakin ingin menghapus "${event.title}"?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('BATAL'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                  ),
                                                  child: const Text('HAPUS'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        return false;
                                      }
                                    : null,
                                onDismissed: widget.isAdmin
                                    ? (direction) async {
                                        try {
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          await DataLoader.deleteEvent(
                                              event.id);
                                          await _loadEvents();
                                          if (!mounted) return;
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Event berhasil dihapus!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } catch (e) {
                                          debugPrint(
                                              '❌ Error deleting via swipe: $e');
                                        }
                                      }
                                    : null,
                                child: Card(
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
                                        color:
                                            _getDivisionColor(event.division),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                              event.formattedDate,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                            if (event.division != null) ...[
                                              const SizedBox(width: 12),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getDivisionColor(
                                                          event.division)
                                                      .withAlpha(
                                                          (0.1 * 255).round()),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  DivisionUtils.displayName(
                                                      event.division),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: _getDivisionColor(
                                                        event.division),
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
                                    trailing: widget.isAdmin
                                        ? PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert,
                                                color: Colors.grey),
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _editEvent(event);
                                              } else if (value == 'delete') {
                                                _deleteEvent(event);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit,
                                                        size: 20,
                                                        color:
                                                            Color(0xFF0066CC)),
                                                    SizedBox(width: 8),
                                                    Text('Edit',
                                                        style: TextStyle(
                                                            color: Color(
                                                                0xFF0066CC))),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete,
                                                        color: Colors.red,
                                                        size: 20),
                                                    SizedBox(width: 8),
                                                    Text('Hapus',
                                                        style: TextStyle(
                                                            color: Colors.red)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          )
                                        : const Icon(
                                            Icons.chevron_right,
                                            color: Colors.grey,
                                          ),
                                    onTap: () => _showEventDetail(event),
                                    onLongPress: widget.isAdmin
                                        ? () {
                                            showModalBottomSheet(
                                              context: context,
                                              shape:
                                                  const RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                  top: Radius.circular(20),
                                                ),
                                              ),
                                              builder: (context) => Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    width: 40,
                                                    height: 4,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[300],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              2),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  ListTile(
                                                    leading: const Icon(
                                                        Icons.edit,
                                                        color:
                                                            Color(0xFF0066CC)),
                                                    title: const Text(
                                                        'Edit Event',
                                                        style: TextStyle(
                                                            color: Color(
                                                                0xFF0066CC))),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      _editEvent(event);
                                                    },
                                                  ),
                                                  ListTile(
                                                    leading: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red),
                                                    title: const Text(
                                                        'Hapus Event',
                                                        style: TextStyle(
                                                            color: Colors.red)),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      _deleteEvent(event);
                                                    },
                                                  ),
                                                  const SizedBox(height: 16),
                                                ],
                                              ),
                                            );
                                          }
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/admin');
              },
              backgroundColor: const Color(0xFF0066CC),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
