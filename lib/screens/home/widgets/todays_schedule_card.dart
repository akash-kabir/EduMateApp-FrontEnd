import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/home_schedule_service.dart';
import 'todays_schedule_skeleton.dart';

class _OngoingTimeIndicator extends StatefulWidget {
  final String endTimeStr;

  const _OngoingTimeIndicator({required this.endTimeStr});

  @override
  State<_OngoingTimeIndicator> createState() => _OngoingTimeIndicatorState();
}

class _OngoingTimeIndicatorState extends State<_OngoingTimeIndicator> {
  Timer? _timer;
  int _minsLeft = 0;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final eParts = widget.endTimeStr.split(':');
    if (eParts.length == 2) {
      final now = DateTime.now();
      final end = DateTime(now.year, now.month, now.day, int.parse(eParts[0]), int.parse(eParts[1]));
      final diff = end.difference(now);
      final seconds = diff.inSeconds;
      final newMinsLeft = seconds > 0 ? (seconds / 60.0).ceil() : 0;
      if (newMinsLeft != _minsLeft && mounted) {
        setState(() {
          _minsLeft = newMinsLeft;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_minsLeft <= 0) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_minsLeft',
            style: const TextStyle(
              color: Color(0xFF10B981), 
              fontSize: 32, 
              fontWeight: FontWeight.w400,
              height: 1.0,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'mins',
                style: TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w500, height: 1.1),
              ),
              Text(
                'left',
                style: TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w500, height: 1.1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TodaysScheduleCard extends StatefulWidget {
  final bool isDark;
  
  const TodaysScheduleCard({super.key, required this.isDark});

  @override
  State<TodaysScheduleCard> createState() => _TodaysScheduleCardState();
}

class _TodaysScheduleCardState extends State<TodaysScheduleCard> {
  bool _isLoading = true;
  HomeScheduleData? _scheduleData;
  late ScrollController _scrollController;
  Timer? _cardRefreshTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fetchSchedule();
    // Refresh card UI every second but only rebuild when minute changes
    int lastMinute = DateTime.now().minute;
    _cardRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _scheduleData != null) {
        final currentMinute = DateTime.now().minute;
        if (currentMinute != lastMinute) {
          lastMinute = currentMinute;
          setState(() {}); // Trigger UI update for ongoing/done checks
          _scrollToOngoingClass();
        }
      }
    });
  }

