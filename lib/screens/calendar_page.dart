import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../services/data_loader.dart';

class CalendarPage extends StatefulWidget {
  final bool isAdmin;
  
  const CalendarPage({super.key, required this.isAdmin});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focused = DateTime.now();
  final Map<String, List<EventModel>> _eventsByDate = {};
  
  StreamSubscription<QuerySnapshot>? _calendarSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _setupCalendarListener();
  }

  void _setupCalendarListener() {
    print('📅 Setting up calendar real-time listener...');
    
    _calendarSubscription = FirebaseFirestore.instance
        .collection('events')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      print('📅 Calendar real-time update: ${snapshot.docs.length} events');
      
      final events = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EventModel.fromJson(data).copyWith(id: doc.id);
      }).toList();
      
      setState(() {
        _groupEventsByDate(events);
        _isLoading = false;
      });
      
    }, onError: (error) {
      print('❌ Calendar listener error: $error');
      _loadEvents();
    });
  }

  @override
  void dispose() {
    _calendarSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final events = await DataLoader.loadEvents();
    setState(() {
      _groupEventsByDate(events);
      _isLoading = false;
    });
  }

  void _groupEventsByDate(List<EventModel> events) {
    _eventsByDate.clear();
    for (var event in events) {
      // PASTIKAN: Format date konsisten (yyyy-MM-dd)
      final dateKey = _normalizeDate(event.date);
      _eventsByDate.putIfAbsent(dateKey, () => []).add(event);
    }
    print('📅 Loaded ${_eventsByDate.length} dates with events');
  }

  String _normalizeDate(String dateStr) {
    try {
      // Format harus: yyyy-MM-dd
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[0].padLeft(4, '0')}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
      }
      
      // Coba format lain: dd/MM/yyyy
      if (dateStr.contains('/')) {
        final parts2 = dateStr.split('/');
        if (parts2.length == 3) {
          return '${parts2[2]}-${parts2[1].padLeft(2, '0')}-${parts2[0].padLeft(2, '0')}';
        }
      }
    } catch (e) {
      print('⚠️ Error normalizing date: $dateStr - $e');
    }
    return dateStr;
  }

  List<DateTime> _daysInMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final startWeekday = firstDay.weekday;
    final daysBefore = startWeekday - 1;
    final startDate = firstDay.subtract(Duration(days: daysBefore));
    
    const totalDays = 42; // 6 weeks
    
    return List.generate(totalDays, (i) => startDate.add(Duration(days: i)));
  }

  bool _isCurrentMonth(DateTime day) {
    return day.month == _focused.month && day.year == _focused.year;
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.day == now.day && day.month == now.month && day.year == now.year;
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    return _eventsByDate[key] ?? [];
  }

  Color _getDivisionColor(String? division) {
    if (division == null) return Colors.grey;
    
    switch (division.toLowerCase()) {
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

  String _getDivisionAbbreviation(String? division) {
    if (division == null) return '';
    switch (division.toLowerCase()) {
      case 'bph':
        return 'BPH';
      case 'psdm':
        return 'PSDM';
      case 'komwira':
        return 'KMW';
      case 'pppm':
        return 'PPPM';
      case 'umum':
        return 'UM';
      default:
        return division.length > 3 ? division.substring(0, 3).toUpperCase() : division.toUpperCase();
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

  void _showDayEvents(DateTime day) {
    final events = _getEventsForDay(day);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(day),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0066CC),
                ),
              ),
              const SizedBox(height: 16),
              if (events.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Tidak ada event',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final divisionColor = _getDivisionColor(event.division);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 8,
                            decoration: BoxDecoration(
                              color: divisionColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          title: Text(
                            event.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (event.division != null)
                                Text('Divisi: ${event.division}'),
                              if (event.category != null)
                                Text('Kategori: ${event.category}'),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(context);
                            _showEventDetail(event);
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthDays = _daysInMonth(_focused);
    final weekDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('MMMM yyyy').format(_focused).toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0066CC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.calendar_today, color: Colors.white),
          onPressed: () {
            setState(() {
              _focused = DateTime.now();
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => setState(() {
              _focused = DateTime(_focused.year, _focused.month - 1, 1);
            }),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () => setState(() {
              _focused = DateTime(_focused.year, _focused.month + 1, 1);
            }),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('events').snapshots(),
            builder: (context, snapshot) {
              final isConnected = snapshot.connectionState == ConnectionState.active;
              return IconButton(
                icon: Icon(
                  isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: isConnected ? Colors.green : Colors.grey,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isConnected 
                          ? '✅ Terhubung ke server real-time' 
                          : '⚠️ Mode offline - menggunakan data lokal',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0066CC),
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: Colors.grey[50],
                  child: Row(
                    children: weekDays.map((day) {
                      return Expanded(
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: day == 'Min' ? Colors.red : Colors.grey[700],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: monthDays.length,
                    itemBuilder: (context, index) {
                      final day = monthDays[index];
                      final isCurrentMonth = _isCurrentMonth(day);
                      final isToday = _isToday(day);
                      final dayEvents = _getEventsForDay(day);
                      final hasEvents = dayEvents.isNotEmpty;

                      return GestureDetector(
                        onTap: () => _showDayEvents(day),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: isToday
                                ? const Color(0xFF0066CC).withOpacity(0.1)
                                : (isCurrentMonth ? Colors.white : Colors.grey[100]),
                            border: Border.all(
                              color: isToday 
                                  ? const Color(0xFF0066CC) 
                                  : (isCurrentMonth ? Colors.grey.shade200 : Colors.grey.shade100),
                              width: 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Text(
                                  day.day.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isCurrentMonth
                                        ? (isToday
                                            ? const Color(0xFF0066CC)
                                            : (day.weekday == 7 ? Colors.red : Colors.black87))
                                        : Colors.grey[400],
                                  ),
                                ),
                              ),
                              
                              if (hasEvents && dayEvents.first.division != null)
                                Positioned(
                                  bottom: 6,
                                  left: 4,
                                  right: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: _getDivisionColor(dayEvents.first.division).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: _getDivisionColor(dayEvents.first.division).withOpacity(0.3),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Text(
                                          _getDivisionAbbreviation(dayEvents.first.division),
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: _getDivisionColor(dayEvents.first.division),
                                          ),
                                        ),
                                      ),
                                      
                                      if (dayEvents.length > 1)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            '+${dayEvents.length - 1} more',
                                            style: const TextStyle(
                                              fontSize: 8,
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: const Border(
                      top: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Divisi:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _buildLegendItem('BPH', const Color(0xFF0066CC)),
                          _buildLegendItem('PSDM', const Color(0xFF00A86B)),
                          _buildLegendItem('Komwira', const Color(0xFFFFD700)),
                          _buildLegendItem('PPPM', const Color(0xFFFF0000)),
                          _buildLegendItem('Umum', const Color(0xFF9C27B0)),
                        ],
                      ),
                    ],
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}