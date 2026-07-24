import 'package:flutter/material.dart';
import '../models/sap/attendance_record.dart';

enum SapHeroStyle {
  segmentedBar,
  equalizerColumns,
  bentoGrid,
  chipsCarousel,
}

class SapHeroVisualization extends StatelessWidget {
  final List<AttendanceRecord> records;
  final double overallPercentage;
  final int totalPresent;
  final int totalClasses;
  final double threshold;
  final int? selectedIndex;
  final ValueChanged<int>? onSegmentSelected;
  final SapHeroStyle activeStyle;
  final ValueChanged<SapHeroStyle>? onStyleChanged;

  const SapHeroVisualization({
    super.key,
    required this.records,
    required this.overallPercentage,
    required this.totalPresent,
    required this.totalClasses,
    required this.threshold,
    this.selectedIndex,
    this.onSegmentSelected,
    this.activeStyle = SapHeroStyle.bentoGrid,
    this.onStyleChanged,
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

  String _getAbbreviation(String subject) {
    final clean = subject.trim();
    if (clean.length <= 4) return clean.toUpperCase();
    final words = clean.split(RegExp(r'\s+'));
    if (words.length > 1) {
      final abbr = words.map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
      return abbr.length > 5 ? abbr.substring(0, 5) : abbr;
    }
    return clean.substring(0, 4).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
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
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: _buildBentoGridStyle(),
    );
  }

  String _getStyleName(SapHeroStyle style) {
    switch (style) {
      case SapHeroStyle.segmentedBar:
        return 'Segmented Bar';
      case SapHeroStyle.equalizerColumns:
        return 'Equalizer';
      case SapHeroStyle.bentoGrid:
        return 'Bento Grid';
      case SapHeroStyle.chipsCarousel:
        return 'Chips Hub';
    }
  }

  PopupMenuItem<SapHeroStyle> _buildMenuItem(SapHeroStyle style, String title) {
    final isSelected = activeStyle == style;
    return PopupMenuItem<SapHeroStyle>(
      value: style,
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF4CD97B) : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildActiveStyleContent() {
    switch (activeStyle) {
      case SapHeroStyle.segmentedBar:
        return _buildSegmentedBarStyle();
      case SapHeroStyle.equalizerColumns:
        return _buildEqualizerColumnsStyle();
      case SapHeroStyle.bentoGrid:
        return _buildBentoGridStyle();
      case SapHeroStyle.chipsCarousel:
        return _buildChipsCarouselStyle();
    }
  }

  // ================= STYLE 1: SEGMENTED MULTI-COLOR PROGRESS BAR =================
  Widget _buildSegmentedBarStyle() {
    return Column(
      key: const ValueKey('segmentedBar'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${overallPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                ),
                Text(
                  'Overall Attendance',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
            Text(
              '$totalPresent / $totalClasses Classes',
              style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Multi-color Segmented Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 12,
            width: double.infinity,
            color: const Color(0xFF2C2C2E),
            child: Row(
              children: records.isEmpty
                  ? []
                  : List.generate(records.length, (index) {
                      final rec = records[index];
                      final isSel = selectedIndex == index;
                      final col = _getRecordColor(rec.percentage);

                      return Expanded(
                        flex: rec.totalClasses > 0 ? rec.totalClasses : 1,
                        child: GestureDetector(
                          onTap: () => onSegmentSelected?.call(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 1.0),
                            decoration: BoxDecoration(
                              color: isSel ? Colors.white : col,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: isSel
                                  ? [
                                      BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 6),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      );
                    }),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Subject Chip Legends
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(records.length, (index) {
            final rec = records[index];
            final isSel = selectedIndex == index;
            final abbr = _getAbbreviation(rec.subject);
            final col = _getRecordColor(rec.percentage);

            return GestureDetector(
              onTap: () => onSegmentSelected?.call(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSel ? col.withOpacity(0.3) : const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSel ? col : Colors.white.withOpacity(0.06),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      abbr,
                      style: TextStyle(
                        color: isSel ? Colors.white : Colors.grey[400],
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ================= STYLE 2: EQUALIZER COLUMNS (VERTICAL BARS) =================
  Widget _buildEqualizerColumnsStyle() {
    return Column(
      key: const ValueKey('equalizerColumns'),
      children: [
        SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(records.length, (index) {
              final rec = records[index];
              final isSel = selectedIndex == index;
              final pct = rec.percentage;
              final col = _getRecordColor(pct);
              final abbr = _getAbbreviation(rec.subject);
              final barHeight = (pct / 100.0 * 70.0).clamp(12.0, 70.0);

              return GestureDetector(
                onTap: () => onSegmentSelected?.call(index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${pct.toInt()}%',
                      style: TextStyle(
                        color: isSel ? Colors.white : Colors.grey[400],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 18,
                      height: barHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [col, col.withOpacity(0.6)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: isSel ? Border.all(color: Colors.white, width: 1.5) : null,
                        boxShadow: isSel
                            ? [BoxShadow(color: col.withOpacity(0.6), blurRadius: 6)]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      abbr,
                      style: TextStyle(
                        color: isSel ? Colors.white : Colors.grey[500],
                        fontSize: 10,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Overall: ${overallPercentage.toStringAsFixed(1)}% ($totalPresent/$totalClasses classes)',
          style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ================= STYLE 3: BENTO METRICS GRID =================
  Widget _buildBentoGridStyle() {
    final safeCount = records.where((r) => r.percentage >= threshold).length;
    final riskCount = records.length - safeCount;

    return Column(
      key: const ValueKey('bentoGrid'),
      children: [
        Row(
          children: [
            // Overall % (Clean Direct Display)
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

            // Classes & Status Cards
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
      ],
    );
  }

  // ================= STYLE 4: INTERACTIVE CHIPS CAROUSEL =================
  Widget _buildChipsCarouselStyle() {
    return Column(
      key: const ValueKey('chipsCarousel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${overallPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text('Total: $totalPresent/$totalClasses classes', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (overallPercentage >= threshold ? const Color(0xFF4CD97B) : const Color(0xFFFF5252)).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Target: ${threshold.toInt()}%',
                style: TextStyle(
                  color: overallPercentage >= threshold ? const Color(0xFF4CD97B) : const Color(0xFFFF5252),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Scrollable Horizontal Chip Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(records.length, (index) {
              final rec = records[index];
              final isSel = selectedIndex == index;
              final col = _getRecordColor(rec.percentage);
              final abbr = _getAbbreviation(rec.subject);

              return GestureDetector(
                onTap: () => onSegmentSelected?.call(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel ? col : const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSel ? Colors.white : Colors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        abbr,
                        style: TextStyle(
                          color: isSel ? Colors.black : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSel ? Colors.black.withOpacity(0.2) : col.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${rec.percentage.toInt()}%',
                          style: TextStyle(
                            color: isSel ? Colors.white : col,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
