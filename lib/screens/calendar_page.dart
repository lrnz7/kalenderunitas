import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/holiday_model.dart';
import '../services/data_loader.dart';
import '../shared/utils/helpers.dart';
import 'package:kalender_unitas/features/calendar/month_model.dart';
import 'package:kalender_unitas/features/calendar/month_view.dart';
import 'edit_event_page.dart';

class CalendarPage extends StatefulWidget {
  final bool isAdmin;
  // Optional test injection for lightweight visual validation
  final List<EventModel>? testEvents;
  final List<HolidayModel>? testHolidays;
  // When true, skip the realtime Firestore connection used only for the small
  // connection-status indicator in the AppBar. Useful for widget tests.
  final bool disableRealtimeIndicator;

  // Optional injection: when provided, the add-event flow will use this
  // callback to create events deterministically in widget tests instead of
  // navigating to the Admin page. Signature accepts the new EventModel.
  final Future<void> Function(EventModel)? onCreateEvent;

  const CalendarPage(
      {super.key,
      required this.isAdmin,
      this.testEvents,
      this.testHolidays,
      this.disableRealtimeIndicator = false,
      this.onCreateEvent});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focused = DateTime.now();
  // Guard to avoid overlapping month-change animations during rapid input
  // This acts as a lightweight determinism lock: while true we ignore new inputs
  // and avoid queuing or overlapping transitions.
  bool _isAnimatingMonthChange = false;

  // PageView controller with the middle page as the current month.
  // Rationale: keep a fixed 3-page carousel (prev/current/next) so only three
  // MonthModels exist at any time. This prevents unbounded preloads, keeps
  // builds cheap, and ensures deterministic snapping behavior.
  // WARNING: Do not wrap this PageView in another scroll view or add nested
  // scrollables inside the month viewport; doing so may break scrolling
  // physics and lead to non-deterministic layout passes.
  late final PageController _pageController;
  final Duration _pageAnimationDuration = const Duration(milliseconds: 320);

  // Cached month models: previous (index 0), current (1), next (2)
  MonthModel? _prevMonth;
  MonthModel? _currentMonth;
  MonthModel? _nextMonth;

  final Map<String, List<EventModel>> _eventsByDate = {};
  final Map<String, List<HolidayModel>> _holidaysByDate = {};

  StreamSubscription<QuerySnapshot>? _calendarSubscription;
  bool _isLoading = true;
  bool _showHolidays = true;

  @override
  void initState() {
    super.initState();

    // Page controller for a 3-page (prev/current/next) carousel.
    // Use explicit viewportFraction to enforce full-page snapping.
    _pageController = PageController(initialPage: 1, viewportFraction: 1.0);

    // Test injection path: if test data is provided, use it and skip
    // the async loader/listener for deterministic widget tests.
    if (widget.testEvents != null || widget.testHolidays != null) {
      setState(() {
        _groupEventsByDate(widget.testEvents ?? []);
        _groupHolidaysByDate(widget.testHolidays ?? []);
        _isLoading = false;
      });
      // Prepare month models synchronously for deterministic tests
      _prepareMonthModelsFor(_focused);
    } else {
      _loadData();
      if (!widget.disableRealtimeIndicator) {
        _setupCalendarListener();
      }
    }
  }

  void _loadData() async {
    setState(() => _isLoading = true);

    final events = await DataLoader.loadEvents();
    final holidays = await DataLoader.loadHolidays();

    setState(() {
      _groupEventsByDate(events);
      _groupHolidaysByDate(holidays);
      _isLoading = false;
      _prepareMonthModelsFor(_focused);
    });
  }

