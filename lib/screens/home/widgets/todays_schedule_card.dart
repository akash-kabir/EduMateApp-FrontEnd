import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/home_schedule_service.dart';

class TodaysScheduleCard extends StatefulWidget {
  final bool isDark;
  
  const TodaysScheduleCard({super.key, required this.isDark});

  @override
  State<TodaysScheduleCard> createState() => _TodaysScheduleCardState();
}

class _TodaysScheduleCardState extends State<TodaysScheduleCard> {
  bool _isLoading = true;
  HomeScheduleData? _scheduleData;

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    final data = await HomeScheduleService.getTodaysSchedule();
    if (mounted) {
      setState(() {
        _scheduleData = data;
        _isLoading = false;
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
          ? Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(child: CupertinoActivityIndicator(color: widget.isDark ? Colors.white : Colors.black54)),
            )
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s schedule',
          style: TextStyle(color: subtitleColor, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
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

    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: _scheduleData!.classes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final c = _scheduleData!.classes[index];
          final isOngoing = _isClassOngoing(c);
          final isDone = _isClassDone(c);
          
          final bgColor = isOngoing 
              ? (widget.isDark ? Colors.white : Colors.black87)
              : (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.1);
              
          final borderColor = isOngoing 
              ? Colors.transparent 
              : (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.2);
              
          final primaryTextColor = isOngoing 
              ? (widget.isDark ? Colors.black87 : Colors.white)
              : (widget.isDark ? Colors.white : Colors.black87);
              
          final secondaryTextColor = isOngoing 
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
                        decoration: isDone ? TextDecoration.lineThrough : null,
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
                    decoration: isDone ? TextDecoration.lineThrough : null,
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
