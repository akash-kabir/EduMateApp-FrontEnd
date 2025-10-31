import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../schedule/class_16_schedule.dart' as class16;
import '../schedule/class_7_schedule.dart' as class7;
import '../schedule/class_15_schedule.dart' as class15;
import '../schedule/class_19_schedule.dart' as class19;
import '../schedule/class_25_schedule.dart' as class25;
import '../schedule/class_35_schedule.dart' as class35;
import '../schedule/class_51_schedule.dart' as class51;

class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({super.key});

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  late DateTime selectedDate;
  late DateTime weekStartDate;
  String selectedClass = 'CSE 16'; 
  bool savePreference = false; 

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();

    weekStartDate = selectedDate.subtract(
      Duration(days: selectedDate.weekday % 7),
    );
    _loadSavedPreference(); 
  }


  Future<void> _loadSavedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedClass = prefs.getString('selectedClass');
    final saved = prefs.getBool('savePreference') ?? false;

    if (saved && savedClass != null) {
      setState(() {
        selectedClass = savedClass;
        savePreference = true;
      });
    }
  }


  Future<void> _savePreference(String classValue, bool shouldSave) async {
    final prefs = await SharedPreferences.getInstance();
    if (shouldSave) {
      await prefs.setString('selectedClass', classValue);
      await prefs.setBool('savePreference', true);
    } else {
      await prefs.remove('selectedClass');
      await prefs.setBool('savePreference', false);
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

    return Scaffold(
      backgroundColor: isDark ? Colors.black : CupertinoColors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            automaticallyImplyLeading: false,
            largeTitle: const Text('Timesheet'),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(CupertinoIcons.chevron_back), Text('Back')],
              ),
            ),
            trailing: GestureDetector(
              onTap: _showClassPicker,
              child: Text(
                selectedClass,
                style: const TextStyle(
                  color: CupertinoColors.systemGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            backgroundColor: isDark
                ? CupertinoColors.black.withOpacity(0.6)
                : CupertinoColors.white.withOpacity(0.6),
            previousPageTitle: 'Calendar',
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            minSize: 0,
                            padding: const EdgeInsets.all(8),
                            onPressed: _goToPreviousWeek,
                            child: const Icon(CupertinoIcons.chevron_left),
                          ),
                          Text(
                            '${_formatDate(weekDates.first)} - ${_formatDate(weekDates.last)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          CupertinoButton(
                            minSize: 0,
                            padding: const EdgeInsets.all(8),
                            onPressed: _goToNextWeek,
                            child: const Icon(CupertinoIcons.chevron_right),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildWeekCalendarGrid(weekDates, isDark, now),
                      const SizedBox(height: 24),

                      _buildClassBlocksForSelectedDay(isDark),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
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

    return Column(
      children: [

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            return Expanded(
              child: Center(
                child: Text(
                  dayLabels[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),


        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final date = weekDates[index];
            final isToday =
                date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
            final isSelected =
                date.year == selectedDate.year &&
                date.month == selectedDate.month &&
                date.day == selectedDate.day;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = date;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? CupertinoColors.systemBlue
                        : (isDark ? Colors.grey[900] : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(12),
                    border: isToday
                        ? Border.all(
                            color: CupertinoColors.systemBlue,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : (isToday
                                    ? CupertinoColors.systemBlue
                                    : (isDark ? Colors.white : Colors.black)),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  List<dynamic> _getClassesForDay(int dayOfWeek) {

    if (dayOfWeek < 1 || dayOfWeek > 5) {
      return [];
    }

    late final Map<int, List<dynamic>> schedule;

    if (selectedClass == 'CSE 7') {
      schedule = class7.Class7Schedule.weeklySchedule;
    } else if (selectedClass == 'CSE 15') {
      schedule = class15.Class15Schedule.weeklySchedule;
    } else if (selectedClass == 'CSE 16') {
      schedule = class16.ClassSchedule.weeklySchedule;
    } else if (selectedClass == 'CSE 19') {
      schedule = class19.Class19Schedule.weeklySchedule;
    } else if (selectedClass == 'CSE 25') {
      schedule = class25.Class25Schedule.weeklySchedule;
    } else if (selectedClass == 'CSE 35') {
      schedule = class35.Class35Schedule.weeklySchedule;
    } else if (selectedClass == 'CSE 51') {
      schedule = class51.Class51Schedule.weeklySchedule;
    } else {
      schedule = class16.ClassSchedule.weeklySchedule; 
    }

    return schedule[dayOfWeek] ?? [];
  }

  Widget _buildClassBlocksForSelectedDay(bool isDark) {
    final classes = _getClassesForDay(selectedDate.weekday);

    if (classes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'No classes scheduled',
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
          final classPeriod = classes[index];

          if (classPeriod.className == '—') {
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
                  '${classPeriod.startTime} - ${classPeriod.endTime}',
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
                    border: Border(
                      left: const BorderSide(color: primaryBlue, width: 4),
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
                        classPeriod.className,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (classPeriod.room.isNotEmpty &&
                          classPeriod.room != '—')
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
                              classPeriod.room,
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

  void _showClassPicker() {
    int selectedIndex = 0;
    final classes = [
      'CSE 7',
      'CSE 15',
      'CSE 16',
      'CSE 19',
      'CSE 25',
      'CSE 35',
      'CSE 51',
    ];

    selectedIndex = classes.indexOf(selectedClass);
    if (selectedIndex == -1) selectedIndex = 0;

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
                              this.savePreference = value;
                            });
                            _savePreference(selectedClass, value);
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
                        setState(() {
                          selectedClass = classes[index];
                        });
                        this.setState(() {
                          selectedClass = classes[index];
                        });

                        if (savePreference) {
                          _savePreference(classes[index], true);
                        }
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
