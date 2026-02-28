import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import '../../config.dart';
import '../../services/shared_preferences_service.dart';

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
  String selectedClass = '';
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
      'selectedClass',
    );
    final savedBranch = await SharedPreferencesService.getString(
      'selectedBranch',
    );
    final saved = await SharedPreferencesService.getBool('savePreference');

    if (saved && savedClass != null && savedClass.isNotEmpty) {
      setState(() {
        if (savedBranch != null) selectedBranch = savedBranch;
        selectedClass = savedClass;
        savePreference = true;
      });
      _fetchScheduleFromBackend();
    } else {
      // Fallback: check profile data (branch/section) from SharedPreferences
      final profileBranch = await SharedPreferencesService.getBranch();
      final profileSection = await SharedPreferencesService.getSection();

      if (profileBranch != null &&
          profileBranch.isNotEmpty &&
          profileSection != null &&
          profileSection.isNotEmpty) {
        setState(() {
          selectedBranch = profileBranch;
          selectedClass = profileSection;
          savePreference = true;
        });
        // Auto-save these as timesheet preferences too
        await _savePreference(profileBranch, profileSection, true);
        _fetchScheduleFromBackend();
      } else {
        // No saved preference at all
        _fetchScheduleFromBackend();
      }
    }
  }

  Future<void> _savePreference(
    String branch,
    String classValue,
    bool shouldSave,
  ) async {
    if (shouldSave) {
      await SharedPreferencesService.setString('selectedBranch', branch);
      await SharedPreferencesService.setString('selectedClass', classValue);
      await SharedPreferencesService.setBool('savePreference', true);
    } else {
      await SharedPreferencesService.remove('selectedBranch');
      await SharedPreferencesService.remove('selectedClass');
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
        print('Error decoding cached schedule: $e');
        return null;
      }
    }
    return null;
  }

  Future<void> _fetchScheduleFromBackend() async {
    print('\n=== FETCH SCHEDULE START ===');
    print('Selected Class: $selectedClass');
    print('Selected Branch: $selectedBranch');

    final currentRequestId = ++_lastRequestId;
    final requestedClass = selectedClass; // Capture what class was requested
    final requestedBranch = selectedBranch;
    print('🆔 Request ID: $currentRequestId');
    print('📌 Captured class: $requestedClass');

    // Try to load from cache first
    print('📦 Checking cache for $requestedBranch/$requestedClass...');
    final cachedData = await _getCachedScheduleData(
      requestedBranch,
      requestedClass,
    );
    if (cachedData != null) {
      print('✅ Found cached schedule data');
      if (mounted) {
        setState(() {
          scheduleData = cachedData;
          isLoading = false;
        });
      }
      return;
    }

    // If no cache, fetch from backend
    print('❌ No cache found, fetching from backend...');
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url =
          '${Config.scheduleByClassEndpoint}/$requestedClass?t=$timestamp';
      print('API URL: $url');
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
        print(
          '❌ IGNORING STALE RESPONSE: Request #$currentRequestId is outdated (latest is #$_lastRequestId)',
        );
        print('   Requested: $requestedClass, Current: $selectedClass');
        return; // Discard this response, don't update UI
      }

      print('Response status: ${response.statusCode}');
      print('Response body length: ${response.body.length} bytes');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('=== RESPONSE DATA ===');
        print('Response has "data" key: ${responseData.containsKey("data")}');
        print(
          'Response has "success" key: ${responseData.containsKey("success")}',
        );

        // Handle the API response structure: { success: true, data: classSchedule }
        if (responseData is Map && responseData.containsKey('data')) {
          final classData = responseData['data'];
          print('Extracted class data:');
          print('  - Name: ${classData["name"]}');
          print('  - Has schedule key: ${classData.containsKey("schedule")}');

          if (classData.containsKey('schedule') &&
              classData['schedule'] is List) {
            final scheduleList = classData['schedule'] as List;
            print('  - Schedule days: ${scheduleList.length}');
            for (var day in scheduleList) {
              print(
                '    Day ${day["day"]}: ${day["periods"]?.length ?? 0} periods',
              );
            }
          }

          // Cache the schedule data for offline use
          await _cacheScheduleData(requestedBranch, requestedClass, classData);
          print('💾 Schedule data cached for offline use');

          if (mounted) {
            setState(() {
              scheduleData = classData;
              isLoading = false;
            });
          }
          print('✅ Schedule data updated');
        } else {
          print('⚠️ No data key in response, using full response');
          // Cache the schedule data for offline use
          await _cacheScheduleData(
            requestedBranch,
            requestedClass,
            responseData,
          );
          print('💾 Schedule data cached for offline use');
          if (mounted) {
            setState(() {
              scheduleData = responseData;
              isLoading = false;
            });
          }
        }
      } else if (response.statusCode == 404) {
        print('❌ Schedule not found for: $requestedClass');
        if (mounted) {
          setState(() {
            scheduleData = null;
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load schedule: ${response.statusCode}');
      }
      print('=== FETCH SCHEDULE END ===\n');
    } catch (e) {
      if (mounted) {
        setState(() {
          scheduleData = null;
          isLoading = false;
        });
      }
      print('❌ Error fetching schedule: $e');
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
              largeTitle: const Text('Timesheet'),
              backgroundColor: isDark
                  ? CupertinoColors.black.withOpacity(0.6)
                  : CupertinoColors.white.withOpacity(0.6),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _showBranchPicker,
                    child: Text(
                      selectedBranch.isEmpty ? 'Select Branch' : selectedBranch,
                      style: const TextStyle(
                        color: CupertinoColors.systemBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showClassPicker,
                    child: Text(
                      selectedClass.isEmpty ? 'Select Section' : selectedClass,
                      style: const TextStyle(
                        color: CupertinoColors.systemGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Day selector pinned below nav bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _DaySelectorHeaderDelegate(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      color: isDark
                          ? CupertinoColors.black.withOpacity(0.6)
                          : CupertinoColors.white.withOpacity(0.6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _buildWeekCalendarGrid(weekDates, isDark, now),
                    ),
                  ),
                ),
              ),
            ),
            if (selectedBranch.isEmpty || selectedClass.isEmpty)
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
                        'Loading schedule for $selectedClass...',
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
                        'No schedule data available for $selectedClass',
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: CupertinoColors.systemBlue.withOpacity(0.4),
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
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? CupertinoColors.systemBlue
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isToday && !isSelected
                      ? CupertinoColors.systemBlue.withOpacity(0.5)
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
    print('\n=== GET CLASSES FOR DAY ===');
    print('Day of week: $dayOfWeek (1=Mon, 7=Sun)');
    print('Selected class: $selectedClass');

    // Convert Flutter weekday (Mon=1, Sun=7) to our day format (Mon=1, Fri=5)
    // Filter only weekdays (Monday-Friday)
    if (dayOfWeek < 1 || dayOfWeek > 5) {
      print('❌ Day $dayOfWeek is not a weekday (1-5), returning empty');
      return [];
    }

    print('ScheduleData is null: ${scheduleData == null}');

    // Try to get data from API first
    if (scheduleData != null) {
      print('ScheduleData keys: ${scheduleData!.keys.toList()}');

      List<dynamic>? schedule = scheduleData!['schedule'] as List<dynamic>?;

      if (schedule != null) {
        print('📋 Schedule found with ${schedule.length} days');
        for (int i = 0; i < schedule.length; i++) {
          var dayData = schedule[i];
          print(
            '  Day ${dayData['day']}: ${dayData['periods']?.length ?? 0} periods',
          );
          if (dayData['day'] == dayOfWeek) {
            print('✅ Found matching day $dayOfWeek');
            if (dayData['periods'] is List) {
              final periods = dayData['periods'] as List;
              print('   Returning ${periods.length} periods:');
              for (var p in periods) {
                print(
                  '   - ${p['startTime']}-${p['endTime']}: ${p['className']}',
                );
              }
              return periods;
            }
          }
        }
        print('❌ Day $dayOfWeek not found in schedule');
      } else {
        print('⚠️ Schedule key exists but is not a List');
      }
    }

    print('🔄 No API data found, using static fallback');
    // Fallback to static data
    final schedule = classSchedules[selectedClass] ?? {};
    final result = schedule[dayOfWeek] ?? [];
    print('Fallback result: ${result.length} periods');
    print('=== GET CLASSES END ===\n');
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
                'Loading schedule for $selectedClass...',
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
                'No schedule data available for $selectedClass',
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
            accentColor = CupertinoColors.systemBlue;
          }

          final backgroundColor = isPassed
              ? (isDark ? Colors.grey[900] : Colors.grey[200])
              : (isDark ? Colors.grey[850] : Colors.grey[300]);

          final double cardOpacity = isPassed ? 0.5 : 1.0;

          return Opacity(
            opacity: cardOpacity,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: Border(
                    left: BorderSide(color: accentColor, width: 4),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${classPeriod['startTime']} - ${classPeriod['endTime']}${classCount > 1 ? ' (${classCount}h)' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
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
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                classPeriod['room'],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
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
          );
        }),
      ],
    );
  }

  void _showBranchPicker() {
    int selectedIndex = branches.indexOf(selectedBranch);
    if (selectedIndex == -1) selectedIndex = 0;

    // Sync savePreference with actual saved state from SharedPreferences
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
        builder: (BuildContext context, StateSetter setState) => Material(
          child: Container(
            height: 280,
            padding: const EdgeInsets.only(top: 6),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const Text(
                          'Select Branch',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        CupertinoButton(
                          onPressed: () {
                            if (savePreference) {
                              _savePreference(
                                selectedBranch,
                                selectedClass,
                                true,
                              );
                            }
                            Navigator.pop(context);
                          },
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: Colors.grey[400],
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      magnification: 1.22,
                      squeeze: 1.2,
                      useMagnifier: true,
                      itemExtent: 32.0,
                      scrollController: FixedExtentScrollController(
                        initialItem: selectedIndex,
                      ),
                      onSelectedItemChanged: (int index) {
                        // Clear old data immediately and update selection
                        this.setState(() {
                          selectedBranch = branches[index];
                          selectedClass = classesPerBranch[branches[index]]![0];
                          scheduleData = null; // Clear old schedule data
                          isLoading = true; // Show loading state
                        });

                        // Fetch new schedule
                        _fetchScheduleFromBackend();
                      },
                      children: List<Widget>.generate(
                        branches.length,
                        (int index) => Center(child: Text(branches[index])),
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

  void _showClassPicker() {
    final classes = classesPerBranch[selectedBranch] ?? [];
    int selectedIndex = classes.indexOf(selectedClass);
    if (selectedIndex == -1) selectedIndex = 0;

    // Sync savePreference with actual saved state from SharedPreferences
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
        builder: (BuildContext context, StateSetter setState) => Material(
          child: Container(
            height: 320,
            padding: const EdgeInsets.only(top: 6),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        CupertinoButton(
                          onPressed: () {
                            if (savePreference) {
                              _savePreference(
                                selectedBranch,
                                selectedClass,
                                true,
                              );
                            }
                            Navigator.pop(context);
                          },
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Save Preference',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        CupertinoSwitch(
                          value: savePreference,
                          onChanged: (bool value) {
                            setState(() {
                              savePreference = value;
                            });
                            this.setState(() {
                              savePreference = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: Colors.grey[400],
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      magnification: 1.22,
                      squeeze: 1.2,
                      useMagnifier: true,
                      itemExtent: 32.0,
                      scrollController: FixedExtentScrollController(
                        initialItem: selectedIndex,
                      ),
                      onSelectedItemChanged: (int index) {
                        // Clear old data immediately and update selection
                        print('\n🔄 CLASS PICKER CHANGED');
                        print('Old class: $selectedClass');
                        print('New class: ${classes[index]}');

                        this.setState(() {
                          selectedClass = classes[index];
                          scheduleData = null; // Clear old schedule data
                          isLoading = true; // Show loading state

                          print(
                            '✅ State updated: $selectedClass, loading: $isLoading, data cleared',
                          );
                        });

                        // Fetch new schedule
                        _fetchScheduleFromBackend();
                      },
                      children: List<Widget>.generate(
                        classes.length,
                        (int index) => Center(child: Text(classes[index])),
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
}

class _DaySelectorHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _DaySelectorHeaderDelegate({required this.child});

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 60;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _DaySelectorHeaderDelegate oldDelegate) => true;
}
