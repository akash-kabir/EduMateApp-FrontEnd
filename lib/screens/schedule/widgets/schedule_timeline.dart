import 'package:flutter/material.dart';
import 'schedule_class_card.dart';

class ScheduleTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> mergedClasses;
  final bool isDark;
  final bool Function(String, String) isOngoing;
  final bool Function(String) isPassed;
  final bool isHoliday;
  final String emptyMessage;

  const ScheduleTimeline({
    super.key,
    required this.mergedClasses,
    required this.isDark,
    required this.isOngoing,
    required this.isPassed,
    this.isHoliday = false,
    this.emptyMessage = 'No classes scheduled for this day',
  });

  @override
  Widget build(BuildContext context) {
    if (mergedClasses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(mergedClasses.length, (index) {
        final classPeriod = mergedClasses[index];
        final ongoing = isOngoing(classPeriod['startTime'], classPeriod['endTime']);
        final passed = isPassed(classPeriod['endTime']);

        return ScheduleClassCard(
          classPeriod: classPeriod,
          isDark: isDark,
          isOngoing: ongoing,
          isPassed: passed,
          classCount: classPeriod['count'] as int,
          isHoliday: isHoliday,
        );
      }),
    );
  }
}
