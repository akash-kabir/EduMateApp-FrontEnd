import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:app/shared/config.dart';
import 'package:app/shared/services/shared_preferences_service.dart';
import 'package:app/features/auth_and_profile/services/token_refresh_service.dart';
import 'package:app/features/schedule/services/schedule_database_helper.dart';
import 'package:app/shared/widgets/dialogs/toast_manager.dart';
import 'package:app/features/schedule/screens/schedule_screen.dart';
import 'package:provider/provider.dart';
import 'package:app/features/schedule/provider/schedule_provider.dart';

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
  bool _hasNotifiedScheduleUpdate = false;
  bool _hasNotifiedElectiveUpdate = false;

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

    // Instant synchronous cache load to eliminate skeleton loader entirely
    final provider = Provider.of<ScheduleProvider>(context, listen: false);
    if (provider.semester != null) {
      selectedBranch = provider.branch ?? 'CSE';
      selectedSemester = provider.semester!;
      selectedSection = provider.section ?? 'CSE-1';
      savePreference = provider.savePreference ?? false;
      selectedElectives = provider.selectedElectives ?? {};
      
      scheduleData = provider.getSchedule(selectedSemester.toString());
      availableElectives = provider.getElectives(selectedSemester.toString()) ?? {};
      rawElectiveData = provider.getRawElectives(selectedSemester.toString()) ?? [];
      isLoading = false; // We have data, no loader needed!
    } else {
      isLoading = true; // First time app open, show loader while SharedPreferences reads
    }

    loadSavedPreferenceAndFetchSchedule();
    _fetchCurrentYearHolidays();
    startRefreshTimer();
  }

  Future<void> _fetchCurrentYearHolidays() async {
    final provider = Provider.of<ScheduleProvider>(context, listen: false);
    final year = DateTime.now().year;
    final cached = provider.getHolidays(year);
    if (cached != null) {
      if (mounted) {
        setState(() {
          currentYearHolidays = cached;
        });
      }
      return;
    }

    try {
      final response = await http.get(Uri.parse('${Config.holidayBaseEndpoint}/$year'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final holidaysList = data['data'] as List<dynamic>;
          provider.setHolidays(year, holidaysList);
          if (mounted) {
            setState(() {
              currentYearHolidays = holidaysList;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching holidays for schedule: $e');
    }
  }

  int? _lastMinute;
  
  void startRefreshTimer() {
    refreshTimer?.cancel();
    _lastMinute = DateTime.now().minute;
    refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final currentMinute = DateTime.now().minute;
        if (currentMinute != _lastMinute) {
          _lastMinute = currentMinute;
          setState(() {}); // Updates the current time indicator
        }
        
        // Poll for updates in the background every 30 seconds
        if (DateTime.now().second % 30 == 0) {
          if (selectedBranch.isNotEmpty && selectedSemester > 0) {
            fetchScheduleFromBackend(isPolling: true);
            fetchAvailableElectives(selectedSemester, isPolling: true);
          }
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
    
    // First, try loading from the saved user profile electives
    final userElectives = await SharedPreferencesService.getUserElectives();
    for (var elective in userElectives) {
      // Find which group this elective belongs to
      for (var entry in availableElectives.entries) {
        if (entry.value.contains(elective)) {
          tempSelected[entry.key] = elective;
          break;
        }
      }
    }

    // Then, fallback to or override with explicit shared preferences (if the user manually changed them in the settings)
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
    
    if (!mounted) return;
    
    final provider = Provider.of<ScheduleProvider>(context, listen: false);
    provider.selectedElectives = tempSelected;
    
    setState(() {
      selectedElectives = tempSelected;
    });
  }

  Future<void> fetchAvailableElectives(int semester,
      {bool isPolling = false, bool skipLoadPreferences = false, bool forceRefresh = false}) async {
    if (!isPolling) {
      _hasNotifiedElectiveUpdate = false;
    }
    final provider = Provider.of<ScheduleProvider>(context, listen: false);
    final cachedGrouped = provider.getElectives(semester.toString());
    final cachedRaw = provider.getRawElectives(semester.toString());

    if (cachedGrouped != null && cachedRaw != null && !isPolling && !forceRefresh) {
      if (mounted) {
        setState(() {
          availableElectives = cachedGrouped;
          rawElectiveData = cachedRaw;
        });
        if (!skipLoadPreferences) {
          await loadSavedElectivePreferences();
        }
      }
      return;
    }

    bool hasCache = false;
    String? localUpdatedAt;

    try {
      Map<String, dynamic>? decoded;
      try {
        decoded = await ScheduleDatabaseHelper.instance.getCachedElectiveData(semester.toString());
      } catch (e) {
        debugPrint('SQLite error in mixin: $e');
      }

      if (decoded == null) {
        final cacheKey = 'cached_electives_v2_$semester';
        String? cachedStr = await SharedPreferencesService.getString(cacheKey);
        cachedStr ??= await SharedPreferencesService.getString('cached_electives_$semester');
        if (cachedStr != null) {
          decoded = jsonDecode(cachedStr);
          await ScheduleDatabaseHelper.instance.cacheElectiveData(semester.toString(), decoded);
        }
      }

      if (decoded != null) {
        if (decoded.containsKey('raw') && decoded.containsKey('grouped')) {
          final raw = decoded['raw'] as List;
          localUpdatedAt = await ScheduleDatabaseHelper.instance.getServerUpdatedAtForElectives(semester.toString());
          final Map<String, List<String>> grouped = {};
          (decoded['grouped'] as Map).forEach((key, val) {
            grouped[key] = List<String>.from(val as List);
          });
          
          hasCache = true;
          provider.setElectives(semester.toString(), grouped, raw);
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
            if (!_hasNotifiedElectiveUpdate) {
              _hasNotifiedElectiveUpdate = true;
              showElectiveUpdateNotification(semester);
            }
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
          
          await ScheduleDatabaseHelper.instance.cacheElectiveData(semester.toString(), cacheData, serverUpdatedAt: serverUpdatedAt);
          provider.setElectives(semester.toString(), grouped, electivesList);

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
        fetchAvailableElectives(semester, isPolling: false, forceRefresh: true);
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
        
        final provider = Provider.of<ScheduleProvider>(context, listen: false);
        provider.branch = selectedBranch;
        provider.semester = selectedSemester;
        provider.section = selectedSection;
        provider.savePreference = savePreference;
        provider.selectedElectives = selectedElectives;
      });
      await Future.wait([
        fetchAvailableElectives(selectedSemester),
        fetchScheduleFromBackend()
      ]);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      // Fallback to user profile
      final profileBranch = await SharedPreferencesService.getString('user_branch');
      final profileSemester = await SharedPreferencesService.getString('user_semester');
      final profileSection = await SharedPreferencesService.getString('user_section');

      setState(() {
        selectedBranch = profileBranch ?? 'CSE';
        selectedSemester = profileSemester != null 
            ? (int.tryParse(profileSemester.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1) 
            : 1;
        selectedSection = profileSection ?? 'CSE-1';
        savePreference = false;
        
        if (selectedBranch.isNotEmpty && selectedSection.isNotEmpty) {
          classesPerBranch.putIfAbsent(selectedBranch, () => []);
          if (!classesPerBranch[selectedBranch]!.contains(selectedSection)) {
            classesPerBranch[selectedBranch]!.add(selectedSection);
          }
        }

        final provider = Provider.of<ScheduleProvider>(context, listen: false);
        provider.branch = selectedBranch;
        provider.semester = selectedSemester;
        provider.section = selectedSection;
        provider.savePreference = savePreference;
        provider.selectedElectives = selectedElectives;
      });
      await Future.wait([
        fetchAvailableElectives(selectedSemester),
        fetchScheduleFromBackend()
      ]);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> cacheScheduleData(String semester, dynamic data, {String? updatedAt}) async {
    await ScheduleDatabaseHelper.instance.cacheScheduleData(semester, data, serverUpdatedAt: updatedAt);
  }

  Future<Map<String, dynamic>?> getCachedScheduleData(String semester) async {
    return await ScheduleDatabaseHelper.instance.getCachedScheduleData(semester);
  }

  Future<void> fetchScheduleFromBackend({bool isPolling = false, bool forceRefresh = false}) async {
    if (!isPolling) {
      _hasNotifiedScheduleUpdate = false;
    }
    
    final currentRequestId = ++lastRequestId;
    final requestedSemester = selectedSemester;

    final provider = Provider.of<ScheduleProvider>(context, listen: false);
    final memoryCache = provider.getSchedule(requestedSemester.toString());

    if (memoryCache != null && !isPolling && !forceRefresh) {
      if (mounted) {
        setState(() {
          scheduleData = memoryCache;
          isLoading = false;
        });
      }
      return;
    }

    final cachedData = await getCachedScheduleData(requestedSemester.toString());
    final hasCache = cachedData != null;
    
    if (hasCache && !isPolling && !forceRefresh) {
      provider.setSchedule(requestedSemester.toString(), cachedData);
      if (mounted) {
        setState(() {
          scheduleData = cachedData;
          isLoading = false; // Immediately dismiss skeleton loader if cache exists
        });
      }
    }

    if (!isPolling) {
      _hasNotifiedScheduleUpdate = false;
    }

    if (!hasCache && !isPolling && mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      String? serverUpdatedAt;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final metaUrl = '${Config.scheduleBaseEndpoint}/$requestedSemester/metadata?t=$timestamp';
      final metaResponse = await TokenRefreshService.authenticatedGet(metaUrl).timeout(const Duration(seconds: 5));

      if (metaResponse.statusCode == 200) {
        final metaData = jsonDecode(metaResponse.body);
        serverUpdatedAt = metaData['updatedAt'];

        if (hasCache && serverUpdatedAt != null) {
          final localUpdatedAt = await ScheduleDatabaseHelper.instance.getServerUpdatedAt(requestedSemester.toString());
          
          if (localUpdatedAt == serverUpdatedAt) {
            if (!isPolling && mounted) {
              setState(() => isLoading = false);
            }
            return; 
          } else if (isPolling && mounted) {
            if (!_hasNotifiedScheduleUpdate) {
              _hasNotifiedScheduleUpdate = true;
              showUpdateNotification();
            }
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
          await cacheScheduleData(requestedSemester.toString(), classData, updatedAt: serverUpdatedAt);
          provider.setSchedule(requestedSemester.toString(), classData);

          if (mounted) {
            setState(() {
              scheduleData = classData;
              isLoading = false;
            });
          }
        } else {
          await cacheScheduleData(requestedSemester.toString(), responseData, updatedAt: serverUpdatedAt);
          provider.setSchedule(requestedSemester.toString(), responseData);
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
        fetchScheduleFromBackend(isPolling: false, forceRefresh: true);
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
