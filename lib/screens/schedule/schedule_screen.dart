import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import '../../constants/app_constants.dart';
import '../../config.dart';
import '../../services/shared_preferences_service.dart';
import '../../widgets/toast_manager.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with WidgetsBindingObserver {
  late DateTime selectedDate;
  late DateTime weekStartDate;
  Timer? _refreshTimer;
  String selectedBranch = '';
  int selectedSemester = 1;
  String selectedSection = '';
  
  bool savePreference = false;
  Map<String, dynamic>? scheduleData;
  bool isLoading = false;
  int _lastRequestId = 0;
  bool _slideFromRight = true; // true = next day, false = prev day
  double _dragOffset = 0.0; // tracks real-time drag distance

  final List<String> branches = ['CSCE', 'CSE', 'IT', 'CSSE'];
  final Map<String, List<String>> classesPerBranch = {
    'CSCE': ['CSCE-1'],
    'CSE': ['CSE-1', ...List.generate(54, (i) => 'CSE-${i + 1}')],
    'IT': ['IT-1', 'IT-2'],
    'CSSE': ['CSSE-1'],
  };

  // Static schedules mapping - will be replaced with API data
  static const Map<String, Map<int, List<dynamic>>> classSchedules = {
    'CSE 7': {
      1: [
        {
          'startTime': '09:00',
          'endTime': '10:00',
          'className': 'Math',
          'room': 'A101',
        },
        {
          'startTime': '10:00',
          'endTime': '11:00',
          'className': 'Physics',
          'room': 'B201',
        },
      ],
      2: [
        {
          'startTime': '11:00',
          'endTime': '12:00',
          'className': 'Chemistry',
          'room': 'C301',
        },
      ],
    },
    'CSE 16': {
      1: [
        {
          'startTime': '09:00',
          'endTime': '10:00',
          'className': 'Data Structures',
          'room': 'Lab1',
        },
        {
          'startTime': '10:00',
          'endTime': '11:00',
          'className': 'Web Development',
          'room': 'Lab2',
        },
      ],
      2: [
        {
          'startTime': '11:00',
          'endTime': '12:00',
          'className': 'Database',
          'room': 'A101',
        },
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    selectedDate = DateTime.now();
    weekStartDate = selectedDate.subtract(
      Duration(days: selectedDate.weekday % 7),
    );
    _loadSavedPreferenceAndFetchSchedule();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh UI when app comes back to foreground
      setState(() {});
      _startRefreshTimer();
    } else if (state == AppLifecycleState.paused) {
      _refreshTimer?.cancel();
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadSavedPreferenceAndFetchSchedule() async {
    final savedClass = await SharedPreferencesService.getString(
      'selectedSemester.toString()',
    );
    final savedBranch = await SharedPreferencesService.getString(
      'selectedBranch',
    );
    final savedSection = await SharedPreferencesService.getString(
      'selectedSection',
    );
    final savedYear =
        await SharedPreferencesService.getString('selectedYear') ?? '1st Year';
    final saved = await SharedPreferencesService.getBool('savePreference');

    if (saved && savedClass != null) {
      setState(() {
        if (savedBranch != null) selectedBranch = savedBranch;
        selectedSemester = int.tryParse(savedClass) ?? 1;
        if (savedSection != null) selectedSection = savedSection;
        savePreference = true;
      });
      // Fetch schedule for saved class
      _fetchScheduleFromBackend();
    } else {
      // No saved preference, fetch default schedule
      _fetchScheduleFromBackend();
    }
  }

  Future<void> _savePreference(
    String branch,
    String classValue,
    String yearValue,
    String sectionValue,
    bool shouldSave,
  ) async {
    if (shouldSave) {
      await SharedPreferencesService.setString('selectedBranch', branch);
      await SharedPreferencesService.setString('selectedSemester.toString()', classValue);
      await SharedPreferencesService.setString('selectedSection', sectionValue);
      await SharedPreferencesService.setString('selectedYear', yearValue);
      await SharedPreferencesService.setBool('savePreference', true);
    } else {
      await SharedPreferencesService.remove('selectedBranch');
      await SharedPreferencesService.remove('selectedSemester.toString()');
      await SharedPreferencesService.remove('selectedSection');
      await SharedPreferencesService.remove('selectedYear');
      await SharedPreferencesService.setBool('savePreference', false);
    }
  }

  Future<bool> _isSavedPreferenceExists() async {
    return await SharedPreferencesService.getBool('savePreference');
  }

  Future<void> _cacheScheduleData(
    String branch,
    String classValue,
    Map<String, dynamic> data,
  ) async {
    final cacheKey = 'schedule_${branch}_$classValue';
    await SharedPreferencesService.setString(cacheKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> _getCachedScheduleData(
    String branch,
    String classValue,
  ) async {
    final cacheKey = 'schedule_${branch}_$classValue';
    final cachedData = await SharedPreferencesService.getString(cacheKey);
    if (cachedData != null) {
      try {
        return jsonDecode(cachedData) as Map<String, dynamic>?;
      } catch (e) {
        // print('Error decoding cached schedule: $e');
        return null;
      }
    }
    return null;
  }

  Future<void> _fetchScheduleFromBackend() async {
    // print('\n=== FETCH SCHEDULE START ===');
    // print('Selected Class: $selectedSemester.toString()');
    // print('Selected Branch: $selectedBranch');

    final currentRequestId = ++_lastRequestId;
    final requestedSemester = selectedSemester; // Capture what class was requested
    final requestedBranch = selectedBranch;
    // print('🆔 Request ID: $currentRequestId');
    // print('📌 Captured class: $requestedSemester.toString()');

    // Try to load from cache first
    // print('📦 Checking cache for $requestedBranch/$requestedSemester.toString()...');
    final cachedData = await _getCachedScheduleData(
      requestedBranch,
      requestedSemester.toString(),
    );
    if (cachedData != null) {
      // print('✅ Found cached schedule data');
      if (mounted) {
        setState(() {
          scheduleData = cachedData;
          isLoading = false;
        });
      }
      return;
    }

    // If no cache, fetch from backend
    // print('❌ No cache found, fetching from backend...');
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = '${Config.scheduleBaseEndpoint}/$requestedBranch/$requestedSemester?t=$timestamp';
      // print('API URL: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );

      // 🔥 CRITICAL: Check if this is still the latest request
      if (currentRequestId != _lastRequestId) {
        // print('❌ IGNORING STALE RESPONSE: Request #$currentRequestId is outdated (latest is #$_lastRequestId)');
        // print('   Requested: $requestedSemester.toString(), Current: $selectedSemester.toString()');
        return; // Discard this response, don't update UI
      }

      // print('Response status: ${response.statusCode}');
      // print('Response body length: ${response.body.length} bytes');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // print('=== RESPONSE DATA ===');
        // print('Response has "data" key: ${responseData.containsKey("data")}');
        // print('Response has "success" key: ${responseData.containsKey("success")}');

        // Handle the API response structure: { success: true, data: classSchedule }
        if (responseData is Map && responseData.containsKey('data')) {
          final classData = responseData['data'];
          // print('Extracted class data:');
          // print('  - Name: ${classData["name"]}');
          // print('  - Has schedule key: ${classData.containsKey("schedule")}');

          if (classData.containsKey('schedule') &&
              classData['schedule'] is List) {
            final scheduleList = classData['schedule'] as List;
            // print('  - Schedule days: ${scheduleList.length}');
            for (var day in scheduleList) {
              // print('    Day ${day["day"]}: ${day["periods"]?.length ?? 0} periods');
            }
          }

          // Cache the schedule data for offline use
          await _cacheScheduleData(requestedBranch, requestedSemester.toString(), classData);
          // print('💾 Schedule data cached for offline use');

          if (mounted) {
            setState(() {
              scheduleData = classData;
              isLoading = false;
            });
          }
          // print('✅ Schedule data updated');
        } else {
          // print('⚠️ No data key in response, using full response');
          // Cache the schedule data for offline use
          await _cacheScheduleData(
            requestedBranch,
            requestedSemester.toString(),
            responseData,
          );
          // print('💾 Schedule data cached for offline use');
          if (mounted) {
            setState(() {
              scheduleData = responseData;
              isLoading = false;
            });
          }
        }
      } else if (response.statusCode == 404) {
        // print('❌ Schedule not found for: $requestedSemester.toString()');
        if (mounted) {
          setState(() {
            scheduleData = null;
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load schedule: ${response.statusCode}');
      }
      // print('=== FETCH SCHEDULE END ===\n');
    } catch (e) {
      if (mounted) {
        setState(() {
          scheduleData = null;
          isLoading = false;
        });
      }
      // print('❌ Error fetching schedule: $e');
    }
  }

  List<DateTime> getWeekDates() {
    return List.generate(7, (i) => weekStartDate.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weekDates = getWeekDates();
    final now = DateTime.now();

    return CupertinoPageScaffold(
      child: GestureDetector(
        onHorizontalDragStart: (_) {
          setState(() {
            _dragOffset = 0.0;
          });
        },
        onHorizontalDragUpdate: (details) {
          setState(() {
            _dragOffset += details.delta.dx;
          });
        },
        onHorizontalDragEnd: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final swipeThreshold = screenWidth * 0.25;
          final velocityThreshold = 200.0;
          final velocity = details.primaryVelocity ?? 0;
          final weekDatesLocal = getWeekDates();
          final currentIndex = weekDatesLocal.indexWhere(
            (date) =>
                date.year == selectedDate.year &&
                date.month == selectedDate.month &&
                date.day == selectedDate.day,
          );
          bool didSwipe = false;
          // Swipe left (negative drag or velocity) → next day
          if (_dragOffset < -swipeThreshold || velocity < -velocityThreshold) {
            // Mon(1)→Sat(6)
            if (currentIndex < 6) {
              final nextIndex = currentIndex + 1 <= 6
                  ? currentIndex + 1
                  : currentIndex;
              setState(() {
                _slideFromRight = true;
                _dragOffset = 0.0;
                selectedDate = weekDatesLocal[nextIndex];
              });
              didSwipe = true;
            }
          }
          // Swipe right (positive drag or velocity) → previous day
          else if (_dragOffset > swipeThreshold ||
              velocity > velocityThreshold) {
            if (currentIndex > 1) {
              final prevIndex = currentIndex - 1 >= 1
                  ? currentIndex - 1
                  : currentIndex;
              setState(() {
                _slideFromRight = false;
                _dragOffset = 0.0;
                selectedDate = weekDatesLocal[prevIndex];
              });
              didSwipe = true;
            }
          }
          if (!didSwipe) {
            // Snap back
            setState(() {
              _dragOffset = 0.0;
            });
          }
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            CupertinoSliverNavigationBar(
              automaticallyImplyLeading: false,
              largeTitle: Text(
                'Timesheet',
                style: TextStyle(
                  fontFamily: 'Salena',
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: isDark
                  ? CupertinoColors.black.withValues(alpha: 0.6)
                  : CupertinoColors.white.withValues(alpha: 0.6),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _showSettingsBottomSheet,
                child: const Icon(
                  CupertinoIcons.settings,
                  color: AuthPalette.coral,
                  size: 22,
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _DaySelectorHeaderDelegate(
                height: 118.0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      color: isDark
                          ? CupertinoColors.black.withValues(alpha: 0.6)
                          : CupertinoColors.white.withValues(alpha: 0.6),
                      height:
                          118.0, // Explicitly match delegate height to prevent paintExtent discrepancy
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildWeekCalendarGrid(weekDates, isDark, now),
                          if (selectedBranch.isNotEmpty &&
                              selectedSemester.toString().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Showing for Semester $selectedSemester ($selectedBranch)',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Text(
                              'No Section Selected',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (selectedBranch.isEmpty || selectedSemester.toString().isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.info_circle,
                        size: 48,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select a Branch and Section',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[300] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap on the Branch and Section in the header\nto get started',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (isLoading)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CupertinoActivityIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading schedule for $selectedSemester.toString()...',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (scheduleData == null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_circle,
                        size: 40,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No schedule data available for $selectedSemester.toString()',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Opacity(
                      opacity: (1.0 - (_dragOffset.abs() / 400.0)).clamp(
                        0.4,
                        1.0,
                      ),
                      child: AnimatedContainer(
                        duration: _dragOffset == 0.0
                            ? const Duration(milliseconds: 200)
                            : Duration.zero,
                        curve: Curves.easeOut,
                        transform: Matrix4.translationValues(
                          _dragOffset.clamp(-200.0, 200.0),
                          0,
                          0,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) {
                            // Determine if this is the incoming or outgoing child
                            final isIncoming =
                                child.key == ValueKey(selectedDate);
                            final Offset offsetBegin;
                            if (isIncoming) {
                              // New content slides in from the swipe direction
                              offsetBegin = _slideFromRight
                                  ? const Offset(1.0, 0.0)
                                  : const Offset(-1.0, 0.0);
                            } else {
                              // Old content slides out in the opposite direction
                              offsetBegin = _slideFromRight
                                  ? const Offset(-1.0, 0.0)
                                  : const Offset(1.0, 0.0);
                            }
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: offsetBegin,
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey(selectedDate),
                            child: _buildClassBlocksForSelectedDay(isDark),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekCalendarGrid(
    List<DateTime> weekDates,
    bool isDark,
    DateTime now,
  ) {
    // Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6 (skip Sun=0)
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final weekdayIndices = [1, 2, 3, 4, 5, 6]; // Mon-Sat in weekDates list

    final selectedIndex = weekDates.indexWhere(
      (date) =>
          date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day,
    );

    return Container(
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AuthPalette.coral.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (i) {
          final dateIndex = weekdayIndices[i];
          final isSelected = dateIndex == selectedIndex;
          final date = weekDates[dateIndex];
          final isToday =
              date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;

          return GestureDetector(
            onTap: () {
              setState(() {
                _slideFromRight = dateIndex > selectedIndex;
                selectedDate = weekDates[dateIndex];
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: 48,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AuthPalette.coral : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isToday && !isSelected
                      ? AuthPalette.coral.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Text(
                dayLabels[i],
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.grey[300] : Colors.grey[700]),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Merge consecutive classes with the same name into a single card
  List<Map<String, dynamic>> _mergeConsecutiveClasses(List<dynamic> classes) {
    if (classes.isEmpty) return [];

    List<Map<String, dynamic>> merged = [];
    Map<String, dynamic>? currentGroup;

    for (final classPeriod in classes) {
      final cp = classPeriod as Map<String, dynamic>;

      // Skip placeholder entries
      if (cp['className'] == '—') continue;

      if (currentGroup == null) {
        // Start a new group
        currentGroup = {
          'className': cp['className'],
          'startTime': cp['startTime'],
          'endTime': cp['endTime'],
          'room': cp['room'],
          'count': 1, // Track how many periods this represents
        };
      } else if (currentGroup['className'] == cp['className']) {
        // Same class name, extend the end time
        currentGroup['endTime'] = cp['endTime'];
        currentGroup['count'] = (currentGroup['count'] as int) + 1;
      } else {
        // Different class name, save current group and start new one
        merged.add(currentGroup);
        currentGroup = {
          'className': cp['className'],
          'startTime': cp['startTime'],
          'endTime': cp['endTime'],
          'room': cp['room'],
          'count': 1,
        };
      }
    }

    // Don't forget to add the last group
    if (currentGroup != null) {
      merged.add(currentGroup);
    }

    return merged;
  }

  List<dynamic> _getClassesForDay(int dayOfWeek) {
    // print('\n=== GET CLASSES FOR DAY ===');
    // print('Day of week: $dayOfWeek (1=Mon, 7=Sun)');
    // print('Selected class: $selectedSemester.toString()');

    // Convert Flutter weekday (Mon=1, Sun=7) to our day format (Mon=1, Fri=5)
    // Filter only weekdays (Monday-Friday)
    if (dayOfWeek < 1 || dayOfWeek > 5) {
      // print('❌ Day $dayOfWeek is not a weekday (1-5), returning empty');
      return [];
    }

    // print('ScheduleData is null: ${scheduleData == null}');

    // Try to get data from API first
    if (scheduleData != null) {
      List<dynamic>? classes = scheduleData!['classes'] as List<dynamic>?;
      if (classes != null) {
        var section = classes.firstWhere((s) => s['name'] == selectedSection, orElse: () => null);
        if (section != null && section['schedule'] is List) {
          var schedule = section['schedule'] as List;
          for (int i = 0; i < schedule.length; i++) {
            var dayData = schedule[i];
            if (dayData['day'] == dayOfWeek && dayData['periods'] is List) {
              final periods = List<Map<String, dynamic>>.from(dayData['periods']);
              periods.sort((a, b) {
                final aTime = a['startTime'].toString();
                final bTime = b['startTime'].toString();
                return aTime.compareTo(bTime);
              });
              return periods;
            }
          }
        }
      }
    }

    // print('🔄 No API data found, using static fallback');
    // Fallback to static data
    final schedule = classSchedules[selectedSemester.toString()] ?? {};
    final result = schedule[dayOfWeek] ?? [];
    // print('Fallback result: ${result.length} periods');
    // print('=== GET CLASSES END ===\n');
    return result;
  }

  bool _isClassPassed(String endTime) {
    final now = DateTime.now();
    if (selectedDate.year != now.year ||
        selectedDate.month != now.month ||
        selectedDate.day != now.day) {
      return false;
    }
    final endParts = endTime.split(':');
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    final nowMinutes = now.hour * 60 + now.minute;
    return nowMinutes >= endMinutes;
  }

  bool _isClassOngoing(String startTime, String endTime) {
    final now = DateTime.now();
    // Only highlight if the selected day is today
    if (selectedDate.year != now.year ||
        selectedDate.month != now.month ||
        selectedDate.day != now.day) {
      return false;
    }
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    final startMinutes =
        int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    final nowMinutes = now.hour * 60 + now.minute;
    return nowMinutes >= startMinutes && nowMinutes < endMinutes;
  }

  Widget _buildClassBlocksForSelectedDay(bool isDark) {
    if (isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CupertinoActivityIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading schedule for $selectedSemester.toString()...',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (scheduleData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.exclamationmark_circle,
                size: 40,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                'No schedule data available for $selectedSemester.toString()',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final classes = _getClassesForDay(selectedDate.weekday);

    if (classes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'No classes scheduled for this day',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    // Merge consecutive classes with the same name
    final mergedClasses = _mergeConsecutiveClasses(classes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(mergedClasses.length, (index) {
          final classPeriod = mergedClasses[index];

          final classCount = classPeriod['count'] as int;
          final isOngoing = _isClassOngoing(
            classPeriod['startTime'] as String,
            classPeriod['endTime'] as String,
          );
          final isPassed = _isClassPassed(classPeriod['endTime'] as String);

          final Color accentColor;
          if (isOngoing) {
            accentColor = CupertinoColors.systemGreen;
          } else if (isPassed) {
            accentColor = isDark ? Colors.grey[700]! : Colors.grey[400]!;
          } else {
            accentColor = AuthPalette.coral;
          }

          final double cardOpacity = isPassed ? 0.5 : 1.0;

          // Glass base decoration
          final BoxDecoration cardDecoration;
          if (isOngoing) {
            cardDecoration = BoxDecoration(
              color: const Color.fromARGB(
                255,
                2,
                56,
                38,
              ).withValues(alpha: 0.14), // Glass Emerald Green Tint
              borderRadius: BorderRadius.circular(16),
              border: const Border(
                left: BorderSide(color: Color(0xFF10B981), width: 5),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.20),
                  blurRadius: 18.0,
                  spreadRadius: 2.0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12.0,
                  offset: const Offset(0, 6),
                ),
              ],
            );
          } else {
            cardDecoration = BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E23).withValues(alpha: 0.40)
                  : Colors.grey[200]!.withValues(alpha: 
                      0.65,
                    ), // Translucent charcoal glass
              borderRadius: BorderRadius.circular(16),
              border: Border(left: BorderSide(color: accentColor, width: 4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8.0,
                  offset: const Offset(0, 4),
                ),
              ],
            );
          }

          return Opacity(
            opacity: cardOpacity,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: isOngoing ? 18.0 : 10.0,
                    sigmaY: isOngoing ? 18.0 : 10.0,
                  ),
                  child: Container(
                    decoration: cardDecoration,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${classPeriod['startTime']} - ${classPeriod['endTime']}${classCount > 1 ? ' (${classCount}h)' : ''}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isOngoing
                                    ? const Color(0xFF10B981)
                                    : (isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                classPeriod['className'],
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            if (classPeriod['room'] != null &&
                                (classPeriod['room'] as String).isNotEmpty &&
                                classPeriod['room'] != '—')
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.location_solid,
                                    size: 14,
                                    color: isOngoing
                                        ? const Color(
                                            0xFF10B981,
                                          ).withValues(alpha: 0.7)
                                        : (isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    classPeriod['room'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isOngoing
                                          ? const Color(0xFF10B981)
                                          : (isDark
                                                ? Colors.grey[300]
                                                : Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

    void _showSettingsBottomSheet() {
    int tempSemester = selectedSemester;
    String tempBranch = selectedBranch.isEmpty ? 'CSE' : selectedBranch;
    String tempSection = selectedSection.isEmpty 
        ? (classesPerBranch[tempBranch]?.first ?? '') 
        : selectedSection;

    _isSavedPreferenceExists().then((exists) {
      if (mounted) {
        setState(() {
          savePreference = exists;
        });
      }
    });

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          final semesterIndex = tempSemester - 1;
          final sectionIndex = classesPerBranch[tempBranch] != null 
              ? (classesPerBranch[tempBranch]!.indexOf(tempSection) != -1 
                  ? classesPerBranch[tempBranch]!.indexOf(tempSection) 
                  : 0) 
              : 0;

          return Material(
            type: MaterialType.transparency,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24.0),
                topRight: Radius.circular(24.0),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                child: Container(
                  height: 480,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F11).withValues(alpha: 0.80),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24.0),
                      topRight: Radius.circular(24.0),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                ),
                                const Text('Timesheet Settings', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() {
                                      selectedBranch = tempBranch;
                                      selectedSemester = tempSemester;
                                      selectedSection = tempSection;
                                      scheduleData = null;
                                      isLoading = true;
                                    });
                                    _savePreference(tempBranch, tempSemester.toString(), '1st Year', tempSection, savePreference);
                                    if (savePreference) {
                                      EduMateToast.showSuccessCard(context, title: 'Preference Saved', description: 'Schedule preference saved.');
                                    }
                                    _fetchScheduleFromBackend();
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Done', style: TextStyle(color: AuthPalette.coral, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          const Divider(color: Colors.white10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Select Branch', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: CupertinoSlidingSegmentedControl<String>(
                                    groupValue: tempBranch,
                                    thumbColor: AuthPalette.coral.withValues(alpha: 0.70),
                                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                                    children: {
                                      'CSE': _buildSegmentText('CSE'),
                                      'CSCE': _buildSegmentText('CSCE'),
                                      'IT': _buildSegmentText('IT'),
                                      'CSSE': _buildSegmentText('CSSE'),
                                    },
                                    onValueChanged: (val) {
                                      if (val != null) {
                                        setModalState(() { 
                                          tempBranch = val; 
                                          if (classesPerBranch[tempBranch] != null && classesPerBranch[tempBranch]!.isNotEmpty) {
                                            tempSection = classesPerBranch[tempBranch]!.first;
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Select Semester', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: CupertinoSlidingSegmentedControl<int>(
                                    groupValue: tempSemester,
                                    thumbColor: AuthPalette.coral.withValues(alpha: 0.70),
                                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                                    children: {
                                      1: _buildSegmentText('1st'),
                                      2: _buildSegmentText('2nd'),
                                      3: _buildSegmentText('3rd'),
                                      4: _buildSegmentText('4th'),
                                      5: _buildSegmentText('5th'),
                                      6: _buildSegmentText('6th'),
                                      7: _buildSegmentText('7th'),
                                      8: _buildSegmentText('8th'),
                                    },
                                    onValueChanged: (val) {
                                      if (val != null) {
                                        setModalState(() { tempSemester = val; });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Select Section', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
                                        Expanded(
                                          child: CupertinoPicker(
                                            key: ValueKey(tempBranch), // Rebuild when branch changes
                                            magnification: 1.15,
                                            squeeze: 1.1,
                                            useMagnifier: true,
                                            itemExtent: 36.0,
                                            scrollController: FixedExtentScrollController(initialItem: sectionIndex),
                                            onSelectedItemChanged: (int index) {
                                              if (classesPerBranch[tempBranch] != null) {
                                                setModalState(() { tempSection = classesPerBranch[tempBranch]![index]; });
                                              }
                                            },
                                            children: (classesPerBranch[tempBranch] ?? []).map((s) => Center(child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 16)))).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 100,
                                    padding: const EdgeInsets.only(left: 8, top: 12),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Remember', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white70)),
                                        const SizedBox(height: 6),
                                        CupertinoSwitch(
                                          activeTrackColor: AuthPalette.deepTeal,
                                          value: savePreference,
                                          onChanged: (bool value) {
                                            setState(() { savePreference = value; });
                                            setModalState(() { savePreference = value; });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
Widget _buildSegmentText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _DaySelectorHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _DaySelectorHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _DaySelectorHeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}
