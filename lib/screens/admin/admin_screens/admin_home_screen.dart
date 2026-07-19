import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../../../config.dart';

class AdminHomeScreen extends StatefulWidget {
  final bool fromStudentView;
  const AdminHomeScreen({super.key, this.fromStudentView = false});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {
    'totalUsers': 0,
    'students': 0,
    'societyHeads': 0,
    'admins': 0,
    'contributors': 0,
    'configuredSemesters': 0,
    'pois': 0,
    'posts': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final response = await http.get(Uri.parse(Config.adminStatsEndpoint));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _stats = data['data'];
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Failed to fetch admin stats: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : RefreshIndicator(
                onRefresh: _fetchStats,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Salena',
                            color: isDark ? CupertinoColors.white : CupertinoColors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // User Stats Card (Demographics)
                      _DemographicsCard(
                        totalUsers: _stats['totalUsers'] ?? 0,
                        students: _stats['students'] ?? 0,
                        societyHeads: _stats['societyHeads'] ?? 0,
                        admins: _stats['admins'] ?? 0,
                        contributors: _stats['contributors'] ?? 0,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      
                      // Schedule Stats Card
                      _StatCard(
                        title: 'Schedule Data',
                        value: '${_stats['configuredSemesters']}/8',
                        subtitle: 'Semesters Configured',
                        icon: CupertinoIcons.calendar,
                        color: Colors.greenAccent,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      
                      // POI Stats Card
                      _StatCard(
                        title: 'Points of Interest',
                        value: '${_stats['pois']}',
                        subtitle: 'Active POIs',
                        icon: CupertinoIcons.map_pin_ellipse,
                        color: Colors.orangeAccent,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      // Posts Stats Card
                      _StatCard(
                        title: 'Posts & Events',
                        value: '${_stats['posts']}',
                        subtitle: 'Total Posts',
                        icon: CupertinoIcons.bubble_left_bubble_right,
                        color: Colors.purpleAccent,
                        isDark: isDark,
                      ),
                      
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? CupertinoColors.systemGrey : Colors.grey[700],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemographicsCard extends StatefulWidget {
  final int totalUsers;
  final int students;
  final int societyHeads;
  final int admins;
  final int contributors;
  final bool isDark;

  const _DemographicsCard({
    required this.totalUsers,
    required this.students,
    required this.societyHeads,
    required this.admins,
    required this.contributors,
    required this.isDark,
  });

  @override
  State<_DemographicsCard> createState() => _DemographicsCardState();
}

class _DemographicsCardState extends State<_DemographicsCard> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!widget.isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${widget.totalUsers}',
                style: TextStyle(fontSize: 36, color: widget.isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                widget.totalUsers == 1 ? 'user' : 'users',
                style: TextStyle(fontSize: 16, color: widget.isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (widget.totalUsers > 0) ...[
            SizedBox(
              height: 180,
              child: Center(
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: _showingSections(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Indicator(color: Colors.blue, text: 'Students', isSquare: false, isDark: widget.isDark, value: widget.students),
                      const SizedBox(height: 12),
                      _Indicator(color: Colors.orange, text: 'Society', isSquare: false, isDark: widget.isDark, value: widget.societyHeads),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Indicator(color: Colors.purple, text: 'Contributors', isSquare: false, isDark: widget.isDark, value: widget.contributors),
                      const SizedBox(height: 12),
                      _Indicator(color: Colors.red, text: 'Admins', isSquare: false, isDark: widget.isDark, value: widget.admins),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            const Center(child: Text('No user data available')),
          ]
        ],
      ),
    );
  }

  List<PieChartSectionData> _showingSections() {
    return [
      if (widget.students > 0)
        PieChartSectionData(
          color: Colors.blue,
          value: widget.students.toDouble(),
          title: '${((widget.students / widget.totalUsers) * 100).toStringAsFixed(0)}%',
          radius: touchedIndex == 0 ? 60.0 : 50.0,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      if (widget.societyHeads > 0)
        PieChartSectionData(
          color: Colors.orange,
          value: widget.societyHeads.toDouble(),
          title: '${((widget.societyHeads / widget.totalUsers) * 100).toStringAsFixed(0)}%',
          radius: touchedIndex == 1 ? 60.0 : 50.0,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      if (widget.contributors > 0)
        PieChartSectionData(
          color: Colors.purple,
          value: widget.contributors.toDouble(),
          title: '${((widget.contributors / widget.totalUsers) * 100).toStringAsFixed(0)}%',
          radius: touchedIndex == 2 ? 60.0 : 50.0,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      if (widget.admins > 0)
        PieChartSectionData(
          color: Colors.red,
          value: widget.admins.toDouble(),
          title: '${((widget.admins / widget.totalUsers) * 100).toStringAsFixed(0)}%',
          radius: touchedIndex == 3 ? 60.0 : 50.0,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
    ];
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;
  final bool isDark;
  final int value;

  const _Indicator({
    required this.color,
    required this.text,
    required this.isSquare,
    required this.isDark,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$text ($value)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        )
      ],
    );
  }
}
