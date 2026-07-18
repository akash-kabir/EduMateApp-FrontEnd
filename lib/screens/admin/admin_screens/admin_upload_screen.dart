import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'admin_elective_management.dart';
import 'curriculum_management_screen.dart';
import 'schedule_management_screen.dart';
import 'admin_poi_management.dart';
import 'admin_holiday_management.dart';

class AdminUploadScreen extends StatelessWidget {
  const AdminUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Data Management',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Manage curriculums, schedules, electives and POIs',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? CupertinoColors.systemGrey : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            _UploadCard(
              title: 'Curriculum Management',
              description: 'Manage semester-wise subjects and credits',
              icon: Icons.school_rounded,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CurriculumManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _UploadCard(
              title: 'Schedule Management',
              description: 'Manage semester-wise daily timetables',
              icon: Icons.schedule_rounded,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScheduleManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _UploadCard(
              title: 'Elective Management',
              description: 'Manage semester-wise professional electives',
              icon: Icons.assignment_turned_in_rounded,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminElectiveManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _UploadCard(
              title: 'POI Management',
              description: 'Manage campus Points of Interest',
              icon: Icons.map_rounded,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminPoiManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _UploadCard(
              title: 'Holiday Management',
              description: 'Manage academic holidays',
              icon: Icons.calendar_today_rounded,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminHolidayManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _UploadCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.65),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1744).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: const Color(0xFFFF1744), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? CupertinoColors.systemGrey
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(CupertinoIcons.forward, color: Color(0xFFFF1744)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
