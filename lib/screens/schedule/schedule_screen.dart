import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import '../../constants/app_constants.dart';
import '../../config.dart';
import '../../services/shared_preferences_service.dart';
import '../../services/token_refresh_service.dart';

import '../../widgets/toast_manager.dart';
import 'schedule_settings_modal.dart';

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
  
  List<dynamic> rawElectiveData = [];
  Map<String, List<String>> availableElectives = {};
  Map<String, String> selectedElectives = {};
  int _lastRequestId = 0;
  bool _slideFromRight = true; // true = next day, false = prev day
  double _dragOffset = 0.0; // tracks real-time drag distance

  final List<String> branches = ['CSCE', 'CSE', 'IT', 'CSSE'];
  final Map<String, List<String>> classesPerBranch = {
    'CSCE': ['CSCE-1'],
    'CSE': List.generate(61, (i) => 'CSE-${i + 1}'),
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
      if (mounted) {
        setState(() {}); // Updates the current time indicator
        
        // Poll for updates in the background
        if (selectedBranch.isNotEmpty && selectedSemester > 0) {
          _fetchScheduleFromBackend(isPolling: true);
          _fetchAvailableElectives(selectedSemester, isPolling: true);
        }
      }
    });
  }

  Future<void> _loadSavedElectivePreferences() async {
    final Map<String, String> tempSelected = {};
    for (var group in availableElectives.keys) {
      final newKey = 'selectedElective_${selectedSemester}_$group';
      final legacyKey =
          'selectedElective_${selectedBranch}_${selectedSemester}_$group';
      final saved =
          await SharedPreferencesService.getString(newKey) ??
          await SharedPreferencesService.getString(legacyKey);
      if (saved != null) {
        tempSelected[group] = saved;
      }
    }
    setState(() {
      selectedElectives = tempSelected;
    });
  }

  Future<void> _fetchAvailableElectives(int semester,
      {bool isPolling = false, bool skipLoadPreferences = false}) async {
    final cacheKey = 'cached_electives_v2_$semester';
    bool hasCache = false;
    String? localUpdatedAt;

    // 1. Try to load from cache
    try {
      final cached = await SharedPreferencesService.getString(cacheKey);
      if (cached != null) {
        final decoded = jsonDecode(cached);
        if (decoded is Map && decoded.containsKey('raw') && decoded.containsKey('grouped')) {
          final raw = decoded['raw'] as List;
          localUpdatedAt = decoded['updatedAt'] as String?;
          final Map<String, List<String>> grouped = {};
          (decoded['grouped'] as Map).forEach((key, val) {
            grouped[key] = List<String>.from(val as List);
          });
          
          hasCache = true;
          if (mounted && !isPolling) {
            setState(() {
              rawElectiveData = raw;
              availableElectives = grouped;
            });
            if (!skipLoadPreferences) {
              await _loadSavedElectivePreferences();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error reading electives cache: $e');
    }

    try {
      // 2. Check metadata endpoint
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final metaUrl =
          '${Config.electiveBaseEndpoint}/$semester/metadata?t=$timestamp';
      final metaResponse = await TokenRefreshService.authenticatedGet(metaUrl).timeout(const Duration(seconds: 5));

      if (metaResponse.statusCode == 200) {
        final metaData = jsonDecode(metaResponse.body);
        final serverUpdatedAt = metaData['updatedAt'];

        if (hasCache && serverUpdatedAt != null) {
          if (localUpdatedAt == serverUpdatedAt) {
            return; // Up to date
          } else if (isPolling && mounted) {
            _showElectiveUpdateNotification(semester);
            return;
          }
        }
      }

      // 3. Fetch full electives payload
      final url = '${Config.electiveBaseEndpoint}/$semester?t=$timestamp';
      final response = await TokenRefreshService.authenticatedGet(url).timeout(const Duration(seconds: 7));
      
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true && resData['data'] != null) {
          final electivesList = resData['data']['electives'] as List;
          final serverUpdatedAtStr = resData['data']['updatedAt'] as String?;
          final Map<String, List<String>> grouped = {};
          for (var item in electivesList) {
            final group = item['electiveGroup'] as String;
            final name = item['name'] as String;
            grouped.putIfAbsent(group, () => []).add(name);
          }

          // Save to cache
          final cacheData = {
            'updatedAt': serverUpdatedAtStr,
            'raw': electivesList,
            'grouped': grouped,
          };
          await SharedPreferencesService.setString(cacheKey, jsonEncode(cacheData));

          if (mounted) {
            setState(() {
              rawElectiveData = electivesList;
              availableElectives = grouped;
            });
            if (!skipLoadPreferences) {
              await _loadSavedElectivePreferences();
            }
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching electives: $e');
    }
    
    if (!hasCache && mounted && !isPolling) {
      setState(() {
        rawElectiveData = [];
        availableElectives = {};
        selectedElectives = {};
      });
    }
  }

  void _showElectiveUpdateNotification(int semester) {
    if (!mounted) return;
    EduMateToast.showCompact(
      context,
      message: 'Electives updated by admin',
      isSuccess: true,
      actionLabel: 'Refresh',
      onActionTap: () {
        _fetchAvailableElectives(semester, isPolling: false);
      },
      duration: const Duration(seconds: 10),
    );
  }

  Future<Map<String, List<String>>> _getElectivesForSettings(int semester) async {
    // Use the same unified cache as the main elective fetch
    final cacheKey = 'cached_electives_v2_$semester';
    try {
      final cached = await SharedPreferencesService.getString(cacheKey);
      if (cached != null) {
        final decoded = jsonDecode(cached);
        if (decoded is Map && decoded.containsKey('grouped')) {
          final Map<String, List<String>> grouped = {};
          (decoded['grouped'] as Map).forEach((key, val) {
            grouped[key] = List<String>.from(val as List);
          });
          // Kick off a background refresh to keep cache fresh
          _fetchAndCacheElectivesInBackground(semester);
          return grouped;
        }
      }
    } catch (e) {
      debugPrint('Error reading electives cache: $e');
    }

    return _fetchAndCacheElectives(semester);
  }

  Future<Map<String, List<String>>> _fetchAndCacheElectives(int semester) async {
    final cacheKey = 'cached_electives_v2_$semester';
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse('${Config.electiveBaseEndpoint}/$semester?t=$timestamp'),
      );
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true && resData['data'] != null) {
          final electivesList = resData['data']['electives'] as List;
          final serverUpdatedAt = resData['data']['updatedAt'] as String?;
          final Map<String, List<String>> grouped = {};
          for (var item in electivesList) {
            final group = item['electiveGroup'] as String;
            final name = item['name'] as String;
            grouped.putIfAbsent(group, () => []).add(name);
          }
          // Save to unified cache
          final cacheData = {
            'updatedAt': serverUpdatedAt,
            'raw': electivesList,
            'grouped': grouped,
          };
          await SharedPreferencesService.setString(cacheKey, jsonEncode(cacheData));
          return grouped;
        }
      }
    } catch (e) {
      debugPrint('Error fetching electives for settings: $e');
    }
    return {};
  }

  void _fetchAndCacheElectivesInBackground(int semester) {
    final cacheKey = 'cached_electives_v2_$semester';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    http.get(Uri.parse('${Config.electiveBaseEndpoint}/$semester?t=$timestamp')).then((response) {
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true && resData['data'] != null) {
          final electivesList = resData['data']['electives'] as List;
          final serverUpdatedAt = resData['data']['updatedAt'] as String?;
          final Map<String, List<String>> grouped = {};
          for (var item in electivesList) {
            final group = item['electiveGroup'] as String;
            final name = item['name'] as String;
            grouped.putIfAbsent(group, () => []).add(name);
          }
          final cacheData = {
            'updatedAt': serverUpdatedAt,
            'raw': electivesList,
            'grouped': grouped,
          };
          SharedPreferencesService.setString(cacheKey, jsonEncode(cacheData));
        }
      }
    }).catchError((e) {
      debugPrint('Background fetch error for electives: $e');
    });
  }

  String? _matchElectiveGroup(String className) {
    final cleanName = className.toUpperCase().replaceAll(RegExp(r'[\s\-_]+'), '');

    // Check against all known elective groups (from API data)
    final allGroups = {...availableElectives, ...{for (var k in selectedElectives.keys) k: <String>[]}};
    for (var group in allGroups.keys) {
      final cleanGroup = group.toUpperCase().replaceAll(RegExp(r'[\s\-_]+'), '');
      // Exact match after normalization
      if (cleanName == cleanGroup) return group;
      // Handle common aliases: "Professional Elective 1" -> "PE1", "Open Elective 1" -> "OE1"
      final aliasMap = <String, List<String>>{
        cleanGroup: _generateAliases(cleanGroup),
      };
      for (var alias in aliasMap[cleanGroup]!) {
        if (cleanName == alias || cleanName.contains(alias)) return group;
      }
    }
    return null;
  }

  /// Generate common aliases for an elective group name.
  /// e.g., PE1 -> [PROFESSIONALELECTIVE1], OE1 -> [OPENELECTIVE1]
  List<String> _generateAliases(String normalizedGroup) {
    final aliases = <String>[];
    final peMatch = RegExp(r'^PE(\d+)$').firstMatch(normalizedGroup);
    if (peMatch != null) {
      aliases.add('PROFESSIONALELECTIVE${peMatch.group(1)}');
    }
    final oeMatch = RegExp(r'^OE(\d+)$').firstMatch(normalizedGroup);
    if (oeMatch != null) {
      aliases.add('OPENELECTIVE${oeMatch.group(1)}');
    }
    final kMatch = RegExp(r'^KEXPLORE$').firstMatch(normalizedGroup);
    if (kMatch != null) {
      aliases.add('K-EXPLORE');
      aliases.add('KEXPLORE');
    }
    return aliases;
  }

  String _getElectiveRoom(String electiveName, int day, String startTime) {
    for (var elective in rawElectiveData) {
      if (elective['name'] == electiveName && elective['periods'] is List) {
        final periods = elective['periods'] as List;
        for (var p in periods) {
          if (p['day'] == day && p['startTime'] == startTime) {
            return p['room'] ?? '';
          }
        }
      }
    }
    return '';
  }

  Future<void> _loadSavedPreferenceAndFetchSchedule() async {
    final savedClass = await SharedPreferencesService.getString('timesheet_semester');
    final savedBranch = await SharedPreferencesService.getString('timesheet_branch');
    final savedSection = await SharedPreferencesService.getString('timesheet_section');
    final saved = await SharedPreferencesService.getBool('timesheet_save_preference');

    if (saved && savedClass != null) {
      setState(() {
        if (savedBranch != null) selectedBranch = savedBranch;
        selectedSemester = int.tryParse(savedClass.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
        if (savedSection != null) selectedSection = savedSection;
        savePreference = true;
        
        // Dynamically add the section to the dropdown list if it's not present
        if (selectedBranch.isNotEmpty && selectedSection.isNotEmpty) {
          classesPerBranch.putIfAbsent(selectedBranch, () => []);
          if (!classesPerBranch[selectedBranch]!.contains(selectedSection)) {
            classesPerBranch[selectedBranch]!.add(selectedSection);
          }
        }
      });
      _fetchAvailableElectives(selectedSemester);
      // Fetch schedule for saved class
      _fetchScheduleFromBackend();
    } else {
      setState(() {
        selectedBranch = 'CSE';
        selectedSemester = 1;
        selectedSection = 'CSE-1';
      });
      _fetchAvailableElectives(selectedSemester);
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
      await SharedPreferencesService.setString('timesheet_branch', branch);
      await SharedPreferencesService.setString('timesheet_semester', classValue);
      await SharedPreferencesService.setString('timesheet_section', sectionValue);
      await SharedPreferencesService.setString('timesheet_year', yearValue);
      await SharedPreferencesService.setBool('timesheet_save_preference', true);
    } else {
      await SharedPreferencesService.remove('timesheet_branch');
      await SharedPreferencesService.remove('timesheet_semester');
      await SharedPreferencesService.remove('timesheet_section');
      await SharedPreferencesService.remove('timesheet_year');
      await SharedPreferencesService.setBool('timesheet_save_preference', false);
    }
  }


  Future<void> _cacheScheduleData(String semester, dynamic data) async {
    final cacheKey = 'schedule_$semester';
    await SharedPreferencesService.setString(cacheKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> _getCachedScheduleData(String semester) async {
    final cacheKey = 'schedule_$semester';
    final cachedData = await SharedPreferencesService.getString(cacheKey);
    if (cachedData != null) {
      try {
        return jsonDecode(cachedData) as Map<String, dynamic>?;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> _fetchScheduleFromBackend({bool isPolling = false}) async {
    final currentRequestId = ++_lastRequestId;
    final requestedSemester = selectedSemester;

    // Load from cache
    final cachedData = await _getCachedScheduleData(
      requestedSemester.toString(),
    );
    final hasCache = cachedData != null;
    
    if (hasCache && !isPolling) {
      if (mounted) {
        setState(() {
          scheduleData = cachedData;
          isLoading = false;
        });
      }
    }

    // Set loading state if not polling and no cache
    if (!hasCache && !isPolling && mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      // 1. Check Metadata Endpoint
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final metaUrl = '${Config.scheduleBaseEndpoint}/$requestedSemester/metadata?t=$timestamp';
      final metaResponse = await TokenRefreshService.authenticatedGet(metaUrl).timeout(const Duration(seconds: 5));

      if (metaResponse.statusCode == 200) {
        final metaData = jsonDecode(metaResponse.body);
        final serverUpdatedAt = metaData['updatedAt'];

        // If we have cache, compare timestamps
        if (hasCache && serverUpdatedAt != null) {
          final localUpdatedAt = cachedData['updatedAt'];
          
          if (localUpdatedAt == serverUpdatedAt) {
            // Data is up to date, no need to fetch full payload
            if (!isPolling && mounted) {
              setState(() => isLoading = false);
            }
            return; 
          } else if (isPolling && mounted) {
            // Data changed while polling, show notification!
            _showUpdateNotification();
            return;
          }
        }
      }

      // 2. Fetch full schedule if no cache or outdated
      final url = '${Config.scheduleBaseEndpoint}/$requestedSemester?t=$timestamp';
      final response = await TokenRefreshService.authenticatedGet(url).timeout(const Duration(seconds: 7));

      if (currentRequestId != _lastRequestId) return; // Discard if user changed tabs

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is Map && responseData.containsKey('data')) {
          final classData = responseData['data'];
          await _cacheScheduleData(requestedSemester.toString(), classData);

          if (mounted) {
            setState(() {
              scheduleData = classData;
              isLoading = false;
            });
          }
        } else {
          await _cacheScheduleData(requestedSemester.toString(), responseData);
          if (mounted) {
            setState(() {
              scheduleData = responseData;
              isLoading = false;
            });
          }
        }
      } else if (response.statusCode == 404) {
        if (!hasCache && mounted) {
          setState(() {
            scheduleData = null;
            isLoading = false;
          });
        }
      } else {
        if (!hasCache && mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching schedule from backend: $e');
      if (mounted) {
        setState(() {
          if (!hasCache) {
            scheduleData = null;
          }
          isLoading = false;
        });
      }
    }
  }

  void _showUpdateNotification() {
    if (!mounted) return;
    EduMateToast.showCompact(
      context,
      message: 'Schedule updated by admin',
      isSuccess: true,
      actionLabel: 'Refresh',
      onActionTap: () {
        _fetchScheduleFromBackend(isPolling: false);
      },
      duration: const Duration(seconds: 10),
    );
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
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Showing for Semester $selectedSemester ',
                                  ),
                                  TextSpan(
                                    text: '(${selectedSection.isNotEmpty ? selectedSection : selectedBranch})',
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
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

  List<dynamic> _processPeriods(List<dynamic> originalPeriods, int dayOfWeek) {
    final periods = originalPeriods.map((p) => Map<String, dynamic>.from(p)).toList();
    for (var period in periods) {
      final className = period['className']?.toString() ?? '';
      final matchedGroup = _matchElectiveGroup(className);
      if (matchedGroup != null) {
        final chosenElective = selectedElectives[matchedGroup];
        if (chosenElective != null) {
          period['className'] = chosenElective;
          period['_replacedByElective'] = true; // Mark so append section skips this slot
          period['isElective'] = true;
          final room = _getElectiveRoom(chosenElective, dayOfWeek, period['startTime']?.toString() ?? '');
          if (room.isNotEmpty) {
            period['room'] = room;
          }
        }
      }
    }
    return periods;
  }

  List<dynamic> _getClassesForDay(int dayOfWeek) {
    // Filter only weekdays (Monday-Friday)
    if (dayOfWeek < 1 || dayOfWeek > 5) {
      return [];
    }

    List<dynamic> dayClasses = [];

    try {
      // Try to get data from API first
      if (scheduleData != null) {
        List<dynamic>? classes = scheduleData!['classes'] as List<dynamic>?;
        if (classes != null && classes.isNotEmpty) {
          var section = classes.firstWhere(
            (s) => s['name'] == selectedSection,
            orElse: () => null,
          );
          
          // Smart correction if no exact match is found
          if (section == null) {
            final normalizedSaved = selectedSection.toUpperCase().replaceAll(RegExp(r'\s+|-'), '');
            section = classes.firstWhere((s) {
              final normName = s['name'].toString().toUpperCase().replaceAll(RegExp(r'\s+|-'), '');
              return normalizedSaved == normName;
            }, orElse: () => null);

            if (section == null && normalizedSaved.startsWith('CSE')) {
              final correctedSearch = 'CS${normalizedSaved.substring(3)}';
              section = classes.firstWhere((s) {
                final normName = s['name'].toString().toUpperCase().replaceAll(RegExp(r'\s+|-'), '');
                return correctedSearch == normName;
              }, orElse: () => null);
            }

            // Fix for when section is saved as just a number (e.g., "22") instead of "CS 22"
            if (section == null && RegExp(r'^\d+$').hasMatch(normalizedSaved)) {
              final correctedSearch = '${selectedBranch.toUpperCase()}$normalizedSaved';
              section = classes.firstWhere((s) {
                final normName = s['name'].toString().toUpperCase().replaceAll(RegExp(r'\s+|-'), '');
                return correctedSearch == normName;
              }, orElse: () => null);
            }

            section ??= classes.first;

            if (section != null) {
              // Safely update selectedSection in a post-frame callback or schedule future to avoid setState build warnings
              final dbName = section['name'] as String;
              String uiFormattedName = dbName.trim();
              if (dbName.startsWith('CS') && !dbName.startsWith('CSCE') && !dbName.startsWith('CSSE')) {
                final numberPart = dbName.substring(2).trim();
                if (int.tryParse(numberPart) != null) {
                  uiFormattedName = 'CSE-$numberPart';
                }
              } else if (dbName.startsWith('CSCE')) {
                final numberPart = dbName.substring(4).trim();
                if (int.tryParse(numberPart) != null) {
                  uiFormattedName = 'CSCE-$numberPart';
                }
              } else if (dbName.startsWith('CSSE')) {
                final numberPart = dbName.substring(4).trim();
                if (int.tryParse(numberPart) != null) {
                  uiFormattedName = 'CSSE-$numberPart';
                }
              } else if (dbName.startsWith('IT')) {
                final numberPart = dbName.substring(2).trim();
                if (int.tryParse(numberPart) != null) {
                  uiFormattedName = 'IT-$numberPart';
                }
              }

              Future.microtask(() {
                if (mounted && selectedSection != uiFormattedName) {
                  setState(() {
                    selectedSection = uiFormattedName;
                  });
                }
              });
            }
          }

          if (section != null && section['schedule'] is List) {
            var schedule = section['schedule'] as List;
            for (int i = 0; i < schedule.length; i++) {
              var dayData = schedule[i];
              final dayNum = dayData['day'] is int
                  ? dayData['day'] as int
                  : int.tryParse(dayData['day'].toString()) ?? -1;
              if (dayNum == dayOfWeek && dayData['periods'] is List) {
                dayClasses = _processPeriods(dayData['periods'], dayOfWeek);
                break;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error in _getClassesForDay: $e');
    }

    // If no classes were fetched from the database, fall back to static data
    if (dayClasses.isEmpty) {
      final schedule = classSchedules[selectedSemester.toString()] ?? {};
      final result = schedule[dayOfWeek] ?? [];
      dayClasses = _processPeriods(result, dayOfWeek);
    }

    // Collect time slots already occupied by substituted electives
    // to prevent double-display when _processPeriods already replaced a placeholder
    final Set<String> occupiedSlots = {};
    for (var cls in dayClasses) {
      if (cls['_replacedByElective'] == true) {
        occupiedSlots.add('${cls['startTime']}-${cls['endTime']}');
      }
    }

    // Append chosen electives for this day (only for slots NOT already substituted)
    for (var entry in selectedElectives.entries) {
      final electiveName = entry.value;
      final electiveItem = rawElectiveData.firstWhere(
        (e) => e['name'] == electiveName,
        orElse: () => null,
      );
      if (electiveItem != null && electiveItem['periods'] is List) {
        final periods = electiveItem['periods'] as List;
        for (var p in periods) {
          final pDay = p['day'] is int ? p['day'] as int : int.tryParse(p['day'].toString()) ?? -1;
          if (pDay == dayOfWeek) {
            final slotKey = '${p['startTime']}-${p['endTime']}';
            if (!occupiedSlots.contains(slotKey)) {
              dayClasses.add({
                'startTime': p['startTime'] ?? '',
                'endTime': p['endTime'] ?? '',
                'className': electiveName,
                'room': p['room'] ?? '',
                'isElective': true,
              });
              occupiedSlots.add(slotKey); // Prevent duplicates within raw data too
            }
          }
        }
      }
    }

    // Sort combined list by startTime
    dayClasses.sort((a, b) {
      final aTime = a['startTime'].toString();
      final bTime = b['startTime'].toString();
      return aTime.compareTo(bTime);
    });

    return dayClasses;
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

  // Shared save handler for both settings variants
  void _onSettingsSaved(String branch, int semester, String section, Map<String, String> electives, bool savePref) async {
    setState(() {
      selectedBranch = branch;
      selectedSemester = semester;
      selectedSection = section;
      selectedElectives = electives;
      if (savePref) {
        savePreference = true;
      }
      scheduleData = null;
      isLoading = true;
    });
    
    if (savePref) {
      await _savePreference(branch, semester.toString(), '1st Year', section, true);
      
      for (final entry in electives.entries) {
        final group = entry.key;
        final val = entry.value;
        if (val != 'Not Selected') {
          await SharedPreferencesService.setString(
            'selectedElective_${semester}_$group',
            val,
          );
        } else {
          await SharedPreferencesService.remove(
            'selectedElective_${semester}_$group',
          );
        }
      }
    }

    // If we are just showing (savePref == false), we skip loading preferences 
    // so we don't overwrite the temporary electives we just set in state.
    _fetchAvailableElectives(semester, skipLoadPreferences: !savePref);
    _fetchScheduleFromBackend();
    
    if (mounted) {
      Navigator.pop(context);
      if (savePref) {
        EduMateToast.showSuccessCard(
          context,
          title: 'Preference Saved',
          description: 'Your settings have been saved successfully.',
        );
      }
    }
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettingsBottomSheet(
        initialBranch: selectedBranch,
        initialSemester: selectedSemester,
        initialSection: selectedSection,
        initialSelectedElectives: selectedElectives,

        hasPreference: savePreference, // Pass the savePreference flag
        fetchSections: _fetchSectionsList,
        fetchElectives: _getElectivesForSettings,
        onSave: _onSettingsSaved,
      ),
    );
  }



  Future<List<String>> _fetchSectionsList(int semester) async {
    try {
      // 1. Try to load from cache first
      final cacheKey = 'schedule_$semester';
      final cachedData = await SharedPreferencesService.getString(cacheKey);
      if (cachedData != null) {
        final decoded = jsonDecode(cachedData);
        if (decoded is Map && decoded.containsKey('classes')) {
          final classesList = decoded['classes'] as List;
          return classesList.map((c) => c['name'] as String).toList()..sort();
        }
      }

      // 2. Fetch from backend
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse('${Config.scheduleBaseEndpoint}/$semester?t=$timestamp'),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is Map && responseData.containsKey('data')) {
          final classData = responseData['data'];
          if (classData is Map && classData.containsKey('classes')) {
            final classesList = classData['classes'] as List;
            // Cache it
            return classesList.map((c) => c['name'] as String).toList()..sort();
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching sections list: $e');
    }
    return [];
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
