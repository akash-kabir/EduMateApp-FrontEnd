import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_provider.dart';
import '../widgets/menu/custom_dropdown_menu.dart';
import '../schedule/class_16_schedule.dart' as class16;
import '../schedule/class_7_schedule.dart' as class7;
import '../schedule/class_15_schedule.dart' as class15;
import '../schedule/class_19_schedule.dart' as class19;
import '../schedule/class_25_schedule.dart' as class25;
import '../schedule/class_35_schedule.dart' as class35;
import '../schedule/class_51_schedule.dart' as class51;
import 'timesheet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isMenuOpen = false;
  late AnimationController _arrowController;
  late AnimationController _menuItemsController;
  late AnimationController _blurController;
  String userFirstName = '';
  String selectedClass = 'CSE 16';
  List<dynamic> todayClasses = [];

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _menuItemsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _blurController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadUserData();
    _loadSavedClass();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userFirstName = prefs.getString('userFirstName') ?? 'User';
    });
    _updateTodayClasses();
  }

  Future<void> _loadSavedClass() async {
    final prefs = await SharedPreferences.getInstance();
    final savedClass = prefs.getString('selectedClass');
    if (savedClass != null) {
      setState(() {
        selectedClass = savedClass;
      });
      _updateTodayClasses();
    }
  }

  void _updateTodayClasses() {
    setState(() {
      todayClasses = _getClassesForDay(DateTime.now().weekday);
    });
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

  Map<String, int> _getClassStats(List<dynamic> classes) {
    int theory = 0;
    int lab = 0;

    for (var classPeriod in classes) {
      if (classPeriod.className == '—') continue;

      if (classPeriod.className.toLowerCase().contains('lab')) {
        lab++;
      } else {
        theory++;
      }
    }

    return {'theory': theory, 'lab': lab};
  }

  @override
  void dispose() {
    _arrowController.dispose();
    _menuItemsController.dispose();
    _blurController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (!_isMenuOpen) {
      setState(() => _isMenuOpen = true);
      _arrowController.forward();
      _blurController.forward();
      _menuItemsController.forward(from: 0.0);
    } else {
      _arrowController.reverse();
      _blurController.reverse();
      _menuItemsController.reverse().then((_) {
        if (mounted) setState(() => _isMenuOpen = false);
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 16) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
      appBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        middle: const Text(
          'EduMate',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: GestureDetector(
          onTap: _toggleMenu,
          child: AnimatedBuilder(
            animation: _arrowController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _arrowController.value * 3.14159,
                child: const Icon(CupertinoIcons.chevron_down),
              );
            },
          ),
        ),
        backgroundColor:
            (isDark ? CupertinoColors.black : CupertinoColors.white)
                .withOpacity(0.6),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: userFirstName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: CupertinoColors.systemBlue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8.0,
                  ),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Today's Schedule",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.fullscreen_exit,
                                    size: 20,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 16),
                                  CupertinoButton(
                                    minSize: 0,
                                    padding: EdgeInsets.zero,
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const TimesheetScreen(),
                                        ),
                                      );
                                      _loadSavedClass();
                                    },
                                    child: const Icon(
                                      CupertinoIcons.arrow_up_right_circle_fill,
                                      size: 24,
                                      color: CupertinoColors.systemBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (todayClasses.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Builder(
                                builder: (context) {
                                  final stats = _getClassStats(todayClasses);
                                  return Text(
                                    'Theory: ${stats['theory']} | Lab: ${stats['lab']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.grey[300]
                                          : Colors.grey[700],
                                    ),
                                  );
                                },
                              ),
                            ),
                          todayClasses.isEmpty
                              ? Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey[900]
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No classes today',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: todayClasses.length,
                                    itemBuilder: (context, index) {
                                      final classPeriod = todayClasses[index];
                                      if (classPeriod.className == '—') {
                                        return const SizedBox.shrink();
                                      }

                                      final backgroundColor = isDark
                                          ? Colors.grey[850]
                                          : Colors.grey[300];

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 12.0,
                                        ),
                                        child: Container(
                                          width: 160,
                                          decoration: BoxDecoration(
                                            color: backgroundColor,
                                            border: Border(
                                              left: const BorderSide(
                                                color:
                                                    CupertinoColors.systemBlue,
                                                width: 4,
                                              ),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${classPeriod.startTime} - ${classPeriod.endTime}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? Colors.grey[400]
                                                      : Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                classPeriod.className,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),
                                              if (classPeriod.room.isNotEmpty &&
                                                  classPeriod.room != '—')
                                                Text(
                                                  classPeriod.room,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark
                                                        ? Colors.grey[400]
                                                        : Colors.grey[600],
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          if (_isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMenu,
                child: AnimatedBuilder(
                  animation: _blurController,
                  builder: (context, child) {
                    return BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 8 * _blurController.value,
                        sigmaY: 8 * _blurController.value,
                      ),
                      child: Container(
                        color: (isDark ? Colors.black : Colors.white)
                            .withOpacity(0.4 * _blurController.value),
                      ),
                    );
                  },
                ),
              ),
            ),

          if (_isMenuOpen)
            CustomDropdownMenu(
              menuItemsController: _menuItemsController,
              onClose: _toggleMenu,
              themeProvider: themeProvider,
            ),
        ],
      ),
    );
  }
}
