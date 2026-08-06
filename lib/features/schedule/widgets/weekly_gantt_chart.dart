import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:app/theme/theme.dart';

class WeeklyGanttChart extends StatefulWidget {
  final List<dynamic> Function(int weekday) getClassesForDay;
  final DateTime now;
  final List<String> selectedElectives;

  const WeeklyGanttChart({
    super.key,
    required this.getClassesForDay,
    required this.now,
    this.selectedElectives = const [],
  });

  @override
  State<WeeklyGanttChart> createState() => _WeeklyGanttChartState();
}

class _WeeklyGanttChartState extends State<WeeklyGanttChart> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _gridHorizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  static const double _pixelsPerMinute = 2.4;
  static const double _yAxisWidth = 90.0;
  static const double _headerHeight = 36.0;

  double _minMinutes = 480; // Default 8:00 AM
  double _maxMinutes = 1020; // Default 5:00 PM
  bool _isSyncingScroll = false;
  Timer? _timer;

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  final List<int> _weekdayIndices = [1, 2, 3, 4, 5];

  @override
  void initState() {
    super.initState();
    _calculateTimeBounds();

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });

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
  void didUpdateWidget(covariant WeeklyGanttChart oldWidget) {
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
      end = start + 50;
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

    for (int day in _weekdayIndices) {
      final classes = widget.getClassesForDay(day);
      for (var p in classes) {
        processPeriod(p);
      }
    }

    if (minM >= maxM || minM == 24 * 60) {
      minM = 480;
      maxM = 1020;
    } else {
      minM = (minM - 5).clamp(0, 24 * 60);
      maxM = (maxM + 30).clamp(0, 24 * 60);
    }

    _minMinutes = minM;
    _maxMinutes = maxM;
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
    final timelineWidth = (totalMinutes * _pixelsPerMinute) + _yAxisWidth + 24;

    final nowMinutes = (widget.now.hour * 60 + widget.now.minute).toDouble();
    final hasCurrentTime = nowMinutes >= _minMinutes && nowMinutes <= _maxMinutes;
    final currentTimeX = ((nowMinutes - _minMinutes) * _pixelsPerMinute) + _yAxisWidth;

    return Container(
      color: Colors.transparent, // Background handled by parent
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 44.0,
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          children: [
          SizedBox(
            height: _headerHeight,
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    width: timelineWidth,
                    height: _headerHeight,
                    child: Stack(
                      children: [
                        ..._buildTimeTicks(timelineWidth),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Determine the row height dynamically so it fills the screen perfectly
                final double dynamicRowHeight = constraints.maxHeight / _weekdayIndices.length;
                final double rowHeight = dynamicRowHeight < 78.0 ? 78.0 : dynamicRowHeight;

                return SingleChildScrollView(
                  controller: _verticalScrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Stack(
                    children: [
                  SingleChildScrollView(
                    controller: _gridHorizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: SizedBox(
                      width: timelineWidth,
                      child: Stack(
                        children: [
                          ..._buildGridLines(timelineWidth),
                          Column(
                            children: _weekdayIndices.map((day) {
                              return _buildTimelineRow(widget.getClassesForDay(day), dayOfWeek: day, nowMinutes: nowMinutes, rowHeight: rowHeight);
                            }).toList(),
                          ),
                          if (hasCurrentTime && _weekdayIndices.contains(widget.now.weekday))
                            Positioned(
                              left: currentTimeX,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 2,
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.greenAccent.withValues(alpha: 0.6),
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
                  
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Column(
                        children: _weekdayIndices.map((day) {
                          return _buildYAxisCell(_days[_weekdayIndices.indexOf(day)], isToday: widget.now.weekday == day, rowHeight: rowHeight);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildYAxisCell(String label, {bool isToday = false, required double rowHeight}) {
    return SizedBox(
      width: _yAxisWidth - 16,
      height: rowHeight,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isToday ? Colors.greenAccent.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.1),
                    width: isToday ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    if (isToday)
                      BoxShadow(
                        color: Colors.greenAccent.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                  ],
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isToday ? Colors.greenAccent : Colors.white70,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineRow(List<dynamic> rawPeriods, {required int dayOfWeek, required double nowMinutes, required double rowHeight}) {
    final mergedPeriods = _mergeAdjacentPeriods(rawPeriods);
    final isToday = widget.now.weekday == dayOfWeek;
    
    return SizedBox(
      height: rowHeight,
      child: Stack(
        children: mergedPeriods.map((pMap) {
          final p = pMap['original'];
          final start = pMap['start'] as double;
          final end = pMap['end'] as double;

          final duration = (end > start) ? (end - start) : 50.0;
          final left = ((start - _minMinutes) * _pixelsPerMinute) + _yAxisWidth;
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
          final isOngoing = isToday && nowMinutes >= start && nowMinutes < end;
          
          final Color cardColor;
          final Color borderColor;
          final Color textColor;

          if (isGap) {
            cardColor = Colors.teal.withValues(alpha: 0.08);
            textColor = Colors.tealAccent.withValues(alpha: 0.7);
          } else {
            cardColor = const Color(0xFF1A1A1A);
            textColor = Colors.white;
          }

          return Positioned(
            left: left + 4,
            width: (width - 8).clamp(16.0, double.infinity),
            top: 8,
            bottom: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    if (isOngoing)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: 8,
                        height: 8,
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
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (room != null && room.isNotEmpty && !isGap)
                            Text(
                              room,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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
        final x = ((minutes - _minMinutes) * _pixelsPerMinute) + _yAxisWidth;
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
        final x = ((minutes - _minMinutes) * _pixelsPerMinute) + _yAxisWidth;
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