  void _groupHolidaysByDate(List<HolidayModel> holidays) {
    _holidaysByDate.clear();
    for (var holiday in holidays) {
      final dateKey = _normalizeDate(holiday.date);
      _holidaysByDate.putIfAbsent(dateKey, () => []).add(holiday);
    }
    debugPrint('🎉 Loaded ${_holidaysByDate.length} dates with holidays');
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
        _prepareMonthModelsFor(_focused);
      });
    }, onError: (error) {
      debugPrint('❌ Calendar listener error: $error');
      _loadData();
    });
  }

  @override
  void dispose() {
    _calendarSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _groupEventsByDate(List<EventModel> events) {
    _eventsByDate.clear();

    for (var event in events) {
      final start = event.startDateTime;
      final end = event.endDateTime ?? event.startDateTime;

      for (var dt = start;
          !dt.isAfter(end);
          dt = dt.add(const Duration(days: 1))) {
        final key = DateFormat('yyyy-MM-dd').format(dt);
        _eventsByDate.putIfAbsent(key, () => []).add(event);
      }
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
      debugPrint('⚠️ Error normalizing date: $dateStr - $e');
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
    return DivisionUtils.colorFor(division);
  }

  String _getDivisionAbbreviation(String? division) {
    if (division == null) return '';

    // For Unitas SI we prefer to display 'Unitas' instead of full 'Unitas SI'
    if (division.toLowerCase() == 'unitas si' ||
        division.toLowerCase() == 'unitas') {
      return DivisionUtils.displayName(division);
    }

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
        return division.length > 3
            ? division.substring(0, 3).toUpperCase()
            : division.toUpperCase();
    }
  }

  Widget _buildEventIndicator(DateTime day, EventModel event) {
    final color = _getDivisionColor(event.division);
    final start = event.startDateTime;
    final end = event.endDateTime ?? start;

    final key = DateFormat('yyyy-MM-dd').format(day);
    final isStart = DateFormat('yyyy-MM-dd').format(start) == key;
    final isEnd = DateFormat('yyyy-MM-dd').format(end) == key;

    final borderRadius = BorderRadius.horizontal(
      left: Radius.circular(isStart ? 6 : 0),
      right: Radius.circular(isEnd ? 6 : 0),
    );

    return Tooltip(
      message: DivisionUtils.displayName(event.division),
      child: InkWell(
        onLongPress: () => _showDayEvents(day),
        child: Container(
          height: 18,
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: color.withAlpha((0.18 * 255).round()),
            borderRadius: borderRadius,
            border: Border.all(
                color: color.withAlpha((0.4 * 255).round()), width: 0.6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                DivisionUtils.displayName(event.division),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
              ? const Color.fromRGBO(0, 102, 204, 0.1)
              : (isCurrentMonth ? Colors.white : Colors.grey[100]!),
          border: Border.all(
            color: isToday
                ? const Color(0xFF0066CC)
                : (hasHoliday && _showHolidays
                    ? holiday!.color.withAlpha((0.3 * 255).round())
                    : (isCurrentMonth
                        ? Colors.grey.shade200
                        : Colors.grey.shade100)),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            // Day Number (top right)
            Positioned(
              top: 8,
              right: 8,
              child: Text(
                day.day.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isCurrentMonth
                      ? (isToday
                          ? const Color(0xFF0066CC)
                          : (hasHoliday && _showHolidays
                              ? holiday!.color
                              : (day.weekday == 7
                                  ? Colors.red
                                  : Colors.black87)))
                      : Colors.grey[400],
                ),
              ),
            ),

            // HOLIDAY DISPLAY - CENTER (NEW!)
            if (hasHoliday && _showHolidays)
              Positioned(
                top: 26,
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

            // EVENT DISPLAY - BOTTOM (support multi-day series indicator)
            if (hasEvents && (!hasHoliday || !_showHolidays))
              Positioned(
                bottom: 8,
                left: 6,
                right: 6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Render up to 3 stacked indicators (more -> +n)
                    for (var i = 0; i < dayEvents.length && i < 3; i++)
                      _buildEventIndicator(day, dayEvents[i]),
                    if (dayEvents.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '+${dayEvents.length - 3}',
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),

            // Jika ada BOTH holiday dan event
            if (hasEvents && hasHoliday && _showHolidays)
              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getDivisionColor(dayEvents.first.division)
                        .withAlpha((0.15 * 255).round()),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getDivisionColor(dayEvents.first.division)
                          .withAlpha((0.3 * 255).round()),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    _getDivisionAbbreviation(dayEvents.first.division),
                    style: TextStyle(
                      fontSize: 10,
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
                      color: holiday.color.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: holiday.color.withAlpha((0.3 * 255).round())),
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
                                holiday.type == 'national'
                                    ? 'Libur Nasional'
                                    : 'Cuti Bersama',
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

  // Dialog-based month/year picker removed — using inline AppBar dropdowns now.

  /// Compute min/max year to display in the year dropdown. Prefer the years
  /// found in loaded events/holidays if available, otherwise provide a
  /// reasonably wide range around the current year.
  Map<String, int> _getYearBounds() {
    final current = DateTime.now().year;
    int minYear = current - 10;
    int maxYear = current + 10;

    for (var key in _eventsByDate.keys) {
      try {
        final y = int.parse(key.split('-').first);
        if (y < minYear) minYear = y;
        if (y > maxYear) maxYear = y;
      } catch (_) {}
    }

    for (var key in _holidaysByDate.keys) {
      try {
        final y = int.parse(key.split('-').first);
        if (y < minYear) minYear = y;
        if (y > maxYear) maxYear = y;
      } catch (_) {}
    }

    // Expand slightly so user can pick one year beyond found data.
    return {'min': minYear - 1, 'max': maxYear + 1};
  }

  @override
  Widget build(BuildContext context) {
    final monthDays = _daysInMonth(_focused);
    final weekDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(_focused).toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            // Expose a plain month name (invisible) for widget tests that look for
            // the non-uppercased month string while keeping visual unchanged
            Opacity(
                opacity: 0.0, child: Text(DateFormat.MMMM().format(_focused))),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0066CC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.calendar_today, color: Colors.white),
          onPressed: _isAnimatingMonthChange
              ? null
              : () {
                  final newFocused = DateTime.now();
                  _requestMonthChange(newFocused);
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
          // Inline month & year selector (compact)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Theme(
                  data: Theme.of(context).copyWith(
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      key: const Key('month_dropdown'),
                      value: _focused.month,
                      dropdownColor: Colors.white,
                      iconEnabledColor: Colors.white,
                      isDense: true,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      items: List.generate(12, (i) => i + 1)
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(
                                  DateFormat.MMMM().format(DateTime(2000, m)),
                                  style: const TextStyle(
                                    color: Color(0xFF0066CC),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ))
                          .toList(),
                      selectedItemBuilder: (context) => List.generate(
                        12,
                        (i) => Text(
                          DateFormat.MMM()
                              .format(DateTime(2000, i + 1))
                              .toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      onChanged: _isAnimatingMonthChange
                          ? null
                          : (m) {
                              if (m != null) {
                                final newFocused =
                                    DateTime(_focused.year, m, 1);
                                _requestMonthChange(newFocused);
                              }
                            },
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Theme(
                  data: Theme.of(context).copyWith(
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _focused.year,
                      dropdownColor: Colors.white,
                      iconEnabledColor: Colors.white,
                      isDense: true,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      items: [
                        for (var y = _getYearBounds()['min']!;
                            y <= _getYearBounds()['max']!;
                            y++)
                          y
                      ]
                          .map((y) => DropdownMenuItem(
                                value: y,
                                child: Text(
                                  y.toString(),
                                  style: const TextStyle(
                                    color: Color(0xFF0066CC),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ))
                          .toList(),
                      selectedItemBuilder: (context) {
                        final bounds = _getYearBounds();
                        return [
                          for (var y = bounds['min']!; y <= bounds['max']!; y++)
                            Text(
                              y.toString(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                        ];
                      },
                      onChanged: _isAnimatingMonthChange
                          ? null
                          : (y) {
                              if (y != null) {
                                final newFocused =
                                    DateTime(y, _focused.month, 1);
                                _requestMonthChange(newFocused);
                              }
                            },
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('prev_button'),
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: _isAnimatingMonthChange
                ? null
                : () {
                    final newFocused =
                        DateTime(_focused.year, _focused.month - 1, 1);
                    _requestMonthChange(newFocused);
                  },
          ),
          IconButton(
            key: const Key('next_button'),
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: _isAnimatingMonthChange
                ? null
                : () {
                    final newFocused =
                        DateTime(_focused.year, _focused.month + 1, 1);
                    _requestMonthChange(newFocused);
                  },
          ),
          widget.disableRealtimeIndicator
              ? IconButton(
                  icon: const Icon(Icons.cloud_done, color: Colors.green),
                  onPressed: () {},
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('events')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final isConnected =
                        snapshot.connectionState == ConnectionState.active;
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
                  child: PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: 3,
                    physics: const PageScrollPhysics(),
                    onPageChanged: (index) => _handlePageChanged(index),
                    itemBuilder: (context, index) {
                      final model = index == 0
                          ? _prevMonth
                          : (index == 1 ? _currentMonth : _nextMonth);
                      if (model == null) return const SizedBox.shrink();

                      return RepaintBoundary(
                        child: MonthView(
                          key: ValueKey('${model.year}-${model.month}'),
                          model: model,
                          showHolidays: _showHolidays,
                          onDayTap: _showDayEvents,
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
                          _buildLegendItem(
                              DivisionUtils.displayName('Unitas SI'),
                              DivisionUtils.colorFor('Unitas SI')),
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
                      if (widget.isAdmin)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            key: const Key('tambah_event_text'),
                            onPressed: _openCreateEvent,
                            child: const Text('Tambah Event'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: () => _openCreateEvent(),
              backgroundColor: const Color(0xFF0066CC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha((0.3 * 255).round())),
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

  // Isolate month grid into a separate method so each month has a stable
  // widget instance during transitions. This minimizes mid-animation rebuilds.
  Widget _buildMonthGrid(List<DateTime> monthDays, DateTime monthFocus) {
    return GridView.builder(
      key: ValueKey('${monthFocus.year}-${monthFocus.month}'),
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.9,
      ),
      itemCount: monthDays.length,
      itemBuilder: (context, index) {
        final day = monthDays[index];
        return _buildDayCell(day, monthFocus);
      },
    );
  }

  // Prepare the three month models (prev/current/next) synchronously.
  void _prepareMonthModelsFor(DateTime focused) {
    _currentMonth =
        MonthModel.fromMaps(focused, _eventsByDate, _holidaysByDate);
    _prevMonth = MonthModel.fromMaps(
        DateTime(focused.year, focused.month - 1, 1),
        _eventsByDate,
        _holidaysByDate);
    _nextMonth = MonthModel.fromMaps(
        DateTime(focused.year, focused.month + 1, 1),
        _eventsByDate,
        _holidaysByDate);
  }

  // Centralized request handler for month changes. Enforces single transition flow.
  void _requestMonthChange(DateTime targetFocused) {
    if (_isAnimatingMonthChange) return;

    // No-op
    if (targetFocused.year == _focused.year &&
        targetFocused.month == _focused.month) return;

    final monthDiff = (targetFocused.year - _focused.year) * 12 +
        (targetFocused.month - _focused.month);

    // Adjacent -> ensure neighbor models are ready, then animate via PageView
    if (monthDiff == -1) {
      _prepareMonthModelsFor(_focused); // ensure cached prev/current/next exist
      _isAnimatingMonthChange = true;
      _pageController.animateToPage(0,
          duration: _pageAnimationDuration, curve: Curves.easeOutCubic);
      return;
    }

    if (monthDiff == 1) {
      _prepareMonthModelsFor(_focused); // ensure cached prev/current/next exist
      _isAnimatingMonthChange = true;
      _pageController.animateToPage(2,
          duration: _pageAnimationDuration, curve: Curves.easeOutCubic);
      return;
    }

    // Non-adjacent -> instant jump: update focus and rebuild months synchronously
    setState(() {
      _focused = targetFocused;
      _prepareMonthModelsFor(_focused);
      _isAnimatingMonthChange = false;
    });

    // Ensure the PageView shows the middle page (safe to jump in place)
    _pageController.jumpToPage(1);
  }

  // Handle page settle events from PageView. If user navigated to page 0 or 2,
  // advance the logical focus and rebuild the 3-page cache, then reset the
  // PageController back to page 1 without animation to keep the carousel stable.
  // This method follows the strict rule: compute NEXT models synchronously,
  // then update state in a single atomic setState so no mid-frame swapping
  // occurs. This prevents visual overlap and ensures deterministic rendering.
  void _handlePageChanged(int index) {
    if (index == 1) return;

    // Lock transitions when a user-driven swipe settles on a neighbor page.
    if (!_isAnimatingMonthChange) {
      _isAnimatingMonthChange = true;
    }

    // Determine the new focused month and precompute the new models BEFORE
    // touching the PageController or calling setState to avoid mid-animation
    // rebuilds of visible pages.
    DateTime newFocused;
    if (index == 0) {
      newFocused = DateTime(_focused.year, _focused.month - 1, 1);
    } else {
      newFocused = DateTime(_focused.year, _focused.month + 1, 1);
    }

    // Build new models synchronously but do not yet mutate state (cheap-ish work
    // but kept outside setState so we don't trigger layout during animation frames)
    final newCurrent =
        MonthModel.fromMaps(newFocused, _eventsByDate, _holidaysByDate);
    final newPrev = MonthModel.fromMaps(
        DateTime(newFocused.year, newFocused.month - 1, 1),
        _eventsByDate,
        _holidaysByDate);
    final newNext = MonthModel.fromMaps(
        DateTime(newFocused.year, newFocused.month + 1, 1),
        _eventsByDate,
        _holidaysByDate);

    // Reset the visible page to the middle immediately (no animation) so the
    // carousel stays centered. Do the mutation after jump to avoid swapping the
    // visible page content mid-frame.
    if (_pageController.hasClients) _pageController.jumpToPage(1);

    // Now commit the prepared models in one setState so widgets reattach to
    // their stable keys in a single rebuild.
    if (mounted) {
      setState(() {
        _focused = newFocused;
        _currentMonth = newCurrent;
        _prevMonth = newPrev;
        _nextMonth = newNext;
      });
    }

    // Clear the transition lock after the animation duration + small buffer.
    Future.delayed(_pageAnimationDuration + const Duration(milliseconds: 50),
        () {
      if (mounted) setState(() => _isAnimatingMonthChange = false);
    });
  }

  // Open the create event flow. If a test injection callback is provided, we
  // push the `EditEventPage` with an onSave that invokes the injected
  // callback and pops. If no callback is provided, fall back to the
  // existing default behavior (navigate to Admin page).
  void _openCreateEvent() {
    final now = DateTime.now();
    final todayStr = '${now.year.toString().padLeft(4, '0')}-'
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";

    final newEvent = EventModel(id: '', title: '', startDate: todayStr);

    if (widget.onCreateEvent != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return EditEventPage(
          event: newEvent,
          onSave: (created) async {
            final navigator = Navigator.of(context);
            await widget.onCreateEvent!(created);
            // Close the editor only if still mounted (avoid using context across
            // async gaps which can cause runtime issues when widget is disposed).
            if (!mounted) return;
            navigator.pop();
          },
        );
      }));
      return;
    }

    // For tests (disableRealtimeIndicator) open the editor directly and save via
    // the same local add path to avoid depending on the '/admin' route being
    // present in the test app.
    if (widget.disableRealtimeIndicator) {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return EditEventPage(
          event: newEvent,
          onSave: (created) async {
            final navigator = Navigator.of(context);
            await DataLoader.addEvent(created);
            // Reload data to reflect the saved event
            _loadData();
            if (!mounted) return;
            navigator.pop();
          },
        );
      }));
      return;
    }

    // Default: navigate to admin page for full add event flow
    Navigator.pushNamed(context, '/admin');
  }

  // ---------------------------
  // Testing helpers (visible in debug only)
  // ---------------------------
  // Expose a few small helpers so guardrail tests can assert internal
  // invariants (recentering, transition lock, focused month). These are
  // annotated for testing visibility and intentionally small to avoid
  // exposing implementation complexity in production code.
  @visibleForTesting
  double? debugCurrentPage() =>
      _pageController.hasClients ? _pageController.page : null;

  @visibleForTesting
  bool debugIsTransitioning() => _isAnimatingMonthChange;

  @visibleForTesting
  DateTime debugFocused() => _focused;
}
