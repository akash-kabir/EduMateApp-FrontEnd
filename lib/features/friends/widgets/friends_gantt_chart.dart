import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:app/features/friends/models/friend_model.dart';
import 'package:app/theme/theme.dart';

class FriendsGanttChart extends StatefulWidget {
  final List<dynamic> userSchedule;
  final List<FriendModel> friends;
  final Map<String, List<dynamic>> friendsSchedules;
  final String currentDayName; // e.g. "Monday"

  const FriendsGanttChart({
    super.key,
    required this.userSchedule,
    required this.friends,
    required this.friendsSchedules,
    required this.currentDayName,
  });

  @override
  State<FriendsGanttChart> createState() => _FriendsGanttChartState();
}

class _FriendsGanttChartState extends State<FriendsGanttChart> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _gridHorizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  static const double _pixelsPerMinute = 2.4;
  static const double _rowHeight = 78.0;
  static const double _yAxisWidth = 72.0;
  static const double _headerHeight = 48.0;

  double _minMinutes = 480; // Default 8:00 AM
  double _maxMinutes = 1020; // Default 5:00 PM
  bool _isSyncingScroll = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _calculateTimeBounds();

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });

    // Synchronize top time ruler scroll with main grid horizontal scroll
    _horizontalScrollController.addListener(() {
      if (_isSyncingScroll) return;
      _isSyncingScroll = true;
      if (_gridHorizontalScrollController.hasClients &&
          _gridHorizontalScrollController.offset != _horizontalScrollController.offset) {
        _gridHorizontalScrollController.jumpTo(_horizontalScrollController.offset);
      }
      _isSyncingScroll = false;
    });

    _gridHorizontalScrollController.addListener(() {
      if (_isSyncingScroll) return;
      _isSyncingScroll = true;
      if (_horizontalScrollController.hasClients &&
          _horizontalScrollController.offset != _gridHorizontalScrollController.offset) {
        _horizontalScrollController.jumpTo(_gridHorizontalScrollController.offset);
      }
      _isSyncingScroll = false;
    });
  }

  @override
  void didUpdateWidget(covariant FriendsGanttChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _calculateTimeBounds();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _horizontalScrollController.dispose();
    _gridHorizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _mergeAdjacentPeriods(List<dynamic> rawPeriods) {
    if (rawPeriods.isEmpty) return [];
    
    List<Map<String, dynamic>> processed = [];
    for (var p in rawPeriods) {
      final times = _parseStartAndEndMinutes(p);
      final start = times['start']!;
      final end = times['end']!;
      if (start <= 0) continue;
      
      processed.add({
        'original': p,
        'start': start,
        'end': end,
        'subject': _extractSubjectName(p),
      });
    }
    
    processed.sort((a, b) => (a['start'] as double).compareTo(b['start'] as double));
    
    List<Map<String, dynamic>> merged = [];
    for (var current in processed) {
      if (merged.isEmpty) {
        merged.add(current);
      } else {
        var previous = merged.last;
        if (previous['end'] == current['start'] && previous['subject'] == current['subject']) {
          previous['end'] = current['end'];
        } else {
          merged.add(current);
        }
      }
    }
    
    return merged;
  }

  bool _isSameDay(dynamic dayValue, String targetDayName) {
    if (dayValue == null) return false;
    final valStr = dayValue.toString().toLowerCase().trim();
    final target = targetDayName.toLowerCase().trim();

    if (valStr == target) return true;

    final Map<String, int> dayMap = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };

    final targetNum = dayMap[target];
    if (targetNum != null && valStr == targetNum.toString()) {
      return true;
    }

    return false;
  }

  Map<String, double> _parseStartAndEndMinutes(dynamic p) {
    if (p == null) return {'start': 0, 'end': 0};

    String startStr = p['startTime']?.toString() ?? '';
    String endStr = p['endTime']?.toString() ?? '';

    final timeStr = p['time']?.toString() ?? '';
    if (timeStr.contains('-')) {
      final parts = timeStr.split('-');
      if (startStr.isEmpty) startStr = parts[0].trim();
      if (endStr.isEmpty && parts.length > 1) endStr = parts[1].trim();
    }

    final start = _parseSingleTime(startStr);
    var end = _parseSingleTime(endStr);

    if (start > 0 && end <= start) {
      end = start + 50; // Default 50 mins
    }

    return {'start': start, 'end': end};
  }

  double _parseSingleTime(String timeStr) {
    if (timeStr.isEmpty) return 0;
    try {
      final clean = timeStr.trim().toUpperCase();
      final isPM = clean.contains('PM');
      final isAM = clean.contains('AM');

      final numPart = clean.replaceAll(RegExp(r'[^0-9:]'), '');
      final parts = numPart.split(':');
      if (parts.isEmpty || parts[0].isEmpty) return 0;

      int hours = int.parse(parts[0]);
      int minutes = parts.length > 1 && parts[1].isNotEmpty ? int.parse(parts[1]) : 0;

      if (isPM && hours < 12) hours += 12;
      if (isAM && hours == 12) hours = 0;
      if (!isPM && !isAM && hours < 7) hours += 12;

      return (hours * 60 + minutes).toDouble();
    } catch (_) {
      return 0;
    }
  }

  void _calculateTimeBounds() {
    double minM = 24 * 60;
    double maxM = 0;

    void processPeriod(dynamic p) {
      final times = _parseStartAndEndMinutes(p);
      final start = times['start']!;
      final end = times['end']!;

      if (start > 0) {
        if (start < minM) minM = start;
        if (end > maxM) maxM = end;
      }
    }

    // Check user schedule
    for (var p in widget.userSchedule) {
      processPeriod(p);
    }

    // Check friends schedules for current day
    for (var friend in widget.friends) {
      final friendDays = widget.friendsSchedules[friend.rollNo] ?? [];
      final todayObj = friendDays.firstWhere(
        (d) => _isSameDay(d['day'], widget.currentDayName),
        orElse: () => null,
      );
      if (todayObj != null && todayObj['periods'] != null) {
        for (var p in todayObj['periods']) {
          processPeriod(p);
        }
      }
    }

    if (minM >= maxM || minM == 24 * 60) {
      minM = 480; // 8:00 AM
      maxM = 1020; // 5:00 PM
    } else {
      minM = (minM - 5).clamp(0, 24 * 60);
      maxM = (maxM + 30).clamp(0, 24 * 60);
    }

    _minMinutes = minM;
    _maxMinutes = maxM;
  }

  List<dynamic> _getFriendTodayPeriods(String rollNo) {
    final days = widget.friendsSchedules[rollNo] ?? [];
    final todayObj = days.firstWhere(
      (d) => _isSameDay(d['day'], widget.currentDayName),
      orElse: () => null,
    );
    if (todayObj != null && todayObj['periods'] != null) {
      return List<dynamic>.from(todayObj['periods']);
    }
    return [];
  }

  String _extractSubjectName(dynamic p) {
    if (p == null) return 'Class';
    if (p['subject'] != null && p['subject'].toString().trim().isNotEmpty) {
      return p['subject'].toString().trim();
    }
    if (p['className'] != null && p['className'].toString().trim().isNotEmpty) {
      return p['className'].toString().trim();
    }
    if (p['name'] != null && p['name'].toString().trim().isNotEmpty) {
      return p['name'].toString().trim();
    }
    if (p['title'] != null && p['title'].toString().trim().isNotEmpty) {
      return p['title'].toString().trim();
    }
    return 'Class';
  }

  @override
  Widget build(BuildContext context) {
    final totalMinutes = _maxMinutes - _minMinutes;
    final timelineWidth = totalMinutes * _pixelsPerMinute;

    final now = DateTime.now();
    final currentMinutes = (now.hour * 60 + now.minute).toDouble();
    final hasCurrentTime = currentMinutes >= _minMinutes && currentMinutes <= _maxMinutes;
    final currentTimeX = (currentMinutes - _minMinutes) * _pixelsPerMinute;

    bool intersectsClass = false;
    for (var p in widget.userSchedule) {
      final t = _parseStartAndEndMinutes(p);
      if (t['start']! > 0 && currentMinutes >= t['start']! && currentMinutes < t['end']!) {
        intersectsClass = true;
        break;
      }
    }
    if (!intersectsClass) {
      for (var f in widget.friends) {
        for (var p in _getFriendTodayPeriods(f.rollNo)) {
          final t = _parseStartAndEndMinutes(p);
          if (t['start']! > 0 && currentMinutes >= t['start']! && currentMinutes < t['end']!) {
            intersectsClass = true;
            break;
          }
        }
        if (intersectsClass) break;
      }
    }
    final pointerColor = intersectsClass ? const Color(0xFF10B981) : Colors.redAccent;

    return Container(
      color: UserColors.background,
      child: Column(
        children: [
          // Seamless Top Bar (Time Scale Header)
          SizedBox(
            height: _headerHeight,
            child: Row(
              children: [
                // Top-Left corner Y-Axis Title
                Container(
                  width: _yAxisWidth,
                  height: _headerHeight,
                  alignment: Alignment.center,
                  child: const Text(
                    'TIME',
                    style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
                  ),
                ),
                // Top-Right Scrollable Time Scale Header
                Expanded(
                  child: SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: SizedBox(
                      width: timelineWidth,
                      height: _headerHeight,
                      child: Stack(
                        children: [
                          ..._buildTimeTicks(timelineWidth),
                          if (hasCurrentTime)
                            Positioned(
                              left: currentTimeX - 22,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: pointerColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: pointerColor.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Interactive Grid
          Expanded(
            child: SingleChildScrollView(
              controller: _verticalScrollController,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Y-Axis Floating Avatar & Label List
                  SizedBox(
                    width: _yAxisWidth,
                    child: Column(
                      children: [
                        _buildYAxisCell('You', isUser: true),
                        ...widget.friends.map((f) => _buildYAxisCell(f.nameTag)),
                      ],
                    ),
                  ),

                  // Horizontal Timeline Canvas (Synchronized with Header)
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _gridHorizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: SizedBox(
                        width: timelineWidth,
                        child: Stack(
                          children: [
                            ..._buildGridLines(timelineWidth),
                            Column(
                              children: [
                                _buildTimelineRow(widget.userSchedule, isUser: true, nowMinutes: currentMinutes),
                                ...widget.friends.map(
                                  (f) => _buildTimelineRow(_getFriendTodayPeriods(f.rollNo), nowMinutes: currentMinutes),
                                ),
                              ],
                            ),
                            if (hasCurrentTime)
                              Positioned(
                                left: currentTimeX,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 2,
                                  decoration: BoxDecoration(
                                    color: pointerColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: pointerColor.withValues(alpha: 0.6),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYAxisCell(String label, {bool isUser = false}) {
    return Container(
      width: _yAxisWidth,
      height: _rowHeight,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isUser ? AuthPalette.teal : Colors.white.withValues(alpha: 0.8),
          fontWeight: isUser ? FontWeight.w800 : FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildTimelineRow(List<dynamic> rawPeriods, {bool isUser = false, required double nowMinutes}) {
    final mergedPeriods = _mergeAdjacentPeriods(rawPeriods);
    
    return SizedBox(
      height: _rowHeight,
      child: Stack(
        children: mergedPeriods.map((pMap) {
          final p = pMap['original'];
          final start = pMap['start'] as double;
          final end = pMap['end'] as double;

          final duration = (end > start) ? (end - start) : 50.0;
          final left = (start - _minMinutes) * _pixelsPerMinute;
          final width = duration * _pixelsPerMinute;

          final subject = _extractSubjectName(p);
          final room = p['room']?.toString();
          final upperSubject = subject.toUpperCase();

          final isElective = p['isElective'] == true ||
              p['type'] == 'elective' ||
              upperSubject.contains('ELECTIVE') ||
              upperSubject.startsWith('PE') ||
              upperSubject.startsWith('OE') ||
              upperSubject.contains('KEXPLORE');

          final isGap = upperSubject.contains('GAP') || upperSubject.contains('FREE');
          final isOngoing = nowMinutes >= start && nowMinutes <= end;

          // Distinctive Dark Colors per Category
          final Color cardColor;
          final Color borderColor;
          final Color textColor;

          if (isGap) {
            cardColor = Colors.teal.withValues(alpha: 0.12);
            borderColor = Colors.teal.withValues(alpha: 0.3);
            textColor = Colors.tealAccent;
          } else if (isOngoing) {
            cardColor = const Color(0xFF2E4039);
            borderColor = AuthPalette.teal;
            textColor = Colors.greenAccent;
          } else if (isElective) {
            // Elective Card: Warm Dark Purple & Amber border for immediate recognition
            cardColor = const Color(0xFF3B2A36);
            borderColor = Colors.amberAccent.withValues(alpha: 0.85);
            textColor = Colors.amberAccent;
          } else if (isUser) {
            cardColor = const Color(0xFF141110);
            borderColor = AuthPalette.teal.withValues(alpha: 0.5);
            textColor = Colors.white;
          } else {
            cardColor = const Color(0xFF141110);
            borderColor = Colors.white.withValues(alpha: 0.12);
            textColor = Colors.white;
          }

          return Positioned(
            left: left + 3,
            width: (width - 6).clamp(16.0, double.infinity),
            top: 6,
            bottom: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: (isOngoing || isElective) ? 1.5 : 1.0),
                ),
                child: Row(
                  children: [
                    if (isOngoing)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.greenAccent,
                        ),
                      ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (room != null && room.isNotEmpty && !isGap)
                            Text(
                              room,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildTimeTicks(double width) {
    final List<Widget> ticks = [];
    final startHour = (_minMinutes / 60).floor();
    final endHour = (_maxMinutes / 60).ceil();

    for (int h = startHour; h <= endHour; h++) {
      final minutes = h * 60.0;
      if (minutes >= _minMinutes && minutes <= _maxMinutes) {
        final x = (minutes - _minMinutes) * _pixelsPerMinute;
        final displayHour = h % 12 == 0 ? 12 : h % 12;
        final amPm = h >= 12 ? 'PM' : 'AM';

        ticks.add(
          Positioned(
            left: x,
            bottom: 6,
            child: FractionalTranslation(
              translation: const Offset(-0.5, 0),
              child: Column(
                children: [
                  Text(
                    '$displayHour $amPm',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 1.5,
                    height: 6,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
    return ticks;
  }

  List<Widget> _buildGridLines(double width) {
    final List<Widget> lines = [];
    final startHour = (_minMinutes / 60).floor();
    final endHour = (_maxMinutes / 60).ceil();

    for (int h = startHour; h <= endHour; h++) {
      final minutes = h * 60.0;
      if (minutes >= _minMinutes && minutes <= _maxMinutes) {
        final x = (minutes - _minMinutes) * _pixelsPerMinute;
        lines.add(
          Positioned(
            left: x,
            top: 0,
            bottom: 0,
            child: Container(
              width: 1,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        );
      }
    }
    return lines;
  }
}
