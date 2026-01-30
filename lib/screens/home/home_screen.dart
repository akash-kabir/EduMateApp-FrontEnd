import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../profile/profile_screen.dart';
import '../profile_setup/profile_setup_screen.dart';
import '../auth/getting_started_screen.dart';
import 'cgpa_calculator_screen.dart';

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
  late SharedPreferences _prefs;
  late String _cachedGreeting;

  @override
  void initState() {
    super.initState();
    _cachedGreeting = _calculateGreeting();
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // CGPA Calculator Card
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CGPACalculatorScreen(),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade600,
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.calculate,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'CGPA Calculator',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Calculate your GPA for any semester',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withOpacity(0.7),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
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
