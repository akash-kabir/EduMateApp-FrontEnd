import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/features/admin/schedule/admin_elective_management.dart';
import 'package:app/features/admin/curriculum/curriculum_management_screen.dart';
import 'package:app/features/admin/schedule/schedule_management_screen.dart';
import 'package:app/features/admin/general/admin_poi_management.dart';
import 'package:app/features/admin/general/admin_holiday_management.dart';
import 'package:app/features/admin/users/admin_student_data_management.dart';

class AdminUploadScreen extends StatelessWidget {
  const AdminUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Clean Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Management',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Salena',
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage curriculums, timetables, electives, map POIs, and holiday calendars.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Academic Data Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'ACADEMIC DATA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _DataManagementCard(
                  title: 'Curriculum',
                  iconColor: const Color(0xFF6366F1),
                  icon: CupertinoIcons.book_fill,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const CurriculumManagementScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _DataManagementCard(
                  title: 'Schedule',
                  iconColor: const Color(0xFFF59E0B),
                  icon: CupertinoIcons.clock_fill,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const ScheduleManagementScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _DataManagementCard(
                  title: 'Electives',
                  iconColor: const Color(0xFF10B981),
                  icon: CupertinoIcons.checkmark_seal_fill,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const AdminElectiveManagementScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),

          // Campus & System Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'CAMPUS & SYSTEM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _DataManagementCard(
                  title: 'POI',
                  iconColor: const Color(0xFFF43F5E),
                  icon: CupertinoIcons.map_pin_ellipse,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const AdminPoiManagementScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _DataManagementCard(
                  title: 'Holidays',
                  iconColor: const Color(0xFF06B6D4),
                  icon: CupertinoIcons.calendar_today,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const AdminHolidayManagementScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _DataManagementCard(
                  title: 'Student Data',
                  subtitle: 'Roll number to section & elective mappings',
                  iconColor: const Color(0xFF06B6D4),
                  icon: CupertinoIcons.person_2_fill,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const AdminStudentDataManagementScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataManagementCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color iconColor;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _DataManagementCard({
    required this.title,
    this.subtitle,
    required this.iconColor,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}
