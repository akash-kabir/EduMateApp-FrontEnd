import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/friend_model.dart';
import '../../services/friends_storage_service.dart';
import '../../services/friends_schedule_service.dart';
import '../../services/shared_preferences_service.dart';
import '../../services/schedule_database_helper.dart';
import '../../constants/app_constants.dart';
import 'friends_settings_screen.dart';
import 'widgets/friends_gantt_chart.dart';

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


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _getCurrentDayName() {
    return 'Monday';
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
            final todayObj = userScheduleList.firstWhere(
              (d) => d['day'] == 1 || d['day'] == '1' || d['day']?.toString().toLowerCase() == 'monday',
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
          final todayObj = userDays.firstWhere(
            (d) => d['day'] == 1 || d['day'] == '1' || d['day']?.toString().toLowerCase() == 'monday',
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
          dayOfWeek: 1,
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
    final currentDay = _getCurrentDayName();

    return CupertinoPageScaffold(
      backgroundColor: UserColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        border: null,
        middle: Text(
          'Friends Schedule ($currentDay)',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () async {
            await Navigator.of(context).push(
              CupertinoPageRoute(builder: (context) => const FriendsSettingsScreen()),
            );
            _loadData();
          },
          child: const Icon(CupertinoIcons.settings, color: Colors.white),
        ),
      ),
      child: SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator(radius: 16))
              : _friends.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.person_3, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          const Text(
                            'No friends added yet.\nAdd up to 10 friends to compare schedules.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 15),
                          ),
                          const SizedBox(height: 24),
                          CupertinoButton(
                            color: AuthPalette.teal,
                            borderRadius: BorderRadius.circular(12),
                            onPressed: () async {
                              await Navigator.of(context).push(
                                CupertinoPageRoute(builder: (context) => const FriendsSettingsScreen()),
                              );
                              _loadData();
                            },
                            child: const Text('Add Friends', style: TextStyle(fontWeight: FontWeight.bold)),
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
      ),
    );
  }
}
