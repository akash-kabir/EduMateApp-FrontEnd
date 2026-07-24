import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/sap_provider.dart';
import '../models/sap/attendance_record.dart';

class SapAttendanceScreen extends StatelessWidget {
  const SapAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sapProvider = Provider.of<SapProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('SapSync Attendance', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => sapProvider.fetchAttendance(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsModal(context, sapProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Dropdown Header
          if (sapProvider.availableSemesters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<SemesterOption>(
                    dropdownColor: Colors.grey[800],
                    value: sapProvider.currentSemester,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    onChanged: (SemesterOption? newValue) {
                      if (newValue != null) {
                        sapProvider.changeSemester(newValue);
                      }
                    },
                    items: sapProvider.availableSemesters.map<DropdownMenuItem<SemesterOption>>((SemesterOption value) {
                      return DropdownMenuItem<SemesterOption>(
                        value: value,
                        child: Text(value.title),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            
          // Error Message
          if (sapProvider.errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                sapProvider.errorMessage,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),

          // Content
          Expanded(
            child: sapProvider.isLoading && sapProvider.attendanceRecords.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : sapProvider.attendanceRecords.isEmpty
                    ? const Center(child: Text('No attendance data available', style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        onRefresh: () => sapProvider.fetchAttendance(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: sapProvider.attendanceRecords.length,
                          itemBuilder: (context, index) {
                            final record = sapProvider.attendanceRecords[index];
                            return _buildAttendanceCard(record);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record) {
    final percentage = record.percentage;
    final color = percentage >= 75 ? Colors.greenAccent : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.subject,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Present: ${record.presentClasses} / ${record.totalClasses}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 60,
                width: 60,
                child: CircularProgressIndicator(
                  value: record.totalClasses == 0 ? 0 : record.presentClasses / record.totalClasses,
                  backgroundColor: Colors.grey[700],
                  color: color,
                  strokeWidth: 6,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _showSettingsModal(BuildContext context, SapProvider sapProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Colors.grey[850],
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
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
