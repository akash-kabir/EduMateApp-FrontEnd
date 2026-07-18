import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config.dart';
import '../../constants/app_constants.dart';
import '../../services/shared_preferences_service.dart';
import '../../widgets/toast_manager.dart';
import '../../widgets/skeleton_loading_card.dart';
import 'schedule_settings_modal.dart';
import 'widgets/schedule_timeline.dart';
import 'widgets/week_calendar_grid.dart';

import 'schedule_logic_mixin.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with WidgetsBindingObserver, ScheduleLogicMixin {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeScheduleState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disposeScheduleState();
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

  Future<Map<String, List<String>>> _getElectivesForSettings(int semester) async {
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

  Future<List<String>> _fetchSectionsList(int semester) async {
    try {
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
    final cleanName = className.toUpperCase().replaceAll(RegExp(r'[\s\-_]+'), '');
    final allGroups = {...availableElectives, ...{for (var k in selectedElectives.keys) k: <String>[]}};
    for (var group in allGroups.keys) {
      final cleanGroup = group.toUpperCase().replaceAll(RegExp(r'[\s\-_]+'), '');
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
    final periods = originalPeriods.map((p) => Map<String, dynamic>.from(p)).toList();
    for (var period in periods) {
      final className = period['className']?.toString() ?? '';
      final matchedGroup = _matchElectiveGroup(className);
      if (matchedGroup != null) {
        final chosenElective = selectedElectives[matchedGroup];
        if (chosenElective != null) {
          period['className'] = chosenElective;
          period['_replacedByElective'] = true; 
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
    if (dayOfWeek < 1 || dayOfWeek > 5) return [];

    List<dynamic> dayClasses = [];
    try {
      if (scheduleData != null) {
        List<dynamic>? classes = scheduleData!['classes'] as List<dynamic>?;
        if (classes != null && classes.isNotEmpty) {
          var section = classes.firstWhere(
            (s) => s['name'] == selectedSection,
            orElse: () => null,
          );
          
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

            if (section == null && RegExp(r'^\d+$').hasMatch(normalizedSaved)) {
              final correctedSearch = '${selectedBranch.toUpperCase()}$normalizedSaved';
              section = classes.firstWhere((s) {
                final normName = s['name'].toString().toUpperCase().replaceAll(RegExp(r'\s+|-'), '');
                return correctedSearch == normName;
              }, orElse: () => null);
            }

            section ??= classes.first;

            if (section != null) {
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

    if (dayClasses.isEmpty) {
      final schedule = ScheduleLogicMixin.classSchedules[selectedSemester.toString()] ?? {};
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weekDates = getWeekDates();
    final now = DateTime.now();
    final classes = _getClassesForDay(selectedDate.weekday);
    final mergedClasses = mergeConsecutiveClasses(classes);

    return GestureDetector(
      onHorizontalDragStart: (_) {
        setState(() {
          dragOffset = 0.0;
        });
      },
      onHorizontalDragUpdate: (details) {
        setState(() {
          dragOffset += details.delta.dx;
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
        
        if (dragOffset < -swipeThreshold || velocity < -velocityThreshold) {
          if (currentIndex < 6) {
            final nextIndex = currentIndex + 1 <= 6
                ? currentIndex + 1
                : currentIndex;
            setState(() {
              slideFromRight = true;
              dragOffset = 0.0;
              selectedDate = weekDatesLocal[nextIndex];
            });
            didSwipe = true;
          }
        }
        else if (dragOffset > swipeThreshold ||
            velocity > velocityThreshold) {
          if (currentIndex > 1) {
            final prevIndex = currentIndex - 1 >= 1
                ? currentIndex - 1
                : currentIndex;
            setState(() {
              slideFromRight = false;
              dragOffset = 0.0;
              selectedDate = weekDatesLocal[prevIndex];
            });
            didSwipe = true;
          }
        }
        if (!didSwipe) {
          setState(() {
            dragOffset = 0.0;
          });
        }
      },
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          automaticallyImplyLeading: false,
          middle: const Text(
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
              Icons.settings,
              color: AuthPalette.coral,
              size: 22,
            ),
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _DaySelectorHeaderDelegate(
                topPadding: MediaQuery.of(context).padding.top + 44.0,
                height: 118.0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      color: isDark
                          ? CupertinoColors.black.withValues(alpha: 0.6)
                          : CupertinoColors.white.withValues(alpha: 0.6),
                      height: 118.0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          WeekCalendarGrid(
                            weekDates: weekDates,
                            selectedDate: selectedDate,
                            now: now,
                            isDark: isDark,
                            onDateSelected: (date, slideRight) {
                              setState(() {
                                slideFromRight = slideRight;
                                selectedDate = date;
                              });
                            },
                          ),
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
            if (getHolidayForSelectedDate() != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF3366), Color(0xFFFF7733)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF3366).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HOLIDAY',
                          style: TextStyle(
                            fontFamily: 'Salena',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          getHolidayForSelectedDate()!['event'] ?? 'No Classes Today',
                          style: const TextStyle(
                            fontFamily: 'Salena',
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
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
                      opacity: (1.0 - (dragOffset.abs() / 400.0)).clamp(
                        0.4,
                        1.0,
                      ),
                      child: AnimatedContainer(
                        duration: dragOffset == 0.0
                            ? const Duration(milliseconds: 200)
                            : Duration.zero,
                        curve: Curves.easeOut,
                        transform: Matrix4.translationValues(
                          dragOffset.clamp(-200.0, 200.0),
                          0,
                          0,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) {
                            final isIncoming = child.key == ValueKey(selectedDate);
                            final Offset offsetBegin;
                            if (isIncoming) {
                              offsetBegin = slideFromRight
                                  ? const Offset(1.0, 0.0)
                                  : const Offset(-1.0, 0.0);
                            } else {
                              offsetBegin = slideFromRight
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
                            child: ScheduleTimeline(
                              mergedClasses: mergedClasses,
                              isDark: isDark,
                              isOngoing: isClassOngoing,
                              isPassed: isClassPassed,
                            ),
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
}

class _DaySelectorHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final double topPadding;

  _DaySelectorHeaderDelegate({required this.child, required this.height, this.topPadding = 0.0});

  @override
  double get minExtent => height + topPadding;

  @override
  double get maxExtent => height + topPadding;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _DaySelectorHeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}
