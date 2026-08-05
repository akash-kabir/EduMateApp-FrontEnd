import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/features/friends/models/friend_model.dart';
import 'package:app/features/friends/services/friends_storage_service.dart';
import 'package:app/features/friends/services/friends_schedule_service.dart';
import 'package:app/shared/services/shared_preferences_service.dart';
import 'package:app/features/schedule/services/schedule_database_helper.dart';
import 'package:app/theme/theme.dart';
import 'package:app/features/friends/screens/friends_settings_screen.dart';
import 'package:app/features/friends/widgets/friends_gantt_chart.dart';
import 'package:app/features/schedule/widgets/week_calendar_grid.dart';

class FriendsScheduleScreen extends StatefulWidget {
  const FriendsScheduleScreen({super.key});

  @override
  State<FriendsScheduleScreen> createState() => _FriendsScheduleScreenState();
}

class _FriendsScheduleScreenState extends State<FriendsScheduleScreen> {
  List<FriendModel> _friends = [];
  Map<String, List<dynamic>> _schedules = {};
  List<dynamic> _userTodaySchedule = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  DateTime _selectedDate = DateTime.now();
  late List<DateTime> _weekDates;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<DateTime> _getWeekDates() {
    final now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday == 7 ? 0 : now.weekday));
    startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  @override
  void initState() {
    super.initState();
    _weekDates = _getWeekDates();
    _loadData();
  }

  String _getDayName(DateTime date) {
    final weekday = date.weekday;
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Monday';
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    _friends = await FriendsStorageService.getFriends();
    
    // Load friends schedules
    if (_friends.isNotEmpty) {
      _schedules = await FriendsScheduleService.getSchedulesForFriends(_friends);
    } else {
      _schedules = {};
    }

    // Load user schedule properly using saved timesheet branch/semester/section and user electives
    try {
      final savedSem = await SharedPreferencesService.getString('timesheet_semester');
      final savedSec = await SharedPreferencesService.getString('timesheet_section');
      
      final userSem = (savedSem != null && savedSem.isNotEmpty) 
          ? savedSem 
          : (await SharedPreferencesService.getSemester() ?? '');
      final userSec = (savedSec != null && savedSec.isNotEmpty) 
          ? savedSec 
          : (await SharedPreferencesService.getSection() ?? '');

      if (userSem.isNotEmpty && userSec.isNotEmpty) {
        final semNumInt = int.tryParse(userSem.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
        final cachedData = await ScheduleDatabaseHelper.instance.getCachedScheduleData(semNumInt.toString());

        List<dynamic> rawPeriods = [];

        if (cachedData != null && cachedData['classes'] is List) {
          final classes = cachedData['classes'] as List;
          
          final normalizedSavedSec = userSec.toUpperCase().replaceAll(RegExp(r'\s+|-'), '');
          var sectionObj = classes.firstWhere(
            (s) => s['name'].toString().toUpperCase().replaceAll(RegExp(r'\s+|-'), '') == normalizedSavedSec,
            orElse: () => null,
          );

          if (sectionObj != null && sectionObj['schedule'] is List) {
            final userScheduleList = sectionObj['schedule'] as List;
            final currentDayIndex = _selectedDate.weekday;
            final currentDayName = _getDayName(_selectedDate).toLowerCase();
            final todayObj = userScheduleList.firstWhere(
              (d) => d['day'] == currentDayIndex || d['day'] == currentDayIndex.toString() || d['day']?.toString().toLowerCase() == currentDayName,
              orElse: () => null,
            );

            if (todayObj != null && todayObj['periods'] is List) {
              rawPeriods = List<dynamic>.from(todayObj['periods']);
            }
          }
        }

        // Fallback: If local cache is empty, load via FriendsScheduleService
        if (rawPeriods.isEmpty) {
          final dummyUser = FriendModel(
            rollNo: '__user__',
            nameTag: 'You',
            semester: userSem.contains('Semester') ? userSem : 'Semester $userSem',
            section: userSec,
          );
          final userSchedMap = await FriendsScheduleService.getSchedulesForFriends([dummyUser]);
          final userDays = userSchedMap['__user__'] ?? [];
          final currentDayIndex = _selectedDate.weekday;
          final currentDayName = _getDayName(_selectedDate).toLowerCase();
          final todayObj = userDays.firstWhere(
            (d) => d['day'] == currentDayIndex || d['day'] == currentDayIndex.toString() || d['day']?.toString().toLowerCase() == currentDayName,
            orElse: () => null,
          );
          if (todayObj != null && todayObj['periods'] != null) {
            rawPeriods = List<dynamic>.from(todayObj['periods']);
          }
        }

        // Gather user selected electives map properly from all group keys
        final Map<String, String> userElectivesMap = {};
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys();
        for (var key in keys) {
          if (key.startsWith('selectedElective_')) {
            final val = prefs.getString(key);
            if (val != null && val.isNotEmpty) {
              userElectivesMap[key] = val;
            }
          }
        }

        // Fallback if specific keys aren't found
        if (userElectivesMap.isEmpty) {
          final userElectivesList = await SharedPreferencesService.getUserElectives();
          for (int i = 0; i < userElectivesList.length; i++) {
            userElectivesMap['Elective_$i'] = userElectivesList[i];
          }
        }

        // Substitute electives into periods
        _userTodaySchedule = await FriendsScheduleService.processPeriodsWithElectives(
          rawPeriods,
          dayOfWeek: _selectedDate.weekday,
          semesterNum: semNumInt,
          userElectivesMap: userElectivesMap,
        );
      }
    } catch (e) {
      debugPrint('Error loading user schedule in FriendsScheduleScreen: $e');
      _userTodaySchedule = [];
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final currentDay = _getDayName(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
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
                          horizontal: 8.0, vertical: 16.0),
                      child: Column(
                        children: [
                          Stack(
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
                                      child: const Icon(CupertinoIcons.back,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                              const Text(
                                'Friends Schedule',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'Salena',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Color(0xFFFF9B7A),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () async {
                                    await showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => const FriendsSettingsScreen(),
                                    );
                                    _loadData();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF141110),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.settings,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          WeekCalendarGrid(
                            weekDates: _weekDates,
                            selectedDate: _selectedDate,
                            now: DateTime.now(),
                            onDateSelected: (date, slideFromRight) {
                              setState(() {
                                _selectedDate = date;
                              });
                              _loadData();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: _isLoading
                        ? const Center(
                            child: CupertinoActivityIndicator(radius: 16))
                        : _friends.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(CupertinoIcons.person_3,
                                        size: 64,
                                        color: Colors.white
                                            .withValues(alpha: 0.3)),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No friends added yet.\nAdd up to 10 friends to compare schedules.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 15),
                                    ),
                                    const SizedBox(height: 24),
                                    CupertinoButton(
                                      color: AuthPalette.coral,
                                      borderRadius: BorderRadius.circular(12),
                                      onPressed: () async {
                                        await showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => const FriendsSettingsScreen(),
                                        );
                                        _loadData();
                                      },
                                      child: const Text('Add Friends',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              )
                            : FriendsGanttChart(
                                userSchedule: _userTodaySchedule,
                                friends: _friends,
                                friendsSchedules: _schedules,
                                currentDayName: currentDay,
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