  void _scrollToOngoingClass() {
    if (_scheduleData == null) return;
    int ongoingIndex = -1;
    for (int i = 0; i < _scheduleData!.classes.length; i++) {
      if (_isClassOngoing(_scheduleData!.classes[i])) {
        ongoingIndex = i;
        break;
      }
    }
    if (ongoingIndex > 0 && _scrollController.hasClients) {
      final offset = (ongoingIndex * (220.0 + 12.0));
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _cardRefreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchSchedule() async {
    final data = await HomeScheduleService.getTodaysSchedule();
    if (mounted) {
      setState(() {
        _scheduleData = data;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToOngoingClass();
      });
    }
  }

  int _calculateClassesLeft(List<dynamic> classes) {
    int count = 0;
    final now = DateTime.now();
    for (var c in classes) {
      final endTimeStr = c['endTime']?.toString() ?? '';
      if (endTimeStr.isNotEmpty) {
        final parts = endTimeStr.split(':');
        if (parts.length == 2) {
          final endHour = int.tryParse(parts[0]) ?? 0;
          final endMin = int.tryParse(parts[1]) ?? 0;
          final endDateTime = DateTime(now.year, now.month, now.day, endHour, endMin);
          if (now.isBefore(endDateTime)) {
            count++;
          }
        }
      }
    }
    return count;
  }

  bool _isClassOngoing(dynamic classData) {
    final now = DateTime.now();
    final startTimeStr = classData['startTime']?.toString() ?? '';
    final endTimeStr = classData['endTime']?.toString() ?? '';
    
    if (startTimeStr.isEmpty || endTimeStr.isEmpty) return false;
    
    final sParts = startTimeStr.split(':');
    final eParts = endTimeStr.split(':');
    
    if (sParts.length == 2 && eParts.length == 2) {
      final start = DateTime(now.year, now.month, now.day, int.parse(sParts[0]), int.parse(sParts[1]));
      final end = DateTime(now.year, now.month, now.day, int.parse(eParts[0]), int.parse(eParts[1]));
      return now.isAfter(start) && now.isBefore(end);
    }
    return false;
  }

  bool _isClassDone(dynamic classData) {
    final now = DateTime.now();
    final endTimeStr = classData['endTime']?.toString() ?? '';
    
    if (endTimeStr.isEmpty) return false;
    
    final eParts = endTimeStr.split(':');
    if (eParts.length == 2) {
      final end = DateTime(now.year, now.month, now.day, int.parse(eParts[0]), int.parse(eParts[1]));
      return now.isAfter(end);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isDark 
              ? const [Color(0xFF303030), Color(0xFF1a1a1a)]
              : const [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (widget.isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _isLoading
          ? TodaysScheduleSkeleton(isDark: widget.isDark)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: _buildHeader(),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildCarousel(),
                ),
              ],
            ),
    );
  }

  DateTime? _getNextClassStartTime() {
    final now = DateTime.now();
    DateTime? nextStart;
    
    for (var c in _scheduleData!.classes) {
      final startTimeStr = c['startTime']?.toString() ?? '';
      if (startTimeStr.isNotEmpty) {
        final sParts = startTimeStr.split(':');
        if (sParts.length == 2) {
          final startHour = int.tryParse(sParts[0]) ?? 0;
          final startMin = int.tryParse(sParts[1]) ?? 0;
          final start = DateTime(now.year, now.month, now.day, startHour, startMin);
          if (start.isAfter(now)) {
            if (nextStart == null || start.isBefore(nextStart)) {
              nextStart = start;
            }
          }
        }
      }
    }
    return nextStart;
  }

  Widget _buildHeader() {
    final titleColor = widget.isDark ? Colors.white : Colors.black87;
    final subtitleColor = widget.isDark ? Colors.white70 : Colors.black54;

    if (_scheduleData!.isHoliday) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s schedule',
            style: TextStyle(color: subtitleColor, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Happy Holiday',
            style: TextStyle(color: titleColor, fontSize: 32, fontWeight: FontWeight.bold, height: 1.1),
          ),
          Text(
            _scheduleData!.holidayName ?? 'Enjoy your day!',
            style: TextStyle(color: subtitleColor, fontSize: 16),
          ),
        ],
      );
    }

    if (_scheduleData!.classes.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s schedule',
            style: TextStyle(color: subtitleColor, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'No Classes',
            style: TextStyle(color: titleColor, fontSize: 32, fontWeight: FontWeight.bold, height: 1.1),
          ),
          Text(
            'Enjoy your day!',
            style: TextStyle(color: subtitleColor, fontSize: 16),
          ),
        ],
      );
    }

    final classesLeft = _calculateClassesLeft(_scheduleData!.classes);
    String? ongoingClassEndTime;
    for (var c in _scheduleData!.classes) {
      if (_isClassOngoing(c)) {
        ongoingClassEndTime = c['endTime']?.toString();
        break;
      }
    }

    if (classesLeft == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s schedule',
            style: TextStyle(color: subtitleColor, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'All Classes Done',
            style: TextStyle(color: titleColor, fontSize: 32, fontWeight: FontWeight.bold, height: 1.1),
          ),
          Text(
            'Great job today!',
            style: TextStyle(color: subtitleColor, fontSize: 16),
          ),
        ],
      );
    }

    if (ongoingClassEndTime != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s schedule',
            style: TextStyle(color: subtitleColor, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$classesLeft',
                    style: TextStyle(
                      color: titleColor, 
                      fontSize: 56, 
                      fontWeight: FontWeight.bold, 
                      height: 1.0,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'classes left',
                    style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Spacer(),
              _OngoingTimeIndicator(endTimeStr: ongoingClassEndTime),
            ],
          ),
        ],
      );
    }

    final nextClassStart = _getNextClassStartTime();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s schedule',
          style: TextStyle(color: subtitleColor, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        if (nextClassStart != null)
          _NextClassRotator(
            classesLeft: classesLeft,
            nextClassStart: nextClassStart,
            titleColor: titleColor,
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$classesLeft',
                style: TextStyle(
                  color: titleColor, 
                  fontSize: 56, 
                  fontWeight: FontWeight.bold, 
                  height: 1.0,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'classes left',
                style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildCarousel() {
    if (_scheduleData!.isHoliday || _scheduleData!.classes.isEmpty) {
      return const SizedBox.shrink(); // Hide carousel if holiday or weekend
    }

    final screenWidth = MediaQuery.of(context).size.width;
    // The card is 220px wide, and we want 24px padding on the left.
    // The right padding should push the last card to the left side of the screen.
    final rightPadding = (screenWidth - 24 - 220).clamp(24.0, double.infinity);

    return SizedBox(
      height: 120,
      child: ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.only(left: 24, right: rightPadding),
        scrollDirection: Axis.horizontal,
        itemCount: _scheduleData!.classes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final c = _scheduleData!.classes[index];
          final isOngoing = _isClassOngoing(c);
          final isDone = _isClassDone(c);
          
          final bgColor = isDone 
              ? (widget.isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03))
              : isOngoing 
                  ? (widget.isDark ? Colors.white : Colors.black87)
                  : (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.1);
              
          final borderColor = isDone
              ? Colors.transparent
              : isOngoing 
                  ? Colors.transparent 
                  : (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.2);
              
          final primaryTextColor = isDone
              ? (widget.isDark ? Colors.white38 : Colors.black38)
              : isOngoing 
                  ? (widget.isDark ? Colors.black87 : Colors.white)
                  : (widget.isDark ? Colors.white : Colors.black87);
              
          final secondaryTextColor = isDone
              ? (widget.isDark ? Colors.white24 : Colors.black26)
              : isOngoing 
                  ? (widget.isDark ? Colors.black54 : Colors.white70)
                  : (widget.isDark ? Colors.white70 : Colors.black54);
          
          return Container(
            width: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${c['startTime']} - ${c['endTime']}',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isOngoing)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NOW',
                          style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  c['className']?.toString() ?? 'Unknown',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.location_solid, 
                      size: 14, 
                      color: secondaryTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      c['room']?.toString() ?? 'TBD',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NextClassRotator extends StatefulWidget {
  final int classesLeft;
  final DateTime nextClassStart;
  final Color titleColor;

  const _NextClassRotator({
    required this.classesLeft,
    required this.nextClassStart,
    required this.titleColor,
  });

  @override
  State<_NextClassRotator> createState() => _NextClassRotatorState();
}

class _NextClassRotatorState extends State<_NextClassRotator> {
  Timer? _rotationTimer;
  Timer? _secondTimer;
  bool _showCountdown = false;

  @override
  void initState() {
    super.initState();
    _rotationTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        setState(() {
          _showCountdown = !_showCountdown;
        });
      }
    });
    // Ensure the countdown text updates smoothly every second.
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
       if (mounted && _showCountdown) {
           setState((){}); 
       }
    });
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _secondTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = widget.nextClassStart.difference(now);
    
    // Fallback if we accidentally surpassed the start time
    if (diff.isNegative) {
      _showCountdown = false;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _showCountdown && !diff.isNegative
          ? _buildCountdown(diff)
          : _buildClassesLeft(),
    );
  }

  Widget _buildClassesLeft() {
    return Row(
      key: const ValueKey('classesLeft'),
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${widget.classesLeft}',
          style: TextStyle(
            color: widget.titleColor, 
            fontSize: 56, 
            fontWeight: FontWeight.bold, 
            height: 1.0,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'classes left',
          style: TextStyle(color: widget.titleColor, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildCountdown(Duration diff) {
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    
    String mainNum = '';
    String subText = '';
    
    if (hours > 0) {
      mainNum = '$hours';
      subText = 'hr${hours > 1 ? 's' : ''} ${mins > 0 ? '$mins min${mins > 1 ? 's' : ''}' : ''} till class';
    } else {
      mainNum = '$mins';
      subText = 'min${mins != 1 ? 's' : ''} till class';
    }

    return Row(
      key: const ValueKey('countdown'),
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          mainNum,
          style: TextStyle(
            color: widget.titleColor, 
            fontSize: 56, 
            fontWeight: FontWeight.bold, 
            height: 1.0,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          subText,
          style: TextStyle(color: widget.titleColor, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
