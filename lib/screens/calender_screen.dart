import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import 'timesheet_screen.dart';

class CalenderScreen extends StatefulWidget {
  const CalenderScreen({super.key});

  @override
  State<CalenderScreen> createState() => _CalenderScreenState();
}

class _CalenderScreenState extends State<CalenderScreen> {
  late DateTime selectedDate;
  late ScrollController _scrollController;
  List<dynamic> events = [];
  bool isLoadingEvents = false;
  Set<String> selectedEventFilters = {
    'event',
    'assignment',
    'privateEvent',
    'holiday',
  }; 

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _scrollController = ScrollController();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => isLoadingEvents = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${Config.BASE_URL}/api/posts?postType=event'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          events = data['posts'] ?? [];
          isLoadingEvents = false;
        });
      } else {
        setState(() => isLoadingEvents = false);
      }
    } catch (e) {
      setState(() => isLoadingEvents = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<DateTime> getMonthDates(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    return List.generate(lastDay.day, (i) => firstDay.add(Duration(days: i)));
  }

  List<Map<String, dynamic>> _getEventsForDate(DateTime date) {
    List<Map<String, dynamic>> dateEvents = [];

    for (var event in events) {
      final eventType = event['postType'] as String;
      if (!selectedEventFilters.contains(eventType)) {
        continue;
      }

      if (event['eventDetails'] != null) {
        final eventDetails = event['eventDetails'];
        final startDate = eventDetails['startDate'];

        if (startDate != null) {
          try {
            final eventDateTime = DateTime.parse(startDate);
            final eventDate = DateTime(
              eventDateTime.year,
              eventDateTime.month,
              eventDateTime.day,
            );
            final targetDate = DateTime(date.year, date.month, date.day);

            if (eventDate == targetDate) {
              dateEvents.add({
                'title': event['heading'] ?? 'Event',
                'time': eventDetails['startTime'] ?? '',
                'color': CupertinoColors.systemPurple,
              });
            }
          } catch (e) {}
        }
      }
    }

    return dateEvents;
  }

  void _showFilterDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter dialogSetState) => Material(
          child: Container(
            height: 320,
            padding: const EdgeInsets.only(top: 6.0),
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      CupertinoButton(
                        child: const Text('Done'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildFilterCheckbox(
                          'Holidays',
                          'holiday',
                          dialogSetState,
                        ),
                        _buildFilterCheckbox('Events', 'event', dialogSetState),
                        _buildFilterCheckbox(
                          'Assignments',
                          'assignment',
                          dialogSetState,
                        ),
                        _buildFilterCheckbox(
                          'Private Events',
                          'privateEvent',
                          dialogSetState,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterCheckbox(
    String label,
    String value,
    StateSetter dialogSetState,
  ) {
    final isSelected = selectedEventFilters.contains(value);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        dialogSetState(() {
          if (selectedEventFilters.contains(value)) {
            selectedEventFilters.remove(value);
          } else {
            selectedEventFilters.add(value);
          }
        });
        setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 18, color: Colors.blue)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : CupertinoColors.white,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            automaticallyImplyLeading: false,
            largeTitle: const Text('Calendar'),
            backgroundColor: isDark
                ? CupertinoColors.black.withOpacity(0.6)
                : CupertinoColors.white.withOpacity(0.6),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showFilterDialog,
              child: const Icon(CupertinoIcons.line_horizontal_3_decrease),
            ),
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildMonthViewAppleStyle(isDark),

                const SizedBox(height: 6),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthViewAppleStyle(bool isDark) {
    final monthDates = getMonthDates(selectedDate);
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final firstWeekdayOffset = firstDayOfMonth.weekday - 1;
    final weekDayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.time,
                      size: 18,
                      color: CupertinoColors.systemBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Time sheet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Track your class hours and activities',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minSize: 0,
                  onPressed: () async {
                    await Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => const TimesheetScreen(),
                      ),
                    );
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'View Timesheet',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  onPressed: () {
                    setState(() {
                      selectedDate = DateTime(
                        selectedDate.year,
                        selectedDate.month - 1,
                      );
                    });
                  },
                  child: const Icon(CupertinoIcons.chevron_left, size: 16),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(selectedDate),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  onPressed: () {
                    setState(() {
                      selectedDate = DateTime(
                        selectedDate.year,
                        selectedDate.month + 1,
                      );
                    });
                  },
                  child: const Icon(CupertinoIcons.chevron_right, size: 16),
                ),
              ],
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekDayLabels.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 3),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.9,
            ),
            itemCount: firstWeekdayOffset + monthDates.length,
            itemBuilder: (context, index) {
              if (index < firstWeekdayOffset) {
                return const SizedBox();
              }
              final dateIndex = index - firstWeekdayOffset;
              final date = monthDates[dateIndex];
              final isToday =
                  date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;
              final isSelected =
                  date.year == selectedDate.year &&
                  date.month == selectedDate.month &&
                  date.day == selectedDate.day;
              final isWeekend = date.weekday == 6 || date.weekday == 7;

              return _buildAppleCalendarGrid(
                date: date,
                isToday: isToday,
                isSelected: isSelected,
                isWeekend: isWeekend,
                isDark: isDark,
              );
            },
          ),
          const SizedBox(height: 24),

          _buildSelectedDateEventsSection(isDark),
        ],
      ),
    );
  }

  Widget _buildAppleCalendarGrid({
    required DateTime date,
    required bool isToday,
    required bool isSelected,
    required bool isWeekend,
    required bool isDark,
  }) {
    final events = _getEventsForDate(date);
    final hasEvents = events.isNotEmpty;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDate = date;
        });
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(color: CupertinoColors.systemBlue, width: 2)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isToday
                        ? CupertinoColors.systemBlue
                        : isWeekend
                        ? Colors.grey[500]
                        : isDark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
            ),
            if (hasEvents)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: events.length > 4
                    ? Container(
                        width: 16,
                        height: 2,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(events.length, (index) {
                          return Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemPurple,
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDateEventsSection(bool isDark) {
    final events = _getEventsForDate(selectedDate);

    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.calendar_circle,
                  size: 20,
                  color: CupertinoColors.systemBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Events',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.grey[850] : Colors.grey[300],
          ),
          Expanded(
            child: events.isNotEmpty
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: event['color'] as Color,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.clock,
                                  size: 12,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  event['time'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      'No events scheduled',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
