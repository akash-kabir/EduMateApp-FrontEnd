import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

class WeekCalendarGrid extends StatelessWidget {
  final List<DateTime> weekDates;
  final DateTime selectedDate;
  final DateTime now;
  final bool isDark;
  final Function(DateTime selectedDate, bool slideFromRight) onDateSelected;

  const WeekCalendarGrid({
    super.key,
    required this.weekDates,
    required this.selectedDate,
    required this.now,
    required this.isDark,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6 (skip Sun=0)
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final weekdayIndices = [1, 2, 3, 4, 5, 6]; // Mon-Sat in weekDates list

    final selectedIndex = weekDates.indexWhere(
      (date) =>
          date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day,
    );

    return Container(
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AuthPalette.coral.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (i) {
          final dateIndex = weekdayIndices[i];
          final isSelected = dateIndex == selectedIndex;
          final date = weekDates[dateIndex];
          final isToday =
              date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;

          return GestureDetector(
            onTap: () {
              final slideFromRight = dateIndex > selectedIndex;
              onDateSelected(weekDates[dateIndex], slideFromRight);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: 48,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AuthPalette.coral : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isToday && !isSelected
                      ? AuthPalette.coral.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Text(
                dayLabels[i],
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.grey[300] : Colors.grey[700]),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
