import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
    'students': 0,
    'societyHeads': 0,
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
                      Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Salena',
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Overview of EduMate system statistics',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? CupertinoColors.systemGrey : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // User Stats Card
                      _StatCard(
                        title: 'Total Users',
                        value: '${_stats['students'] + _stats['societyHeads']}',
                        subtitle: '${_stats['students']} Students • ${_stats['societyHeads']} Society Heads',
                        icon: CupertinoIcons.person_3,
                        color: Colors.blueAccent,
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
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
