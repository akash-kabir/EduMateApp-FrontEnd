import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:app/shared/config.dart';
import 'package:app/shared/widgets/dialogs/toast_manager.dart';
import 'package:app/features/admin/schedule/schedule_editor_screen.dart';

class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() =>
      _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  bool _isLoading = true;
  Map<int, dynamic> _schedules = {};
  String _selectedSeason = 'Autumn';

  List<int> get _displayedSemesters =>
      _selectedSeason == 'Autumn' ? [1, 3, 5, 7] : [2, 4, 6, 8];

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
            '${Config.scheduleBaseEndpoint}?t=${DateTime.now().millisecondsSinceEpoch}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['data'] as List;

        final Map<int, dynamic> parsed = {};
        for (var item in items) {
          parsed[item['semester']] = item;
        }

        setState(() {
          _schedules = parsed;
          _isLoading = false;
        });
      } else {
        setState(() {
          _schedules = {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(
          context,
          message: 'Failed to fetch schedules: $e',
          isSuccess: false,
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadSchedule(int semester) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null) return;

      setState(() => _isLoading = true);

      final file = result.files.first;
      String jsonString;
      if (file.path != null) {
        jsonString = await File(file.path!).readAsString();
      } else {
        final bytes = await file.readAsBytes();
        jsonString = String.fromCharCodes(bytes);
      }

      final jsonData = jsonDecode(jsonString);

      if (!jsonData.containsKey('classes') || jsonData['classes'] is! List) {
        throw Exception('Invalid JSON format: missing classes array');
      }

      final response = await http.post(
        Uri.parse('${Config.scheduleBaseEndpoint}/$semester'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(jsonData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          EduMateToast.showCompact(
            context,
            message: 'Schedule for Semester $semester uploaded successfully!',
            isSuccess: true,
          );
        }
        _fetchSchedules();
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to upload schedule');
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(
          context,
          message: 'Error: ${e.toString().replaceAll('Exception: ', '')}',
          isSuccess: false,
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchSchedules,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                            top: 130, bottom: 30, left: 16, right: 16),
                        itemCount: _displayedSemesters.length,
                        itemBuilder: (context, index) {
                          final sem = _displayedSemesters[index];
                          final schedule = _schedules[sem];
                          final bool isConfigured = schedule != null;
                          int periodCount = 0;

                          if (isConfigured && schedule['classes'] != null) {
                            for (var c in schedule['classes']) {
                              if (c['schedule'] != null) {
                                for (var d in c['schedule']) {
                                  if (d['periods'] != null) {
                                    periodCount += (d['periods'] as List).length;
                                  }
                                }
                              }
                            }
                          }

                          return _SemesterCard(
                            semester: sem,
                            isConfigured: isConfigured,
                            periodCount: periodCount,
                            isDark: isDark,
                            onUpload: () => _uploadSchedule(sem),
                            onUpdate: () => _fetchSchedules(),
                          );
                        },
                      ),
                    ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF141414).withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.7),
                    border: Border(
                      bottom: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05)),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 50,
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  child: Icon(CupertinoIcons.back,
                                      color:
                                          isDark ? Colors.white : Colors.black),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  'Schedule',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Salena',
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildPillSlider(context, isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillSlider(BuildContext context, bool isDark) {
    final isAutumn = _selectedSeason == 'Autumn';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pillWidth = (constraints.maxWidth - 8) / 2;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.fastOutSlowIn,
                  left: isAutumn ? 4 : pillWidth + 4,
                  top: 4,
                  bottom: 4,
                  width: pillWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444), // Amber Red
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (_selectedSeason != 'Autumn') {
                            setState(() => _selectedSeason = 'Autumn');
                          }
                        },
                        child: Center(
                          child: Text(
                            'Autumn',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              color: isAutumn
                                  ? Colors.white
                                  : (isDark ? Colors.white60 : Colors.black54),
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (_selectedSeason != 'Spring') {
                            setState(() => _selectedSeason = 'Spring');
                          }
                        },
                        child: Center(
                          child: Text(
                            'Spring',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              color: !isAutumn
                                  ? Colors.white
                                  : (isDark ? Colors.white60 : Colors.black54),
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SemesterCard extends StatelessWidget {
  final int semester;
  final bool isConfigured;
  final int periodCount;
  final bool isDark;
  final VoidCallback onUpload;
  final VoidCallback onUpdate;

  const _SemesterCard({
    required this.semester,
    required this.isConfigured,
    required this.periodCount,
    required this.isDark,
    required this.onUpload,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [Color(0xFF303030), Color(0xFF1A1A1A)]
                    : const [Color(0xFFFFFFFF), Color(0xFFF3F4F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Semester $semester',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isConfigured
                            ? CupertinoColors.activeGreen.withValues(alpha: 0.2)
                            : CupertinoColors.systemOrange
                                .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isConfigured ? 'Configured' : 'Not Set',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isConfigured
                              ? CupertinoColors.activeGreen
                              : CupertinoColors.systemOrange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isConfigured
                      ? '$periodCount periods scheduled'
                      : 'No schedule JSON uploaded yet',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        icon: CupertinoIcons.arrow_up_doc_fill,
                        label: isConfigured ? 'Replace JSON' : 'Upload JSON',
                        color: const Color(0xFF10B981), // Emerald Green
                        isDark: isDark,
                        onTap: onUpload,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        icon: CupertinoIcons.pencil_circle_fill,
                        label: isConfigured ? 'Edit Schedule' : 'Add Schedule',
                        color: const Color(0xFFF59E0B), // Amber
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ScheduleEditorScreen(
                                semester: semester,
                              ),
                            ),
                          ).then((_) => onUpdate());
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.25 : 0.15),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
