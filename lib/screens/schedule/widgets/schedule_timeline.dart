import 'package:flutter/material.dart';
import 'schedule_class_card.dart';

class ScheduleTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> mergedClasses;
  final bool isDark;
  final bool Function(String, String) isOngoing;
  final bool Function(String) isPassed;

  const ScheduleTimeline({
    super.key,
    required this.mergedClasses,
    required this.isDark,
    required this.isOngoing,
    required this.isPassed,
  });

  @override
  Widget build(BuildContext context) {
    if (mergedClasses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'No classes scheduled for this day',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time Column
          SizedBox(
            width: 70,
            child: _buildTimeColumn(mergedClasses, isDark),
          ),
          // Timeline Divider with dots
          Container(
            width: 20,
            margin: const EdgeInsets.only(right: 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Vertical Line
                Container(
                  width: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        if (isDark)
                          const Color(0xFF2D2D35).withValues(alpha: 0.1)
                        else
                          Colors.grey[300]!.withValues(alpha: 0.1),
                        if (isDark)
                          const Color(0xFF2D2D35)
                        else
                          Colors.grey[300]!,
                        if (isDark)
                          const Color(0xFF2D2D35)
                        else
                          Colors.grey[300]!,
                        if (isDark)
                          const Color(0xFF2D2D35).withValues(alpha: 0.1)
                        else
                          Colors.grey[300]!.withValues(alpha: 0.1),
                      ],
                      stops: const [0.0, 0.1, 0.9, 1.0],
                    ),
                  ),
                ),
                // Render Dots
                ...List.generate(mergedClasses.length, (index) {
                  final classPeriod = mergedClasses[index];
                  final ongoing = isOngoing(classPeriod['startTime'], classPeriod['endTime']);
                  final passed = isPassed(classPeriod['endTime']);

                  return Positioned(
                    top: (index * 130.0) + 45.0, // Approximate center of card
                    child: Container(
                      width: ongoing ? 12 : 8,
                      height: ongoing ? 12 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ongoing
                            ? const Color(0xFF10B981)
                            : (passed
                                ? (isDark ? Colors.grey[600] : Colors.grey[400])
                                : (isDark ? Colors.white : Colors.black87)),
                        border: Border.all(
                          color: isDark ? const Color(0xFF111111) : Colors.white,
                          width: 2,
                        ),
                        boxShadow: ongoing
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // Class Cards
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(mergedClasses.length, (index) {
                final classPeriod = mergedClasses[index];
                final ongoing = isOngoing(classPeriod['startTime'], classPeriod['endTime']);
                final passed = isPassed(classPeriod['endTime']);

                return Container(
                  constraints: const BoxConstraints(minHeight: 130),
                  child: ScheduleClassCard(
                    classPeriod: classPeriod,
                    isDark: isDark,
                    isOngoing: ongoing,
                    isPassed: passed,
                    classCount: classPeriod['count'] as int,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(List<Map<String, dynamic>> classesList, bool isDark) {
    return Column(
      children: List.generate(classesList.length, (index) {
        final cp = classesList[index];
        final ongoing = isOngoing(cp['startTime'], cp['endTime']);
        final passed = isPassed(cp['endTime']);

        return Container(
          height: 130, // Fixed height to match cards
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                cp['startTime'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: ongoing ? FontWeight.bold : FontWeight.w600,
                  color: ongoing
                      ? const Color(0xFF10B981)
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cp['endTime'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: passed
                      ? (isDark ? Colors.grey[700] : Colors.grey[400])
                      : (isDark ? Colors.grey[500] : Colors.grey[600]),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
