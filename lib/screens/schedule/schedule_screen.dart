import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime selectedDate;
  late DateTime weekStartDate;
  String selectedBranch = '';
  String selectedClass = '';
  bool savePreference = false;
  Map<String, dynamic>? scheduleData;
  bool isLoading = false;
  int _lastRequestId = 0;

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
    selectedDate = DateTime.now();
    weekStartDate = selectedDate.subtract(
      Duration(days: selectedDate.weekday % 7),
    );
    _loadSavedPreferenceAndFetchSchedule();
  }

  Future<void> _loadSavedPreferenceAndFetchSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final savedClass = prefs.getString('selectedClass');
    final savedBranch = prefs.getString('selectedBranch');
    final saved = prefs.getBool('savePreference') ?? false;

    if (saved && savedClass != null) {
      setState(() {
        if (savedBranch != null) selectedBranch = savedBranch;
        selectedClass = savedClass;
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
    bool shouldSave,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (shouldSave) {
      await prefs.setString('selectedBranch', branch);
      await prefs.setString('selectedClass', classValue);
      await prefs.setBool('savePreference', true);
    } else {
      await prefs.remove('selectedBranch');
      await prefs.remove('selectedClass');
      await prefs.setBool('savePreference', false);
    }
  }

  Future<bool> _isSavedPreferenceExists() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('savePreference') ?? false;
  }

  Future<void> _cacheScheduleData(
    String branch,
    String classValue,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'schedule_${branch}_$classValue';
    await prefs.setString(cacheKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> _getCachedScheduleData(
    String branch,
    String classValue,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'schedule_${branch}_$classValue';
    final cachedData = prefs.getString(cacheKey);
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

  void _goToPreviousWeek() {
    setState(() {
      weekStartDate = weekStartDate.subtract(const Duration(days: 7));
    });
  }

  void _goToNextWeek() {
    setState(() {
      weekStartDate = weekStartDate.add(const Duration(days: 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weekDates = getWeekDates();
    final now = DateTime.now();

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        middle: const Text('Timesheet'),
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
        backgroundColor: isDark
            ? CupertinoColors.black.withOpacity(0.6)
            : CupertinoColors.white.withOpacity(0.6),
        previousPageTitle: 'Back',
      ),
      child: SafeArea(
        child: Material(
          color: isDark ? Colors.black : CupertinoColors.white,
          child: selectedBranch.isEmpty || selectedClass.isEmpty
              ? Center(
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
                )
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildWeekCalendarGrid(weekDates, isDark, now),
                          const SizedBox(height: 24),
                          _buildClassBlocksForSelectedDay(isDark),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  Widget _buildWeekCalendarGrid(
    List<DateTime> weekDates,
    bool isDark,
    DateTime now,
  ) {
    final dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final selectedIndex = weekDates.indexWhere(
      (date) =>
          date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day,
    );

    return CupertinoSlidingSegmentedControl<int>(
      backgroundColor: CupertinoColors.systemGrey2,
      thumbColor: CupertinoColors.systemBlue,
      groupValue: selectedIndex >= 0 ? selectedIndex : 0,
      onValueChanged: (int? value) {
        if (value != null) {
          setState(() {
            selectedDate = weekDates[value];
          });
        }
      },
      children: {
        for (int i = 0; i < 7; i++)
          i: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(dayLabels[i]),
          ),
      },
    );
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(classes.length, (index) {
          final classPeriod = classes[index] as Map<String, dynamic>;

          if (classPeriod['className'] == '—') {
            return const SizedBox.shrink();
          }

          final backgroundColor = isDark ? Colors.grey[850] : Colors.grey[300];
          const primaryBlue = CupertinoColors.systemBlue;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${classPeriod['startTime']} - ${classPeriod['endTime']}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: const Border(
                      left: BorderSide(color: primaryBlue, width: 4),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classPeriod['className'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (classPeriod['room'] != null &&
                          (classPeriod['room'] as String).isNotEmpty &&
                          classPeriod['room'] != '—')
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.location,
                              size: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              classPeriod['room'],
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
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
