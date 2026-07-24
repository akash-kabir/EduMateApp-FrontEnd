import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../provider/sap_provider.dart';
import '../models/sap/attendance_record.dart';
import '../widgets/radial_segment_chart.dart';
import '../widgets/sleek_attendance_card.dart';
import '../widgets/sap_hero_visualization.dart';

class SapAttendanceScreen extends StatefulWidget {
  const SapAttendanceScreen({super.key});

  @override
  State<SapAttendanceScreen> createState() => _SapAttendanceScreenState();
}

class _SapAttendanceScreenState extends State<SapAttendanceScreen> {
  int? _selectedIndex;
  SapHeroStyle _heroStyle = SapHeroStyle.bentoGrid;

  @override
  Widget build(BuildContext context) {
    final sapProvider = Provider.of<SapProvider>(context);
    final records = sapProvider.attendanceRecords;
    final overallPct = sapProvider.overallPercentage;

    return Scaffold(
      backgroundColor: const Color(0xFF121417),
      appBar: AppBar(
        title: const Text(
          'SapSync Attendance',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showSettingsModal(context, sapProvider),
            tooltip: 'SapSync Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Error Banner (if any)
          if (sapProvider.errorMessage.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
              ),
              child: Text(
                sapProvider.errorMessage,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),

          // 2. Main Content
          Expanded(
            child: sapProvider.isLoading && records.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4CD97B),
                    ),
                  )
                : records.isEmpty
                    ? const Center(
                        child: Text(
                          'No attendance data available.\nTap refresh to sync.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF4CD97B),
                        backgroundColor: const Color(0xFF1C1C1E),
                        onRefresh: () => sapProvider.fetchAttendance(),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          children: [
                            // Hero Visualization Header (4 Switchable Modes)
                            SapHeroVisualization(
                              records: records,
                              overallPercentage: overallPct,
                              totalPresent: sapProvider.totalPresentClasses,
                              totalClasses: sapProvider.totalClassesCount,
                              threshold: sapProvider.attendanceThreshold,
                              selectedIndex: _selectedIndex,
                              onSegmentSelected: (index) {
                                setState(() {
                                  _selectedIndex = _selectedIndex == index ? null : index;
                                });
                              },
                              activeStyle: _heroStyle,
                              onStyleChanged: (newStyle) {
                                setState(() {
                                  _heroStyle = newStyle;
                                });
                              },
                            ),
                            const SizedBox(height: 20),

                            // Section Title
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Subject Attendance',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  '${records.length} Subjects',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Subject List Cards
                            ...List.generate(records.length, (index) {
                              final record = records[index];
                              final isSelected = _selectedIndex == index;
                              return SleekAttendanceCard(
                                record: record,
                                isSelected: isSelected,
                                threshold: sapProvider.attendanceThreshold,
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = isSelected ? null : index;
                                  });
                                },
                              );
                            }),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _formatAcademicYear(String rawTitle, String userId) {
    if (rawTitle.isEmpty) return 'Not configured';
    final yearMatch = RegExp(r'(\d{4})-\d{4}').firstMatch(rawTitle);
    if (yearMatch != null) {
      final startYear = int.tryParse(yearMatch.group(1)!) ?? 2024;
      int studentStartYear = 2024;
      if (userId.length >= 2) {
        final prefix = int.tryParse(userId.substring(0, 2));
        if (prefix != null && prefix >= 15 && prefix <= 30) {
          studentStartYear = 2000 + prefix;
        }
      }
      final yearDiff = startYear - studentStartYear + 1;
      String yearName = '1st Year';
      if (yearDiff == 2) yearName = '2nd Year';
      else if (yearDiff == 3) yearName = '3rd Year';
      else if (yearDiff >= 4) yearName = '4th Year';

      final isSpring = rawTitle.toLowerCase().contains('spring');
      final sessionName = isSpring ? 'Spring Session' : 'Autumn Session';
      return '$yearName • $sessionName';
    }
    return rawTitle;
  }

  List<Map<String, String>> _getTermOptions(String userId) {
    int studentStartYear = 2024;
    if (userId.length >= 2) {
      final prefix = int.tryParse(userId.substring(0, 2));
      if (prefix != null && prefix >= 15 && prefix <= 35) {
        studentStartYear = 2000 + prefix;
      }
    }

    return [
      {'label': '1st Year', 'year': '$studentStartYear-${studentStartYear + 1}'},
      {'label': '2nd Year', 'year': '${studentStartYear + 1}-${studentStartYear + 2}'},
      {'label': '3rd Year', 'year': '${studentStartYear + 2}-${studentStartYear + 3}'},
      {'label': '4th Year', 'year': '${studentStartYear + 3}-${studentStartYear + 4}'},
    ];
  }

  void _showSettingsModal(BuildContext context, SapProvider sapProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16181F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'SapSync Settings',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // 1. Sync Attendance Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  sapProvider.fetchAttendance();
                },
                icon: const Icon(Icons.refresh, color: Colors.black),
                label: const Text(
                  'Sync / Refresh Attendance',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CD97B),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Term & Session Switcher Card with Cupertino Sliding Segmented Controls
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Academic Term', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoSlidingSegmentedControl<String>(
                        groupValue: sapProvider.termYear.isEmpty
                            ? _getTermOptions(sapProvider.sapUserId).first['year']
                            : sapProvider.termYear,
                        backgroundColor: const Color(0xFF2C2C2E),
                        thumbColor: const Color(0xFF4CD97B),
                        children: Map.fromEntries(
                          _getTermOptions(sapProvider.sapUserId).map((opt) {
                            final isSel = sapProvider.termYear == opt['year'] ||
                                (sapProvider.termYear.isEmpty && opt == _getTermOptions(sapProvider.sapUserId).first);
                            return MapEntry(
                              opt['year']!,
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  opt['label']!,
                                  style: TextStyle(
                                    color: isSel ? Colors.black : Colors.grey[300],
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        onValueChanged: (val) {
                          if (val != null) {
                            sapProvider.updateSession(
                              val,
                              sapProvider.sessionKey.isEmpty ? 'Autumn' : sapProvider.sessionKey,
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Session', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoSlidingSegmentedControl<String>(
                        groupValue: sapProvider.sessionKey.toLowerCase() == 'spring' ? 'Spring' : 'Autumn',
                        backgroundColor: const Color(0xFF2C2C2E),
                        thumbColor: const Color(0xFF4CD97B),
                        children: {
                          'Autumn': Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Autumn Session',
                              style: TextStyle(
                                color: sapProvider.sessionKey.toLowerCase() != 'spring' ? Colors.black : Colors.grey[300],
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          'Spring': Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Spring Session',
                              style: TextStyle(
                                color: sapProvider.sessionKey.toLowerCase() == 'spring' ? Colors.black : Colors.grey[300],
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        },
                        onValueChanged: (val) {
                          if (val != null) {
                            final curYear = sapProvider.termYear.isEmpty
                                ? _getTermOptions(sapProvider.sapUserId).first['year']!
                                : sapProvider.termYear;
                            sapProvider.updateSession(curYear, val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Attendance Threshold Setting Slider
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Attendance Threshold', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            Text(
                              '${sapProvider.attendanceThreshold.toInt()}%',
                              style: const TextStyle(color: Color(0xFF4CD97B), fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: const Color(0xFF4CD97B),
                            inactiveTrackColor: Colors.grey[800],
                            thumbColor: const Color(0xFF4CD97B),
                            overlayColor: const Color(0xFF4CD97B).withOpacity(0.2),
                            valueIndicatorColor: const Color(0xFF4CD97B),
                            valueIndicatorTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                          child: Slider(
                            value: sapProvider.attendanceThreshold,
                            min: 0.0,
                            max: 100.0,
                            divisions: 100,
                            label: '${sapProvider.attendanceThreshold.toInt()}%',
                            onChanged: (val) {
                              setModalState(() {});
                              sapProvider.setAttendanceThreshold(val);
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('0%', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            Text('75% (Target)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            Text('100%', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Disconnect SapSync Button
              ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1C1C1E),
                      title: const Text('Disconnect SapSync?', style: TextStyle(color: Colors.white)),
                      content: const Text(
                        'This will remove your stored SAP credentials and clear all local attendance data for SapSync. Your main EduMate account will not be affected.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Disconnect', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    Navigator.pop(context); // Close bottom sheet
                    await sapProvider.logout(); // Purge SapSync credentials and cache
                    if (context.mounted) {
                      Navigator.pop(context); // Return to Home Screen
                    }
                  }
                },
                icon: const Icon(Icons.link_off, color: Colors.white),
                label: const Text('Disconnect SapSync', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5252),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
