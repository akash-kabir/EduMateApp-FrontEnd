import 'package:flutter/material.dart';
import 'package:app/features/sapsync/models/attendance_record.dart';

class SapHeroVisualization extends StatelessWidget {
  final List<AttendanceRecord> records;
  final double overallPercentage;
  final int totalPresent;
  final int totalClasses;
  final double threshold;

  const SapHeroVisualization({
    super.key,
    required this.records,
    required this.overallPercentage,
    required this.totalPresent,
    required this.totalClasses,
    required this.threshold,
  });

  Color _getRecordColor(double pct) {
    if (pct >= threshold) {
      return const Color(0xFF4CD97B);
    } else if (pct >= threshold - 10) {
      return Colors.amberAccent;
    } else {
      return const Color(0xFFFF5252);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeCount = records.where((r) => r.percentage >= threshold).length;
    final riskCount = records.length - safeCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E222B), Color(0xFF16181F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Overall %
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${overallPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: _getRecordColor(overallPercentage),
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'OVERALL',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Attended Classes & Status Cards
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Attended', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      Text(
                        '$totalPresent / $totalClasses',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      Row(
                        children: [
                          Text('$safeCount Safe', style: const TextStyle(color: Color(0xFF4CD97B), fontSize: 12, fontWeight: FontWeight.bold)),
                          if (riskCount > 0) ...[
                            const Text(' | ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text('$riskCount Risk', style: const TextStyle(color: Color(0xFFFF5252), fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
