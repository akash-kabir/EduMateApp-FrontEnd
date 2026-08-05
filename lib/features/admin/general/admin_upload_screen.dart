import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/features/admin/schedule/admin_elective_management.dart';
import 'package:app/features/admin/curriculum/curriculum_management_screen.dart';
import 'package:app/features/admin/schedule/schedule_management_screen.dart';
import 'package:app/features/admin/general/admin_poi_management.dart';
import 'package:app/features/admin/general/admin_holiday_management.dart';
import 'package:app/features/admin/users/admin_student_data_management.dart';

class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({super.key});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: _scrollController,
          builder: (context, child) {
            final fadeIntensity = _scrollController.hasClients
                ? (_scrollController.offset / 40.0).clamp(0.0, 1.0)
                : 0.0;
            return ShaderMask(
              shaderCallback: (Rect rect) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(1.0 - fadeIntensity),
                    Colors.black,
                  ],
                  stops: const [0.0, 0.08],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: child,
            );
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              // Clean Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data Management',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Salena',
                          letterSpacing: -0.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Manage curriculums, timetables, electives, map POIs, and holiday calendars.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white60,
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
                  child: const Text(
                    'ACADEMIC DATA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: Colors.white38,
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
                  child: const Text(
                    'CAMPUS & SYSTEM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: Colors.white38,
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

                      iconColor: const Color(0xFF06B6D4),
                      icon: CupertinoIcons.person_2_fill,
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
        ),
      ),
    );
  }
}

class _DataManagementCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color iconColor;
  final IconData icon;
  final VoidCallback onTap;

  const _DataManagementCard({
    required this.title,
    this.subtitle,
    required this.iconColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141110),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: Colors.white30,
            ),
          ],
        ),
      ),
    );
  }
}
