import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/holiday_model.dart';
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
  final Map<String, List<HolidayModel>> _holidaysByDate = {};
  
  StreamSubscription<QuerySnapshot>? _calendarSubscription;
  bool _isLoading = true;
  bool _showHolidays = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupCalendarListener();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    
    final events = await DataLoader.loadEvents();
    final holidays = await DataLoader.loadHolidays();
    
    setState(() {
      _groupEventsByDate(events);
      _groupHolidaysByDate(holidays);
      _isLoading = false;
    });
  }

  void _groupHolidaysByDate(List<HolidayModel> holidays) {
    _holidaysByDate.clear();
    for (var holiday in holidays) {
      final dateKey = _normalizeDate(holiday.date);
      _holidaysByDate.putIfAbsent(dateKey, () => []).add(holiday);
    }
    print('🎉 Loaded ${_holidaysByDate.length} dates with holidays');
  }

  void _setupCalendarListener() {
    _calendarSubscription = FirebaseFirestore.instance
        .collection('events')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      
      final events = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EventModel.fromJson(data).copyWith(id: doc.id);
      }).toList();
      
      setState(() {
        _groupEventsByDate(events);
      });
      
    }, onError: (error) {
      print('❌ Calendar listener error: $error');
      _loadData();
    });
  }

  @override
  void dispose() {
    _calendarSubscription?.cancel();
    super.dispose();
  }

  void _groupEventsByDate(List<EventModel> events) {
    _eventsByDate.clear();
    for (var event in events) {
      final dateKey = _normalizeDate(event.date);
      _eventsByDate.putIfAbsent(dateKey, () => []).add(event);
    }
  }

  String _normalizeDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[0].padLeft(4, '0')}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
      }
      
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
    
    const totalDays = 42;
    
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

  List<HolidayModel> _getHolidaysForDay(DateTime day) {
    if (!_showHolidays) return [];
    final key = DateFormat('yyyy-MM-dd').format(day);
    return _holidaysByDate[key] ?? [];
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

  Widget _buildDayCell(DateTime day, DateTime currentMonth) {
    final isCurrentMonth = _isCurrentMonth(day);
    final isToday = _isToday(day);
    final dayEvents = _getEventsForDay(day);
    final dayHolidays = _getHolidaysForDay(day);
    final hasEvents = dayEvents.isNotEmpty;
    final hasHoliday = dayHolidays.isNotEmpty;
    
    final HolidayModel? holiday = hasHoliday ? dayHolidays.first : null;

    return GestureDetector(
      onTap: () => _showDayEvents(day),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isToday
              ? const Color(0xFF0066CC).withOpacity(0.1)
              : (isCurrentMonth ? Colors.white : Colors.grey[100]!),
          border: Border.all(
            color: isToday 
                ? const Color(0xFF0066CC) 
                : (hasHoliday && _showHolidays 
                    ? holiday!.color.withOpacity(0.3) 
                    : (isCurrentMonth ? Colors.grey.shade200 : Colors.grey.shade100)),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            // Day Number (top right)
            Positioned(
              top: 4,
              right: 4,
              child: Text(
                day.day.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCurrentMonth
                      ? (isToday
                          ? const Color(0xFF0066CC)
                          : (hasHoliday && _showHolidays
                              ? holiday!.color
                              : (day.weekday == 7 ? Colors.red : Colors.black87)))
                      : Colors.grey[400],
                ),
              ),
            ),
            
            // HOLIDAY DISPLAY - CENTER (NEW!)
            if (hasHoliday && _showHolidays)
              Positioned(
                top: 18,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    // Holiday icon
                    Icon(
                      holiday!.icon,
                      size: 16,
                      color: holiday.color,
                    ),
                    const SizedBox(height: 2),
                    // Short holiday name
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        holiday.shortName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: holiday.color,
                          height: 1.0,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ),
            
            // EVENT DISPLAY - BOTTOM
            if (hasEvents && (!hasHoliday || !_showHolidays))
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Container(
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
            ),
            
            // Jika ada BOTH holiday dan event
            if (hasEvents && hasHoliday && _showHolidays)
              Positioned(
                bottom: 2,
                left: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: _getDivisionColor(dayEvents.first.division).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: _getDivisionColor(dayEvents.first.division).withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    _getDivisionAbbreviation(dayEvents.first.division),
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: _getDivisionColor(dayEvents.first.division),
                    ),
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayEvents(DateTime day) {
    final events = _getEventsForDay(day);
    final holidays = _getHolidaysForDay(day);
    
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
              
              // Tampilkan info holiday jika ada
              if (holidays.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (var holiday in holidays)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: holiday.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: holiday.color.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(holiday.icon, color: holiday.color, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                holiday.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: holiday.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                holiday.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                holiday.type == 'national' ? 'Libur Nasional' : 'Cuti Bersama',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: holiday.color,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              
              const SizedBox(height: 16),
              
              if (events.isEmpty && holidays.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Tidak ada event atau hari libur',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else if (events.isNotEmpty)
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
                          onTap: () => _showEventDetail(event),
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
          // Toggle holiday display
          IconButton(
            icon: Icon(
              _showHolidays ? Icons.flag : Icons.flag_outlined,
              color: _showHolidays ? Colors.yellow : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showHolidays = !_showHolidays;
              });
            },
            tooltip: 'Tampilkan hari libur',
          ),
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
                      return _buildDayCell(day, _focused);
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
                        'Legenda:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildLegendItem('BPH', const Color(0xFF0066CC)),
                          _buildLegendItem('PSDM', const Color(0xFF00A86B)),
                          _buildLegendItem('Komwira', const Color(0xFFFFD700)),
                          _buildLegendItem('PPPM', const Color(0xFFFF0000)),
                          _buildLegendItem('Umum', const Color(0xFF9C27B0)),
                          if (_showHolidays) ...[
                            _buildLegendItem('Libur Nasional', Colors.red),
                            _buildLegendItem('Cuti Bersama', Colors.orange),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total: ${_eventsByDate.length} event, ${_holidaysByDate.length} hari libur',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
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
            ),
          ),
        ],
      ),
    );
  }
}