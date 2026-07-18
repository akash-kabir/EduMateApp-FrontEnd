import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../../../services/holiday_service.dart';
import '../../../widgets/toast_manager.dart';

class HolidayListScreen extends StatefulWidget {
  const HolidayListScreen({super.key});

  @override
  State<HolidayListScreen> createState() => _HolidayListScreenState();
}

class _HolidayListScreenState extends State<HolidayListScreen> {
  bool _isLoading = true;
  List<dynamic> _holidays = [];
  final int _currentYear = DateTime.now().year;

  // Variables to track "Today" pointer
  int _todayLineIndex = -1;
  int _todayHolidayIndex = -1;
  
  final GlobalKey _targetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchHolidays();
  }

  void _scrollToTarget() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Adding a small delay ensures layout is completely finished
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _targetKey.currentContext != null) {
          Scrollable.ensureVisible(
            _targetKey.currentContext!,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            alignment: 0.5, // Center the target in the viewport
          );
        }
      });
    });
  }

  Future<void> _fetchHolidays() async {
    setState(() => _isLoading = true);
    
    final result = await HolidayService.fetchHolidays(_currentYear);
    
    if (result['success'] == true) {
      final List<dynamic> fetchedHolidays = result['data'];
      
      // Sort holidays by start date just in case
      fetchedHolidays.sort((a, b) => 
        DateTime.parse(a['startDate']).compareTo(DateTime.parse(b['startDate']))
      );

      _holidays = fetchedHolidays;
      _calculateTodayPointer();
    } else {
      if (mounted) {
        EduMateToast.showCompact(context, message: 'Failed to load holidays', isSuccess: false);
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToTarget();
    }
  }

  void _calculateTodayPointer() {
    if (_holidays.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Strip time

    _todayHolidayIndex = -1;
    _todayLineIndex = -1;

    for (int i = 0; i < _holidays.length; i++) {
      final holiday = _holidays[i];
      final startDate = DateTime.parse(holiday['startDate']);
      final endDate = DateTime.parse(holiday['endDate']);
      
      // Normalize to midnight for accurate day comparison
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      if (today.isAtSameMomentAs(start) || today.isAtSameMomentAs(end) || (today.isAfter(start) && today.isBefore(end))) {
        // Today is this holiday!
        _todayHolidayIndex = i;
        return;
      }
    }

    // If we reach here, today is NOT a holiday. We need to find where to place the line.
    for (int i = 0; i < _holidays.length; i++) {
      final holiday = _holidays[i];
      final startDate = DateTime.parse(holiday['startDate']);
      final start = DateTime(startDate.year, startDate.month, startDate.day);

      if (today.isBefore(start)) {
        // Today is before this holiday. So the line goes exactly here (before it).
        _todayLineIndex = i;
        return;
      }
    }

    // If today is after ALL holidays, put the line at the very end
    _todayLineIndex = _holidays.length;
  }

  Widget _buildTodayLine(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 2,
            color: Colors.redAccent.withOpacity(0.8),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'TODAY',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHolidayCard(dynamic holiday, bool isDark, bool isToday) {
    final startDate = DateTime.parse(holiday['startDate']);
    final endDate = DateTime.parse(holiday['endDate']);
    
    // Format date string (e.g. 23.01.2026 or 14.09.2026 - 15.09.2026)
    final startFormat = DateFormat('dd.MM.yyyy').format(startDate);
    final endFormat = DateFormat('dd.MM.yyyy').format(endDate);
    final dateDisplay = (startFormat == endFormat) ? startFormat : '$startFormat - $endFormat';

    final noOfDays = holiday['noOfDays'];
    final event = holiday['event'];
    final daysStr = holiday['days'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'TODAY',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isToday 
                    ? Colors.redAccent 
                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.transparent),
                width: isToday ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                if (isToday)
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.15),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isToday 
                              ? Colors.redAccent.withOpacity(0.1) 
                              : const Color(0xFF2E8B57).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              startDate.day.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isToday ? Colors.redAccent : const Color(0xFF2E8B57),
                              ),
                            ),
                            Text(
                              DateFormat('MMM').format(startDate).toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isToday ? Colors.redAccent : const Color(0xFF2E8B57),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                                height: 1.3,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.calendar,
                                  size: 14,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    daysStr,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.time,
                                  size: 14,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dateDisplay,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.info_circle,
                                  size: 14,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$noOfDays ${noOfDays == 1 ? "Day" : "Days"}',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Holidays',
          style: TextStyle(
            fontFamily: 'Salena',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark
            ? CupertinoColors.black.withOpacity(0.6)
            : CupertinoColors.white.withOpacity(0.6),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator(radius: 16))
            : _holidays.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.calendar,
                          size: 64,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No holidays found for $_currentYear.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: List.generate(_holidays.length + 1, (index) {
                        if (index == _holidays.length) {
                          if (_todayLineIndex == _holidays.length) {
                            return Container(
                              key: _targetKey,
                              child: _buildTodayLine(isDark),
                            );
                          }
                          return const SizedBox.shrink();
                        }

                        final isTodayHoliday = (index == _todayHolidayIndex);
                        final isTarget = isTodayHoliday || (index == _todayLineIndex);

                        return Container(
                          key: isTarget ? _targetKey : null,
                          child: Column(
                            children: [
                              if (index == _todayLineIndex) _buildTodayLine(isDark),
                              _buildHolidayCard(_holidays[index], isDark, isTodayHoliday),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
        ),
      ),
    );
  }
}
