import 'package:flutter/material.dart';
import 'package:app/features/sapsync/models/attendance_record.dart';

class SleekAttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  final bool isSelected;
  final double threshold;
  final VoidCallback? onTap;

  const SleekAttendanceCard({
    super.key,
    required this.record,
    this.isSelected = false,
    this.threshold = 75.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = record.percentage;
    final isHigh = percentage >= threshold;
    final accentColor = isHigh ? const Color(0xFF4CD97B) : const Color(0xFFFF5252);
    final gradientColors = isHigh
        ? [const Color(0xFF4CD97B), const Color(0xFF00B894)]
        : [const Color(0xFFFF5252), const Color(0xFFFF7675)];

    final pctFactor = (percentage / 100.0).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 14),
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? accentColor.withOpacity(0.6) : Colors.white.withOpacity(0.06),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Card Content (Padded)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Row: Subject Title
                  Text(
                    record.subject,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),

                  // 2. Middle Row: Pill Progress Bar with Threshold Marker
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = constraints.maxWidth;
                      final markerLeft = (barWidth * (threshold / 100.0)).clamp(0.0, barWidth - 3);

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: pctFactor,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: gradientColors,
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withOpacity(0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Threshold Split Line Indicator
                          Positioned(
                            left: markerLeft,
                            top: -3,
                            child: Container(
                              width: 3,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.amberAccent,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amberAccent.withOpacity(0.8),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. Bottom Row: Left Meta (Attended n/m & Faculty) + Right Large % Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Left Column: Attended & Faculty
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attended: ${record.presentClasses} / ${record.totalClasses}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Faculty: ${record.facultyName ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),

                      // Right Column: Large Bold Percentage Number
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 4. Expanded Calculation Section (With Subtle Inner Margins)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              child: isSelected
                  ? Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141416),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          // Left Side: Attend Next vs Skip Next Simulations
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4CD97B),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Attend next: ${record.simulateAttendNext().toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF5252),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Skip next: ${record.simulateSkipNext().toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Vertical Separator Line
                          Container(
                            height: 34,
                            width: 1,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          const SizedBox(width: 14),

                          // Right Side: Target Calculator [X] Classes to Attend / Skip
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                isHigh ? 'Skip' : 'Attend',
                                style: TextStyle(
                                  color: isHigh ? const Color(0xFF4CD97B) : const Color(0xFFFF5252),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '${isHigh ? record.classesAllowedToSkip(threshold) : record.classesNeededToReach(threshold)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Classes',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
