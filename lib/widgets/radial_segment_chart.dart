import 'dart:math';
import 'package:flutter/material.dart';
import '../models/sap/attendance_record.dart';

class RadialSegmentChart extends StatelessWidget {
  final List<AttendanceRecord> records;
  final double overallPercentage;
  final int? selectedIndex;
  final ValueChanged<int>? onSegmentSelected;

  const RadialSegmentChart({
    super.key,
    required this.records,
    required this.overallPercentage,
    this.selectedIndex,
    this.onSegmentSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartSize = min(constraints.maxWidth, 220.0);
        return SizedBox(
          width: chartSize,
          height: chartSize,
          child: GestureDetector(
            onTapUp: (details) {
              if (records.isEmpty || onSegmentSelected == null) return;
              final center = Offset(chartSize / 2, chartSize / 2);
              final touchPos = details.localPosition - center;
              var angle = atan2(touchPos.dy, touchPos.dx);
              // Normalize angle starting from top (-pi/2)
              angle = (angle + pi / 2) % (2 * pi);
              if (angle < 0) angle += 2 * pi;

              final segmentAngle = (2 * pi) / records.length;
              final index = (angle / segmentAngle).floor() % records.length;
              onSegmentSelected!(index);
            },
            child: CustomPaint(
              painter: _RadialChartPainter(
                records: records,
                selectedIndex: selectedIndex,
              ),
              child: Center(
                child: Container(
                  width: chartSize * 0.44,
                  height: chartSize * 0.44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161618),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${overallPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: overallPercentage >= 75
                              ? const Color(0xFF4CD97B)
                              : const Color(0xFFFF5252),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'OVERALL',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RadialChartPainter extends CustomPainter {
  final List<AttendanceRecord> records;
  final int? selectedIndex;

  _RadialChartPainter({
    required this.records,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 4;
    final innerRadius = outerRadius * 0.46;
    final totalSegments = records.length;
    final anglePerSegment = (2 * pi) / totalSegments;
    const gapAngle = 0.08; // Radial gap between petals in radians

    for (int i = 0; i < totalSegments; i++) {
      final record = records[i];
      final pct = (record.percentage / 100.0).clamp(0.0, 1.0);
      final isSelected = selectedIndex == i;

      final startAngle = -pi / 2 + i * anglePerSegment + gapAngle / 2;
      final sweepAngle = anglePerSegment - gapAngle;

      final isHigh = record.percentage >= 75;
      final baseColor = isHigh ? const Color(0xFF4CD97B) : const Color(0xFFFF5252);
      final darkTrackColor = const Color(0xFF2C2C2E).withOpacity(0.6);

      // 1. Draw Outer Track Arc (Total Capacity)
      final trackPaint = Paint()
        ..color = isSelected ? darkTrackColor.withOpacity(0.9) : darkTrackColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      final trackPath = _createSegmentPath(
        center: center,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        startAngle: startAngle,
        sweepAngle: sweepAngle,
      );
      canvas.drawPath(trackPath, trackPaint);

      // 2. Draw Inner Filled Arc (Actual Attendance %)
      final filledOuterRadius = innerRadius + (outerRadius - innerRadius) * pct;
      final fillPaint = Paint()
        ..color = isSelected ? baseColor : baseColor.withOpacity(0.85)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      final fillPath = _createSegmentPath(
        center: center,
        innerRadius: innerRadius,
        outerRadius: filledOuterRadius,
        startAngle: startAngle,
        sweepAngle: sweepAngle,
      );
      canvas.drawPath(fillPath, fillPaint);

      // 3. Highlight border if selected
      if (isSelected) {
        final borderPaint = Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..isAntiAlias = true;
        canvas.drawPath(trackPath, borderPaint);
      }
    }
  }

  Path _createSegmentPath({
    required Offset center,
    required double innerRadius,
    required double outerRadius,
    required double startAngle,
    required double sweepAngle,
  }) {
    final path = Path();

    final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);

    path.arcTo(outerRect, startAngle, sweepAngle, false);
    path.lineTo(
      center.dx + innerRadius * cos(startAngle + sweepAngle),
      center.dy + innerRadius * sin(startAngle + sweepAngle),
    );
    path.arcTo(innerRect, startAngle + sweepAngle, -sweepAngle, false);
    path.lineTo(
      center.dx + outerRadius * cos(startAngle),
      center.dy + outerRadius * sin(startAngle),
    );
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(covariant _RadialChartPainter oldDelegate) {
    return oldDelegate.records != records || oldDelegate.selectedIndex != selectedIndex;
  }
}
