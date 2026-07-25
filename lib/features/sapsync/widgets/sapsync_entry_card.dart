import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/features/sapsync/screens/sap_setup_screen.dart';
import 'package:app/features/sapsync/screens/sap_attendance_screen.dart';
import 'package:app/features/sapsync/provider/sap_provider.dart';

class SapSyncEntryCard extends StatelessWidget {
  const SapSyncEntryCard({super.key});

  String _getAbbreviation(String subject) {
    final clean = subject.trim();
    if (clean.isEmpty) return '';
    
    // Extract capital letters from subject (e.g. Data Mining and Data Warehousing -> DMDW)
    final uppercaseLetters = RegExp(r'[A-Z]').allMatches(clean).map((m) => m.group(0)!).join();
    if (uppercaseLetters.length >= 2) {
      return uppercaseLetters.length > 5 ? uppercaseLetters.substring(0, 5) : uppercaseLetters;
    }

    // Fallback if title doesn't contain multiple capital letters
    final words = clean.split(RegExp(r'\s+'));
    if (words.length > 1) {
      final abbr = words.map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
      return abbr.length > 4 ? abbr.substring(0, 4) : abbr;
    }
    return clean.length > 4 ? clean.substring(0, 4).toUpperCase() : clean.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final sapProvider = Provider.of<SapProvider>(context);
    final isConnected = sapProvider.isConnected;
    final records = sapProvider.attendanceRecords;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => isConnected 
                ? const SapAttendanceScreen() 
                : const SapSetupScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: isConnected
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Title & Total Classes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Attendance',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${sapProvider.totalPresentClasses}/${sapProvider.totalClassesCount} Classes',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            CupertinoIcons.chevron_right,
                            color: Colors.grey,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Equalizer Columns for Subjects (Horizontal Scrollable, 125px Height, 25px Width)
                  if (records.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 125,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(records.length, (index) {
                            final rec = records[index];
                            final pct = rec.percentage;
                            final threshold = sapProvider.attendanceThreshold;
                            final col = pct >= threshold
                                ? const Color(0xFF4CD97B)
                                : pct >= threshold - 10
                                    ? Colors.amberAccent
                                    : const Color(0xFFFF5252);
                            final abbr = _getAbbreviation(rec.subject);
                            final barHeight = (pct / 100.0 * 80.0).clamp(14.0, 80.0);

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${pct.toInt()}%',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 25,
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [col, col.withValues(alpha: 0.5)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    abbr,
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SAPSYNC',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to setup',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sync_lock,
                      color: Colors.blueAccent,
                      size: 28,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
