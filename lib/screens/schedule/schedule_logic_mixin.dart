import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config.dart';
import '../../services/shared_preferences_service.dart';
import '../../services/token_refresh_service.dart';
import '../../widgets/toast_manager.dart';
import 'schedule_screen.dart';

mixin ScheduleLogicMixin on State<ScheduleScreen> {
  late DateTime selectedDate;
  late DateTime weekStartDate;
  Timer? refreshTimer;
  String selectedBranch = '';
  int selectedSemester = 1;
  String selectedSection = '';
  
  bool savePreference = false;
  Map<String, dynamic>? scheduleData;
  bool isLoading = false;
  List<dynamic> currentYearHolidays = [];
  
  List<dynamic> rawElectiveData = [];
  Map<String, List<String>> availableElectives = {};
  Map<String, String> selectedElectives = {};
  int lastRequestId = 0;
  bool slideFromRight = true;
  double dragOffset = 0.0;

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


  void initializeScheduleState() {
    selectedDate = DateTime.now();
    weekStartDate = selectedDate.subtract(
      Duration(days: selectedDate.weekday % 7),
    );
    loadSavedPreferenceAndFetchSchedule();
    _fetchCurrentYearHolidays();
    startRefreshTimer();
  }

  Future<void> _fetchCurrentYearHolidays() async {
    try {
      final response = await http.get(Uri.parse('${Config.holidayBaseEndpoint}/${DateTime.now().year}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              currentYearHolidays = data['data'] as List<dynamic>;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching holidays for schedule: $e');
    }
  }

  void startRefreshTimer() {
    refreshTimer?.cancel();
    refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {}); // Updates the current time indicator
        
        // Poll for updates in the background
        if (selectedBranch.isNotEmpty && selectedSemester > 0) {
          fetchScheduleFromBackend(isPolling: true);
          fetchAvailableElectives(selectedSemester, isPolling: true);
        }
      }
    });
  }

  void disposeScheduleState() {
    refreshTimer?.cancel();
  }

  Map<String, dynamic>? getHolidayForSelectedDate() {
    if (currentYearHolidays.isEmpty) return null;
    final date = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    for (var holiday in currentYearHolidays) {
      if (holiday['startDate'] == null || holiday['endDate'] == null) continue;
      final startDate = DateTime.parse(holiday['startDate']);
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final endDate = DateTime.parse(holiday['endDate']);
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      
      if (date.isAtSameMomentAs(start) || date.isAtSameMomentAs(end) || (date.isAfter(start) && date.isBefore(end))) {
        return holiday;
      }
    }
    return null;
  }

  Future<void> loadSavedElectivePreferences() async {
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

  Future<void> fetchAvailableElectives(int semester,
      {bool isPolling = false, bool skipLoadPreferences = false}) async {
    final cacheKey = 'cached_electives_v2_$semester';
    bool hasCache = false;
    String? localUpdatedAt;

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
              await loadSavedElectivePreferences();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error reading electives cache: $e');
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final metaUrl = '${Config.electiveBaseEndpoint}/$semester/metadata?t=$timestamp';
      final metaResponse = await TokenRefreshService.authenticatedGet(metaUrl).timeout(const Duration(seconds: 5));

      if (metaResponse.statusCode == 200) {
        final metaData = jsonDecode(metaResponse.body);
        final serverUpdatedAt = metaData['updatedAt'];

        if (hasCache && serverUpdatedAt != null) {
          if (localUpdatedAt == serverUpdatedAt) {
            return;
          } else if (isPolling && mounted) {
            showElectiveUpdateNotification(semester);
            return;
          }
        }
      }

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
              await loadSavedElectivePreferences();
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

  void showElectiveUpdateNotification(int semester) {
    if (!mounted) return;
    EduMateToast.showCompact(
      context,
      message: 'Electives updated by admin',
      isSuccess: true,
      actionLabel: 'Refresh',
      onActionTap: () {
        fetchAvailableElectives(semester, isPolling: false);
      },
      duration: const Duration(seconds: 10),
    );
  }

  Future<void> loadSavedPreferenceAndFetchSchedule() async {
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
        
        if (selectedBranch.isNotEmpty && selectedSection.isNotEmpty) {
          classesPerBranch.putIfAbsent(selectedBranch, () => []);
          if (!classesPerBranch[selectedBranch]!.contains(selectedSection)) {
            classesPerBranch[selectedBranch]!.add(selectedSection);
          }
        }
      });
      fetchAvailableElectives(selectedSemester);
      fetchScheduleFromBackend();
    } else {
      setState(() {
        selectedBranch = 'CSE';
        selectedSemester = 1;
        selectedSection = 'CSE-1';
      });
      fetchAvailableElectives(selectedSemester);
      fetchScheduleFromBackend();
    }
  }

  Future<void> cacheScheduleData(String semester, dynamic data) async {
    final cacheKey = 'schedule_$semester';
    await SharedPreferencesService.setString(cacheKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getCachedScheduleData(String semester) async {
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

  Future<void> fetchScheduleFromBackend({bool isPolling = false}) async {
    final currentRequestId = ++lastRequestId;
    final requestedSemester = selectedSemester;

    final cachedData = await getCachedScheduleData(requestedSemester.toString());
    final hasCache = cachedData != null;
    
    if (hasCache && !isPolling) {
      if (mounted) {
        setState(() {
          scheduleData = cachedData;
          isLoading = false;
        });
      }
    }

    if (!hasCache && !isPolling && mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final metaUrl = '${Config.scheduleBaseEndpoint}/$requestedSemester/metadata?t=$timestamp';
      final metaResponse = await TokenRefreshService.authenticatedGet(metaUrl).timeout(const Duration(seconds: 5));

      if (metaResponse.statusCode == 200) {
        final metaData = jsonDecode(metaResponse.body);
        final serverUpdatedAt = metaData['updatedAt'];

        if (hasCache && serverUpdatedAt != null) {
          final localUpdatedAt = cachedData['updatedAt'];
          
          if (localUpdatedAt == serverUpdatedAt) {
            if (!isPolling && mounted) {
              setState(() => isLoading = false);
            }
            return; 
          } else if (isPolling && mounted) {
            showUpdateNotification();
            return;
          }
        }
      }

      final url = '${Config.scheduleBaseEndpoint}/$requestedSemester?t=$timestamp';
      final response = await TokenRefreshService.authenticatedGet(url).timeout(const Duration(seconds: 7));

      if (currentRequestId != lastRequestId) return; 

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is Map && responseData.containsKey('data')) {
          final classData = responseData['data'];
          await cacheScheduleData(requestedSemester.toString(), classData);

          if (mounted) {
            setState(() {
              scheduleData = classData;
              isLoading = false;
            });
          }
        } else {
          await cacheScheduleData(requestedSemester.toString(), responseData);
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

  void showUpdateNotification() {
    if (!mounted) return;
    EduMateToast.showCompact(
      context,
      message: 'Schedule updated by admin',
      isSuccess: true,
      actionLabel: 'Refresh',
      onActionTap: () {
        fetchScheduleFromBackend(isPolling: false);
      },
      duration: const Duration(seconds: 10),
    );
  }

  List<Map<String, dynamic>> mergeConsecutiveClasses(List<dynamic> classes) {
    if (classes.isEmpty) return [];
    List<Map<String, dynamic>> merged = [];
    Map<String, dynamic>? currentGroup;

    for (final classPeriod in classes) {
      final cp = classPeriod as Map<String, dynamic>;
      if (cp['className'] == '—') continue;

      if (currentGroup == null) {
        currentGroup = {
          'className': cp['className'],
          'startTime': cp['startTime'],
          'endTime': cp['endTime'],
          'room': cp['room'],
          'count': 1, 
        };
      } else if (currentGroup['className'] == cp['className']) {
        currentGroup['endTime'] = cp['endTime'];
        currentGroup['count'] = (currentGroup['count'] as int) + 1;
      } else {
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

    if (currentGroup != null) {
      merged.add(currentGroup);
    }
    return merged;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool isClassOngoing(String startTimeStr, String endTimeStr) {
    if (!_isToday(selectedDate)) return false;
    
    final now = DateTime.now();
    
    // Parse start time
    final startParts = startTimeStr.split(':');
    if (startParts.length != 2) return false;
    final startHour = int.tryParse(startParts[0]);
    final startMinute = int.tryParse(startParts[1]);
    
    // Parse end time
    final endParts = endTimeStr.split(':');
    if (endParts.length != 2) return false;
    final endHour = int.tryParse(endParts[0]);
    final endMinute = int.tryParse(endParts[1]);
    
    if (startHour == null || startMinute == null || endHour == null || endMinute == null) {
      return false;
    }

    final classStart = DateTime(now.year, now.month, now.day, startHour, startMinute);
    final classEnd = DateTime(now.year, now.month, now.day, endHour, endMinute);

    return now.isAfter(classStart) && now.isBefore(classEnd);
  }

  bool isClassPassed(String endTimeStr) {
    if (!_isToday(selectedDate)) return false;
    
    final now = DateTime.now();
    final parts = endTimeStr.split(':');
    if (parts.length != 2) return false;

    final hour = int.tryParse(parts[0]);
    final min = int.tryParse(parts[1]);

    if (hour == null || min == null) return false;

    final classEndTime = DateTime(now.year, now.month, now.day, hour, min);
    return now.isAfter(classEndTime);
  }
}
