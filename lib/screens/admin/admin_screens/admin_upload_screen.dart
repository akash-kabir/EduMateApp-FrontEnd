import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'curriculum_management_screen.dart';
import 'schedule_management_screen.dart';

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
              'Curriculum & Schedule',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Manage curriculums and schedules for all semesters',
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
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDark
              ? CupertinoColors.systemGrey6.withOpacity(0.3)
              : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFF1744).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF1744).withOpacity(0.1),
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
    );
  }
}
