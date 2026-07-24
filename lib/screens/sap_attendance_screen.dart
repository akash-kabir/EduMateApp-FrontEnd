import 'package:flutter/material.dart';
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
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => sapProvider.fetchAttendance(),
            tooltip: 'Sync Attendance',
          ),
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

              // Active Session Info
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
                    Text('Active Session', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      sapProvider.currentSemester?.title ?? 'Not configured',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
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
                            min: 60.0,
                            max: 90.0,
                            divisions: 6,
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
                            Text('60%', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            Text('75% (Target)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            Text('90%', style: TextStyle(color: Colors.grey, fontSize: 11)),
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
