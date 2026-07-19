import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

class ScheduleClassCard extends StatelessWidget {
  final Map<String, dynamic> classPeriod;
  final bool isDark;
  final bool isOngoing;
  final bool isPassed;
  final int classCount;
  final bool isHoliday;

  const ScheduleClassCard({
    super.key,
    required this.classPeriod,
    required this.isDark,
    required this.isOngoing,
    required this.isPassed,
    required this.classCount,
    this.isHoliday = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool effectivelyPassed = isPassed || isHoliday;
    final bool effectivelyOngoing = isOngoing && !isHoliday;

    final Color accentColor;
    if (effectivelyOngoing) {
      accentColor = CupertinoColors.systemGreen;
    } else if (effectivelyPassed) {
      accentColor = isDark ? Colors.grey[700]! : Colors.grey[400]!;
    } else {
      accentColor = AuthPalette.coral;
    }

    final double cardOpacity = effectivelyPassed ? 0.4 : 1.0;

    // Base decoration
    final BoxDecoration cardDecoration;
    if (effectivelyOngoing) {
      cardDecoration = BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F3E28), // Deep green
            Color(0xFF1B6A45), // Lighter emerald green
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Color(0xFF10B981), width: 5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.25),
            blurRadius: 18.0,
            spreadRadius: 2.0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12.0,
            offset: const Offset(0, 6),
          ),
        ],
      );
    } else {
      cardDecoration = BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E23).withValues(alpha: 0.40)
            : Colors.grey[200]!.withValues(alpha: 0.65), // Translucent charcoal glass
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }

    return Opacity(
      opacity: cardOpacity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnimatedScale(
          scale: effectivelyOngoing ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: effectivelyOngoing ? 0.0 : 10.0,
              sigmaY: effectivelyOngoing ? 0.0 : 10.0,
            ),
            child: Container(
              decoration: cardDecoration,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${classPeriod['startTime']} - ${classPeriod['endTime']}${classCount > 1 ? ' (${classCount}h)' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: effectivelyOngoing
                              ? Colors.white
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          classPeriod['className'],
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: effectivelyOngoing ? Colors.white : (isDark ? Colors.white : Colors.black),
                          ),
                        ),
                      ),
                      if (classPeriod['room'] != null &&
                          (classPeriod['room'] as String).isNotEmpty &&
                          classPeriod['room'] != '—')
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.location_solid,
                              size: 14,
                              color: effectivelyOngoing
                                  ? Colors.white70
                                  : (isDark ? Colors.grey[500] : Colors.grey[500]),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              classPeriod['room'],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: effectivelyOngoing
                                    ? Colors.white
                                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (classPeriod['isElective'] == true) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AuthPalette.coral.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AuthPalette.coral.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'Elective',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AuthPalette.coral,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}
