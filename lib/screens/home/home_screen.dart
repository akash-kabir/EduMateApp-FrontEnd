import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../profile/profile_screen.dart';
import 'dynamic_island/dynamic_island.dart';
import 'dynamic_island/island_behavior.dart';
import '../profile_setup/profile_setup_screen.dart';
import '../auth/getting_started_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToEvent;
  final VoidCallback? onNavigateToSchedule;

  const HomeScreen({
    super.key,
    this.onNavigateToEvent,
    this.onNavigateToSchedule,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userFirstName = '';
  String? userId;
  String? token;
  late DynamicIslandBehavior _islandBehavior;
  late SharedPreferences _prefs;
  late String _cachedGreeting;
  bool _isProfileCompletedCached = true;

  @override
  void initState() {
    super.initState();
    _islandBehavior = DynamicIslandBehavior(isProfileCompleted: true);
    _cachedGreeting = _calculateGreeting();
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();

    final actualProfileCompleted =
        _prefs.getBool('isProfileCompleted') ?? false;

    if (actualProfileCompleted != _isProfileCompletedCached) {
      setState(() {
        _isProfileCompletedCached = actualProfileCompleted;
        _islandBehavior = DynamicIslandBehavior(
          isProfileCompleted: actualProfileCompleted,
        );
      });
    }

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final newFirstName = _prefs.getString('userFirstName') ?? 'User';
    final newUserId = _prefs.getString('userId');
    final newToken = _prefs.getString('token');

    setState(() {
      userFirstName = newFirstName;
      userId = newUserId;
      token = newToken;
      _cachedGreeting = _calculateGreeting();
    });
  }

  String _calculateGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 16) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  void _debugLogout() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Debug Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const GettingStartedScreen(),
                  ),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              DynamicIsland(
                greeting: _cachedGreeting,
                userName: userFirstName,
                isDark: isDark,
                showProfileSetup: !_isProfileCompletedCached,
                onProfileSetupComplete: () {
                  setState(() {
                    _islandBehavior.onProfileSetupComplete();
                    _isProfileCompletedCached = true;
                  });
                  Navigator.of(context)
                      .push(
                        CupertinoPageRoute(
                          builder: (context) => ProfileSetupScreen(
                            userId: userId,
                            token: token,
                            onProfileSetupComplete: () {
                              setState(() {
                                _islandBehavior.onProfileSetupComplete();
                                _isProfileCompletedCached = true;
                              });
                            },
                          ),
                        ),
                      )
                      .then((_) {
                        _loadUserData();
                      });
                },
                onProfileTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const ProfileScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            const begin = Offset(0.0, 1.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOut;
                            var tween = Tween(
                              begin: begin,
                              end: end,
                            ).chain(CurveTween(curve: curve));
                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          },
                    ),
                  );
                },
                onNavigateToEvent: widget.onNavigateToEvent,
                onNavigateToSchedule: widget.onNavigateToSchedule,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      onPressed: _debugLogout,
                      child: const Text(
                        'Logout (Debug)',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
