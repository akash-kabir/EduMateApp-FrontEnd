import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:app/features/sapsync/provider/sap_provider.dart';
import 'package:app/features/sapsync/widgets/sleek_attendance_card.dart';
import 'package:app/features/sapsync/widgets/sap_hero_visualization.dart';
import 'package:app/features/sapsync/widgets/sap_skeleton_loader.dart';
import 'package:app/shared/widgets/dialogs/custom_glass_dialog.dart';

class SapAttendanceScreen extends StatefulWidget {
  const SapAttendanceScreen({super.key});

  @override
  State<SapAttendanceScreen> createState() => _SapAttendanceScreenState();
}

class _SapAttendanceScreenState extends State<SapAttendanceScreen> {
  int? _selectedIndex;
  final ScrollController _scrollController = ScrollController();

  bool _isFlashing = false;
  double _dragOffset = 0.0;
  bool _isRefreshing = false;
  final double _refreshThreshold = 80.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh(SapProvider sapProvider) async {
    if (_isRefreshing || sapProvider.isLoading) return;
    
    setState(() {
      _isRefreshing = true;
      _dragOffset = _refreshThreshold;
    });

    await sapProvider.fetchAttendance();
    
    setState(() { 
      _isFlashing = true; 
      _isRefreshing = false;
      _dragOffset = 0.0; 
    });
    
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() { _isFlashing = false; });
    }
  }

  bool _onScroll(ScrollNotification notification, SapProvider sapProvider) {
    if (_isRefreshing || sapProvider.isLoading || _isFlashing) return false;

    if (notification is OverscrollNotification && notification.overscroll < 0) {
      setState(() {
        _dragOffset += notification.overscroll.abs();
      });
    } else if (notification is ScrollUpdateNotification) {
      if (notification.metrics.pixels <= 0 && notification.scrollDelta != null && notification.scrollDelta! < 0) {
        setState(() {
          _dragOffset += notification.scrollDelta!.abs();
        });
      } else if (notification.metrics.pixels > 0 && _dragOffset > 0) {
        setState(() {
          _dragOffset = 0.0;
        });
      }
    } else if (notification is ScrollEndNotification) {
      if (_dragOffset >= _refreshThreshold) {
        _handleRefresh(sapProvider);
      } else {
        setState(() { _dragOffset = 0.0; });
      }
    }
    return false;
  }


  @override
  Widget build(BuildContext context) {
    final sapProvider = Provider.of<SapProvider>(context);
    final records = sapProvider.attendanceRecords;
    final overallPct = sapProvider.overallPercentage;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: AnimatedBuilder(
            animation: _scrollController,
            builder: (context, child) {
              final fadeIntensity = _scrollController.hasClients ? (_scrollController.offset / 40.0).clamp(0.0, 1.0) : 0.0;
              return ShaderMask(
                shaderCallback: (Rect rect) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 1.0 - fadeIntensity),
                      Colors.black,
                    ],
                    stops: const [0.0, 0.08], // Fades top 8% of the scroll view
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: child,
              );
            },
            child: RepaintBoundary(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) => _onScroll(notification, sapProvider),
                child: Stack(
                  children: [
                    CustomScrollView(
                      controller: _scrollController,
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                // 1. The Header (Scrolls away)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Hero(
                            tag: 'back_button',
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF141110),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(CupertinoIcons.back, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const Text(
                          'Attendance',
                          style: TextStyle(
                            fontSize: 24,
                            fontFamily: 'Salena',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Color(0xFFFF9B7A),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Hero(
                            tag: 'settings_button',
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => _showSettingsModal(context, sapProvider),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF141110),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.settings, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Error Banner (if any)
                if (sapProvider.errorMessage.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        sapProvider.errorMessage,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  ),

                // 3. Main Content
                if (_isFlashing || (sapProvider.isLoading && records.isEmpty))
                  const SliverFillRemaining(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SapSkeletonLoader(),
                    ),
                  )
                else if (records.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No attendance data available.\nPull down to sync.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Hero Visualization Header
                        SapHeroVisualization(
                          records: records,
                          overallPercentage: overallPct,
                          totalPresent: sapProvider.totalPresentClasses,
                          totalClasses: sapProvider.totalClassesCount,
                          threshold: sapProvider.attendanceThreshold,
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
                                color: Colors.grey,
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
                      ]),
                    ),
                  ),
              ],
            ),
            if (_dragOffset > 0 || _isRefreshing || _isFlashing)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _isRefreshing || _isFlashing
                    ? const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CD97B)),
                        minHeight: 3,
                      )
                    : Container(
                        height: 3,
                        alignment: Alignment.center,
                        child: FractionallySizedBox(
                          widthFactor: (_dragOffset / _refreshThreshold).clamp(0.0, 1.0),
                          child: Container(
                            color: const Color(0xFF4CD97B),
                          ),
                        ),
                      ),
              ),
          ],
        ),
      ),
    ),
  ),
),
);
  }
  List<Map<String, String>> _getTermOptions(String userId) {
    int studentStartYear = 2024;
    if (userId.length >= 2) {
      final prefix = int.tryParse(userId.substring(0, 2));
      if (prefix != null && prefix >= 15 && prefix <= 35) {
        studentStartYear = 2000 + prefix;
      }
    }

    return [
      {'label': '1st Year', 'year': '$studentStartYear-${studentStartYear + 1}'},
      {'label': '2nd Year', 'year': '${studentStartYear + 1}-${studentStartYear + 2}'},
      {'label': '3rd Year', 'year': '${studentStartYear + 2}-${studentStartYear + 3}'},
      {'label': '4th Year', 'year': '${studentStartYear + 3}-${studentStartYear + 4}'},
    ];
  }

  void _showSettingsModal(BuildContext context, SapProvider sapProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141110),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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

              // 1. Sync Attendance Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  sapProvider.fetchAttendance();
                },
                icon: const Icon(Icons.refresh, color: Colors.black),
                label: const Text(
                  'Sync / Refresh Attendance',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CD97B),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Term & Session Switcher Card with Cupertino Sliding Segmented Controls
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Academic Term', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoSlidingSegmentedControl<String>(
                        groupValue: sapProvider.termYear.isEmpty
                            ? _getTermOptions(sapProvider.sapUserId).first['year']
                            : sapProvider.termYear,
                        backgroundColor: const Color(0xFF2C2C2E),
                        thumbColor: const Color(0xFF4CD97B),
                        children: Map.fromEntries(
                          _getTermOptions(sapProvider.sapUserId).map((opt) {
                            final isSel = sapProvider.termYear == opt['year'] ||
                                (sapProvider.termYear.isEmpty && opt == _getTermOptions(sapProvider.sapUserId).first);
                            return MapEntry(
                              opt['year']!,
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  opt['label']!,
                                  style: TextStyle(
                                    color: isSel ? Colors.black : Colors.grey[300],
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        onValueChanged: (val) {
                          if (val != null) {
                            setModalState(() {});
                            sapProvider.updateSession(
                              val,
                              sapProvider.sessionKey.isEmpty ? 'Autumn' : sapProvider.sessionKey,
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Session', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoSlidingSegmentedControl<String>(
                        groupValue: sapProvider.sessionKey.toLowerCase() == 'spring' ? 'Spring' : 'Autumn',
                        backgroundColor: const Color(0xFF2C2C2E),
                        thumbColor: const Color(0xFF4CD97B),
                        children: {
                          'Autumn': Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Autumn Session',
                              style: TextStyle(
                                color: sapProvider.sessionKey.toLowerCase() != 'spring' ? Colors.black : Colors.grey[300],
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          'Spring': Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Spring Session',
                              style: TextStyle(
                                color: sapProvider.sessionKey.toLowerCase() == 'spring' ? Colors.black : Colors.grey[300],
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        },
                        onValueChanged: (val) {
                          if (val != null) {
                            setModalState(() {});
                            final curYear = sapProvider.termYear.isEmpty
                                ? _getTermOptions(sapProvider.sapUserId).first['year']!
                                : sapProvider.termYear;
                            sapProvider.updateSession(curYear, val);
                          }
                        },
                      ),
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
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
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
                            overlayColor: const Color(0xFF4CD97B).withValues(alpha: 0.2),
                            valueIndicatorColor: const Color(0xFF4CD97B),
                            valueIndicatorTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                          child: Slider(
                            value: sapProvider.attendanceThreshold,
                            min: 0.0,
                            max: 100.0,
                            divisions: 100,
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
                            Text('0%', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            Text('75% (Target)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            Text('100%', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  // Removed inner StatefulBuilder closing
                ),
              const SizedBox(height: 24),

              // Disconnect SapSync Button
              ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showGlassmorphicDialog<bool>(
                    context: context,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Disconnect SapSync?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'This will remove your stored SAP credentials and clear all local attendance data for SapSync. Your main EduMate account will not be affected.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => Navigator.pop(context, false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: const Center(
                                    child: Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => Navigator.pop(context, true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text('Disconnect', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
      },
    );
  }
}
