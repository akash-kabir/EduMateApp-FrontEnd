import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:app/shared/config.dart';
import 'package:app/theme/theme.dart';
import 'package:app/shared/services/shared_preferences_service.dart';
import 'package:app/shared/services/api_service.dart';
import 'package:app/shared/widgets/dialogs/toast_manager.dart';
import 'package:app/shared/widgets/skeletons/skeleton_loading_card.dart';
import 'package:app/features/schedule/screens/schedule_settings_modal.dart';
import 'package:app/features/schedule/widgets/schedule_timeline.dart';
import 'package:app/features/schedule/widgets/week_calendar_grid.dart';
import 'package:app/features/schedule/widgets/weekly_gantt_chart.dart';
import 'package:app/features/schedule/screens/schedule_logic_mixin.dart';
import 'package:app/features/schedule/services/schedule_database_helper.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with WidgetsBindingObserver, ScheduleLogicMixin, AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  
  late PageController _pageController;
  Map<String, dynamic>? _cachedSectionData;
  String? _cachedSectionQuery;
  int? _cachedScheduleHash;
  bool _isWeeklyView = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeScheduleState();
    final weekDatesLocal = getWeekDates();
    final initialIndex = weekDatesLocal.indexWhere(
      (date) => date.year == selectedDate.year && date.month == selectedDate.month && date.day == selectedDate.day,
    );
    // initialIndex 0 is Sunday. We only want Mon-Sat (indices 1-6) mapping to page indices 0-5.
    final pageIndex = initialIndex > 0 ? (initialIndex - 1).clamp(0, 5) : 0;
    _pageController = PageController(initialPage: pageIndex);
    _loadViewModePreference();
  }

  Future<void> _loadViewModePreference() async {
    final defaultGantt = await SharedPreferencesService.getBool('defaultToGanttChart');
    if (mounted && defaultGantt) {
      setState(() {
        _isWeeklyView = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disposeScheduleState();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) setState(() {});
    }
  }

  List<DateTime> getWeekDates() {
    return List.generate(7, (i) => weekStartDate.add(Duration(days: i)));
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
      await SharedPreferencesService.setString(
        'timesheet_semester',
        classValue,
      );
      await SharedPreferencesService.setString(
        'timesheet_section',
        sectionValue,
      );
      await SharedPreferencesService.setString('timesheet_year', yearValue);
      await SharedPreferencesService.setBool('timesheet_save_preference', true);
    } else {
      await SharedPreferencesService.remove('timesheet_branch');
      await SharedPreferencesService.remove('timesheet_semester');
      await SharedPreferencesService.remove('timesheet_section');
      await SharedPreferencesService.remove('timesheet_year');
      await SharedPreferencesService.setBool(
        'timesheet_save_preference',
        false,
      );
    }
  }

  void _onSettingsSaved(
    String branch,
    int semester,
    String section,
    Map<String, String> electives,
    bool savePref,
  ) async {
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
      await _savePreference(
        branch,
        semester.toString(),
        '1st Year',
        section,
        true,
      );

      final List<String> electivesList = [];
      for (final entry in electives.entries) {
        final group = entry.key;
        final val = entry.value;
        if (val != 'Not Selected') {
          electivesList.add(val);
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

      final token = await SharedPreferencesService.getToken();
      final rollNo = await SharedPreferencesService.getRollNo();
      final year = await SharedPreferencesService.getYear();

      if (token != null && rollNo != null && year != null) {
        try {
          final profileData = {
            'rollNo': rollNo,
            'year': year,
            'semester': 'Semester $semester',
            'branch': branch,
            'section': section,
            'electives': electivesList,
          };

          final result = await ApiService.updateUserProfileWithFields(
            token: token,
            profileData: profileData,
          );
          if (result['success'] == true) {
            final responseData = result['data'];
            if (responseData != null && responseData['data'] != null) {
              await SharedPreferencesService.saveFullUserProfile(
                responseData['data'] as Map<String, dynamic>,
              );
            }
          }
        } catch (e) {
          debugPrint('Error syncing electives to backend: $e');
        }
      }
    }

    fetchAvailableElectives(semester, skipLoadPreferences: !savePref);
    fetchScheduleFromBackend();

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
        hasPreference: savePreference,
        fetchSections: _fetchSectionsList,
        fetchElectives: _getElectivesForSettings,
        onSave: _onSettingsSaved,
      ),
    );
  }

  Future<Map<String, List<String>>> _getElectivesForSettings(
    int semester,
  ) async {
    try {
      Map<String, dynamic>? decoded;
      try {
        decoded = await ScheduleDatabaseHelper.instance.getCachedElectiveData(
          semester.toString(),
        );
      } catch (e) {
        debugPrint('SQLite error in screen: $e');
      }

      if (decoded == null) {
        final cacheKey = 'cached_electives_v2_$semester';
        String? cachedStr = await SharedPreferencesService.getString(cacheKey);
        cachedStr ??= await SharedPreferencesService.getString(
            'cached_electives_$semester',
          );
        if (cachedStr != null) {
          decoded = jsonDecode(cachedStr);
          await ScheduleDatabaseHelper.instance.cacheElectiveData(
            semester.toString(),
            decoded,
          );
        }
      }

      if (decoded != null) {
        if (decoded.containsKey('grouped')) {
          final Map<String, List<String>> grouped = {};
          (decoded['grouped'] as Map).forEach((key, val) {
            grouped[key] = List<String>.from(val as List);
          });
          _fetchAndCacheElectivesInBackground(semester);
          return grouped;
        }
      }
    } catch (e) {
      debugPrint('Error reading electives cache: $e');
    }

    return _fetchAndCacheElectives(semester);
  }

  Future<Map<String, List<String>>> _fetchAndCacheElectives(
    int semester,
  ) async {
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
          final cacheData = {
            'updatedAt': serverUpdatedAt,
            'raw': electivesList,
            'grouped': grouped,
          };
          await ScheduleDatabaseHelper.instance.cacheElectiveData(
            semester.toString(),
            cacheData,
            serverUpdatedAt: serverUpdatedAt,
          );
          return grouped;
        }
      }
    } catch (e) {
      debugPrint('Error fetching electives for settings: $e');
    }
    return {};
  }

  void _fetchAndCacheElectivesInBackground(int semester) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    http
        .get(Uri.parse('${Config.electiveBaseEndpoint}/$semester?t=$timestamp'))
        .then((response) {
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
              ScheduleDatabaseHelper.instance.cacheElectiveData(
                semester.toString(),
                cacheData,
                serverUpdatedAt: serverUpdatedAt,
              );
            }
          }
        })
        .catchError((e) {
          debugPrint('Background fetch error for electives: $e');
        });
  }

  Future<List<String>> _fetchSectionsList(int semester) async {
    try {
      final sqliteData = await ScheduleDatabaseHelper.instance
          .getCachedScheduleData(semester.toString());
      if (sqliteData != null && sqliteData.containsKey('classes')) {
        final classesList = sqliteData['classes'] as List;
        return classesList.map((c) => c['name'] as String).toList()..sort();
      }

      final cacheKey = 'schedule_$semester';
      final cachedData = await SharedPreferencesService.getString(cacheKey);
      if (cachedData != null) {
        final decoded = jsonDecode(cachedData);
        if (decoded is Map && decoded.containsKey('classes')) {
          final classesList = decoded['classes'] as List;
          return classesList.map((c) => c['name'] as String).toList()..sort();
        }
      }

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
            return classesList.map((c) => c['name'] as String).toList()..sort();
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching sections list: $e');
    }
    return [];
  }

  // --- UI Helpers ---

  String? _matchElectiveGroup(String className) {
    final cleanName = className.toUpperCase().replaceAll(
      RegExp(r'[\s\-_]+'),
      '',
    );
    final allGroups = {
      ...availableElectives,
      ...{for (var k in selectedElectives.keys) k: <String>[]},
    };
    for (var group in allGroups.keys) {
      final cleanGroup = group.toUpperCase().replaceAll(
        RegExp(r'[\s\-_]+'),
        '',
      );
      if (cleanName == cleanGroup) return group;
      final aliasMap = <String, List<String>>{
        cleanGroup: _generateAliases(cleanGroup),
      };
      for (var alias in aliasMap[cleanGroup]!) {
        if (cleanName == alias || cleanName.contains(alias)) return group;
      }
    }
    return null;
  }

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

  List<dynamic> _processPeriods(List<dynamic> originalPeriods, int dayOfWeek) {
    final periods = originalPeriods
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
    for (var period in periods) {
      final className = period['className']?.toString() ?? '';
      final matchedGroup = _matchElectiveGroup(className);
      if (matchedGroup != null) {
        final chosenElective = selectedElectives[matchedGroup];
        if (chosenElective != null) {
          period['className'] = chosenElective;
          period['_replacedByElective'] = true;
          period['isElective'] = true;
          final room = _getElectiveRoom(
            chosenElective,
            dayOfWeek,
            period['startTime']?.toString() ?? '',
          );
          if (room.isNotEmpty) {
            period['room'] = room;
          }
        }
      }
    }
    return periods;
  }

  List<dynamic> _getClassesForDay(int dayOfWeek) {
    if (dayOfWeek < 1 || dayOfWeek > 5) return [];

    List<dynamic> dayClasses = [];
    try {
      if (scheduleData != null) {
        List<dynamic>? classes = scheduleData!['classes'] as List<dynamic>?;
        if (classes != null && classes.isNotEmpty) {
          if (_cachedSectionData == null ||
              _cachedSectionQuery != selectedSection ||
              _cachedScheduleHash != scheduleData.hashCode) {
            _cachedSectionQuery = selectedSection;
            _cachedScheduleHash = scheduleData.hashCode;

            var section = classes.firstWhere(
              (s) => s['name'] == selectedSection,
              orElse: () => null,
            );

            if (section == null) {
              final normalizedSaved = selectedSection.toUpperCase().replaceAll(
                RegExp(r'\s+|-'),
                '',
              );
              section = classes.firstWhere((s) {
                final normName = s['name'].toString().toUpperCase().replaceAll(
                  RegExp(r'\s+|-'),
                  '',
                );
                return normalizedSaved == normName;
              }, orElse: () => null);

              if (section == null && normalizedSaved.startsWith('CSE')) {
                final correctedSearch = 'CS${normalizedSaved.substring(3)}';
                section = classes.firstWhere((s) {
                  final normName = s['name']
                      .toString()
                      .toUpperCase()
                      .replaceAll(RegExp(r'\s+|-'), '');
                  return correctedSearch == normName;
                }, orElse: () => null);
              }

              if (section == null &&
                  RegExp(r'^\d+$').hasMatch(normalizedSaved)) {
                final correctedSearch =
                    '${selectedBranch.toUpperCase()}$normalizedSaved';
                section = classes.firstWhere((s) {
                  final normName = s['name']
                      .toString()
                      .toUpperCase()
                      .replaceAll(RegExp(r'\s+|-'), '');
                  return correctedSearch == normName;
                }, orElse: () => null);
              }

              section ??= classes.first;

              if (section != null) {
                final dbName = section['name'] as String;
                String uiFormattedName = dbName.trim();
                if (dbName.startsWith('CS') &&
                    !dbName.startsWith('CSCE') &&
                    !dbName.startsWith('CSSE')) {
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
            _cachedSectionData = section;
          }

          var section = _cachedSectionData;

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

    if (dayClasses.isEmpty) {
      final schedule =
          ScheduleLogicMixin.classSchedules[selectedSemester.toString()] ?? {};
      final result = schedule[dayOfWeek] ?? [];
      dayClasses = _processPeriods(result, dayOfWeek);
    }

    final Set<String> occupiedSlots = {};
    for (var cls in dayClasses) {
      if (cls['_replacedByElective'] == true) {
        occupiedSlots.add('${cls['startTime']}-${cls['endTime']}');
      }
    }

    for (var entry in selectedElectives.entries) {
      final electiveName = entry.value;
      final electiveItem = rawElectiveData.firstWhere(
        (e) => e['name'] == electiveName,
        orElse: () => null,
      );
      if (electiveItem != null && electiveItem['periods'] is List) {
        final periods = electiveItem['periods'] as List;
        for (var p in periods) {
          final pDay = p['day'] is int
              ? p['day'] as int
              : int.tryParse(p['day'].toString()) ?? -1;
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
              occupiedSlots.add(slotKey);
            }
          }
        }
      }
    }

    dayClasses.sort((a, b) {
      final aTime = a['startTime'].toString();
      final bTime = b['startTime'].toString();
      return aTime.compareTo(bTime);
    });

    return dayClasses;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final weekDates = getWeekDates();
    final now = DateTime.now();

    return CupertinoPageScaffold(
        child: Stack(
          children: [
            // BOTTOM LAYER: PageView where each page handles its own vertical scrolling
            Positioned.fill(
              child: _isWeeklyView
                  ? WeeklyGanttChart(
                      getClassesForDay: _getClassesForDay,
                      now: now,
                      selectedElectives: selectedElectives.values.toList(),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: 6,
                      onPageChanged: (index) {
                        setState(() {
                          selectedDate = weekDates[index + 1];
                        });
                      },
                      itemBuilder: (context, index) {
                  final dateForPage = weekDates[index + 1];
                  final classes = _getClassesForDay(dateForPage.weekday);
                  final mergedClasses = mergeConsecutiveClasses(classes);
                  
                  // Check if it's a holiday
                  Map<String, dynamic>? holidayForPage;
                  if (currentYearHolidays.isNotEmpty) {
                    final date = DateTime(dateForPage.year, dateForPage.month, dateForPage.day);
                    for (var holiday in currentYearHolidays) {
                      if (holiday['startDate'] == null || holiday['endDate'] == null) continue;
                      final startDate = DateTime.parse(holiday['startDate']);
                      final start = DateTime(startDate.year, startDate.month, startDate.day);
                      final endDate = DateTime.parse(holiday['endDate']);
                      final end = DateTime(endDate.year, endDate.month, endDate.day);
                      
                      if (date.isAtSameMomentAs(start) || date.isAtSameMomentAs(end) || (date.isAfter(start) && date.isBefore(end))) {
                        holidayForPage = holiday;
                        break;
                      }
                    }
                  }

                  return MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: CustomScrollView(
                      physics: const ClampingScrollPhysics(), // Reduced bounce physics
                      slivers: [
                        // Empty space to push content below the fixed header
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: MediaQuery.of(context).padding.top + 44.0 + 106.0,
                          ),
                        ),
                      
                      if (holidayForPage != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 24,
                                horizontal: 24,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF3366), // Vibrant Pink-Red
                                    Color(0xFFFF7733), // Vibrant Orange
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF3366).withValues(alpha: 0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'OFFICIAL HOLIDAY',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    holidayForPage['event'] ?? 'No Classes Today',
                                    style: const TextStyle(
                                      fontFamily: 'Salena',
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      if (isLoading)
                        const SliverFillRemaining(
                          child: Padding(
                            padding: EdgeInsets.only(top: 16.0),
                            child: SkeletonLoadingList(),
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
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No schedule data available for $selectedSemester',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        if (availableElectives.isNotEmpty && selectedElectives.length < availableElectives.length)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: GestureDetector(
                                onTap: _showSettingsBottomSheet,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        CupertinoIcons.exclamationmark_circle_fill,
                                        color: Colors.red,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Set Electives',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        'Tap to configure',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        CupertinoIcons.chevron_right,
                                        color: Colors.red,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          sliver: SliverToBoxAdapter(
                            child: ScheduleTimeline(
                              mergedClasses: mergedClasses,
                              isOngoing: (c) {
                                if (dateForPage.year != now.year || dateForPage.month != now.month || dateForPage.day != now.day) return false;
                                return isClassOngoing(c['startTime'] as String, c['endTime'] as String);
                              },
                              isPassed: (endTimeStr) {
                                if (dateForPage.year != now.year || dateForPage.month != now.month || dateForPage.day != now.day) return false;
                                
                                final parts = endTimeStr.split(':');
                                if (parts.length != 2) return false;
                                final hour = int.tryParse(parts[0]);
                                final min = int.tryParse(parts[1]);
                                if (hour == null || min == null) return false;
                                
                                final classEndTime = DateTime(now.year, now.month, now.day, hour, min);
                                return now.isAfter(classEndTime);
                              },
                              isHoliday: holidayForPage != null,
                              emptyMessage:
                                  (dateForPage.weekday == 6 ||
                                      dateForPage.weekday == 7)
                                  ? 'No classes scheduled for this day.\nEnjoy your day!'
                                  : 'No classes scheduled for this day',
                            ),
                          ),
                        ),
                      ],
          ]),
                  );
                },
              ),
            ),
            
            // TOP LAYER: Pinned Header overlay to provide blur effect
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoNavigationBar(
                    automaticallyImplyLeading: false,
                    leading: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _isWeeklyView = !_isWeeklyView;
                          if (!_isWeeklyView) {
                            final weekDates = getWeekDates();
                            final newIndex = weekDates.indexWhere(
                              (d) => d.year == selectedDate.year && d.month == selectedDate.month && d.day == selectedDate.day,
                            );
                            _pageController.dispose();
                            _pageController = PageController(initialPage: newIndex > 0 ? newIndex - 1 : 0);
                          }
                        });
                      },
                      child: Icon(
                        _isWeeklyView ? Icons.view_agenda_rounded : Icons.view_week_rounded,
                        color: AuthPalette.coral,
                        size: 24,
                      ),
                    ),
                    middle: const Text(
                      'Timesheet',
                      style: TextStyle(fontFamily: 'Salena', fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: CupertinoColors.black.withValues(alpha: 0.6),
                    border: null,
                    trailing: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _showSettingsBottomSheet,
                      child: const Icon(
                        Icons.settings,
                        color: AuthPalette.coral,
                        size: 22,
                      ),
                    ),
                  ),
                  ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: double.infinity,
                    color: CupertinoColors.black.withValues(alpha: 0.6),
                    height: _isWeeklyView ? 56.0 : 106.0,
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: _isWeeklyView ? 0 : 10,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isWeeklyView) ...[
                          WeekCalendarGrid(
                            weekDates: weekDates,
                            selectedDate: selectedDate,
                            now: now,
                            onDateSelected: (date, slideRight) {
                              final newIndex = weekDates.indexWhere(
                                (d) => d.year == date.year && d.month == date.month && d.day == date.day,
                              );
                              if (newIndex > 0) {
                                _pageController.animateToPage(
                                  newIndex - 1,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            },
                          ),
                          if (selectedBranch.isNotEmpty && selectedSemester.toString().isNotEmpty)
                            const SizedBox(height: 16),
                        ],
                        if (selectedBranch.isNotEmpty &&
                            selectedSemester.toString().isNotEmpty) ...[
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[400],
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      'Showing for Semester $selectedSemester ',
                                ),
                                TextSpan(
                                  text:
                                      '(${selectedSection.isNotEmpty ? selectedSection : selectedBranch})',
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
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  }
}
