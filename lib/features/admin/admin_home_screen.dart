import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:app/shared/config.dart';

class AdminHomeScreen extends StatefulWidget {
  final bool fromStudentView;
  const AdminHomeScreen({super.key, this.fromStudentView = false});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool _isLoading = true;
  late ScrollController _scrollController;
  Map<String, dynamic> _stats = {
    'totalUsers': 0,
    'students': 0,
    'societies': 0,
    'admins': 0,
    'contributors': 0,
    'configuredSemesters': 0,
    'pois': 0,
    'posts': 0,
  };

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fetchStats();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const AdminDashboardSkeleton()
            : RefreshIndicator(
                onRefresh: _fetchStats,
                child: Stack(
                  children: [
                    AnimatedBuilder(
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
                                Colors.black.withValues(alpha: 1.0 - fadeIntensity),
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
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 16.0),
                              child: Column(
                                children: [
                                  const SizedBox(height: 4),
                                  const Center(
                                    child: Text(
                                      'Admin Dashboard',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Salena',
                                        color: CupertinoColors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // User Stats Card (Demographics)
                                  _DemographicsCard(
                                    totalUsers: _stats['totalUsers'] ?? 0,
                                    students: _stats['students'] ?? 0,
                                    societyHeads: _stats['societies'] ?? 0,
                                    admins: _stats['admins'] ?? 0,
                                    contributors: _stats['contributors'] ?? 0,
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Schedule Stats Card
                                  _StatCard(
                                    title: 'Schedule Data',
                                    value: '${_stats['configuredSemesters']}/8',
                                    subtitle: 'Semesters Configured',
                                    icon: CupertinoIcons.calendar,
                                    color: Colors.greenAccent,
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // POI Stats Card
                                  _StatCard(
                                    title: 'Points of Interest',
                                    value: '${_stats['pois']}',
                                    subtitle: 'Active POIs',
                                    icon: CupertinoIcons.map_pin_ellipse,
                                    color: Colors.orangeAccent,
                                  ),
                                  const SizedBox(height: 16),

                                  // Posts Stats Card
                                  _StatCard(
                                    title: 'Posts & Events',
                                    value: '${_stats['posts']}',
                                    subtitle: 'Total Posts',
                                    icon: CupertinoIcons.bubble_left_bubble_right,
                                    color: Colors.purpleAccent,
                                  ),
                                  
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141110),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemGrey,
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
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
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

  const _DemographicsCard({
    required this.totalUsers,
    required this.students,
    required this.societyHeads,
    required this.admins,
    required this.contributors,
  });

  @override
  State<_DemographicsCard> createState() => _DemographicsCardState();
}

class _DemographicsCardState extends State<_DemographicsCard> {
  int touchedIndex = -1;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF141110),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${widget.totalUsers}',
                          style: const TextStyle(
                            fontSize: 56, 
                            color: Colors.white, 
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.totalUsers == 1 ? 'user' : 'users',
                          style: TextStyle(
                            fontSize: 18, 
                            color: Colors.grey[400], 
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 180,
                      child: widget.totalUsers > 0 
                        ? PieChart(
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
                              centerSpaceRadius: 35,
                              sections: _showingSections(),
                            ),
                          )
                        : const Center(child: Text('No Data', style: TextStyle(color: Colors.white))),
                    ),
                  ),
                ],
              ),
              if (_isExpanded && widget.totalUsers > 0) ...[
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Indicator(color: Colors.blue, text: 'Students', isSquare: false, value: widget.students),
                          const SizedBox(height: 12),
                          _Indicator(color: Colors.orange, text: 'Society', isSquare: false, value: widget.societyHeads),
                          const SizedBox(height: 12),
                          _Indicator(
                            color: Colors.teal, 
                            text: 'Guests', 
                            isSquare: false, 
                            value: (widget.totalUsers - (widget.students + widget.societyHeads + widget.admins + widget.contributors) > 0) ? widget.totalUsers - (widget.students + widget.societyHeads + widget.admins + widget.contributors) : 0
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Indicator(color: Colors.purple, text: 'Contributors', isSquare: false, value: widget.contributors),
                          const SizedBox(height: 12),
                          _Indicator(color: Colors.red, text: 'Admins', isSquare: false, value: widget.admins),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Icon(
                    CupertinoIcons.chevron_up,
                    size: 20,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ],
          ),
        ),
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
          radius: touchedIndex == 0 ? 50.0 : 40.0,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      if (widget.societyHeads > 0)
        PieChartSectionData(
          color: Colors.orange,
          value: widget.societyHeads.toDouble(),
          title: '${((widget.societyHeads / widget.totalUsers) * 100).toStringAsFixed(0)}%',
          radius: touchedIndex == 1 ? 50.0 : 40.0,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      if (widget.contributors > 0)
        PieChartSectionData(
          color: Colors.purple,
          value: widget.contributors.toDouble(),
          title: '${((widget.contributors / widget.totalUsers) * 100).toStringAsFixed(0)}%',
          radius: touchedIndex == 2 ? 50.0 : 40.0,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      if (widget.admins > 0)
        PieChartSectionData(
          color: Colors.red,
          value: widget.admins.toDouble(),
          title: '${((widget.admins / widget.totalUsers) * 100).toStringAsFixed(0)}%',
          radius: touchedIndex == 3 ? 50.0 : 40.0,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      if (widget.totalUsers - (widget.students + widget.societyHeads + widget.admins + widget.contributors) > 0)
        PieChartSectionData(
          color: Colors.teal,
          value: (widget.totalUsers - (widget.students + widget.societyHeads + widget.admins + widget.contributors)).toDouble(),
          title: '${(((widget.totalUsers - (widget.students + widget.societyHeads + widget.admins + widget.contributors)) / widget.totalUsers) * 100).toStringAsFixed(0)}%',
          radius: touchedIndex == 4 ? 50.0 : 40.0,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
    ];
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;
  final int value;

  const _Indicator({
    required this.color,
    required this.text,
    required this.isSquare,
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
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }
}

class AdminDashboardSkeleton extends StatefulWidget {
  const AdminDashboardSkeleton({super.key});

  @override
  State<AdminDashboardSkeleton> createState() => _AdminDashboardSkeletonState();
}

class _AdminDashboardSkeletonState extends State<AdminDashboardSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildSkeletonCard({required double height, required Color baseColor}) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF141110),
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = Colors.white.withValues(alpha: 0.2);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 200,
                    height: 32,
                    decoration: BoxDecoration(
                      color: titleColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Demographics Card Skeleton
                _buildSkeletonCard(height: 350, baseColor: Colors.transparent),
                
                // Stat Card Skeletons
                _buildSkeletonCard(height: 120, baseColor: Colors.transparent),
                _buildSkeletonCard(height: 120, baseColor: Colors.transparent),
                _buildSkeletonCard(height: 120, baseColor: Colors.transparent),
              ],
            ),
          ),
        );
      },
    );
  }
}
