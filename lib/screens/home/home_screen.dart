// ignore_for_file: unused_field

import 'dart:ui';

import 'package:app/screens/home/widgets/dashboard_action_card.dart';
import 'package:app/screens/settings/settings_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../widgets/custom_glass_dialog.dart';
import '../../constants/app_constants.dart';
import '../../services/shared_preferences_service.dart';
import '../profile_setup/profile_setup_screen.dart';
import 'cgpa_calculator/cgpa_calculator_screen.dart';
import 'holiday_list/holiday_list_screen.dart';

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
  bool openAppToTimesheet = false;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    await _loadUserData();
    _checkAndShowProfileSetupDialog();
  }

  Future<void> _loadUserData() async {
    final firstName = await SharedPreferencesService.getFirstName();
    final newFirstName = (firstName != null && firstName.isNotEmpty)
        ? firstName
        : (await SharedPreferencesService.getUserName() ?? 'User');
    final newUserId = await SharedPreferencesService.getUserId();
    final newToken = await SharedPreferencesService.getToken();
    final openTimesheetPref = await SharedPreferencesService.getBool('openToTimesheet');

    setState(() {
      userFirstName = newFirstName;
      userId = newUserId;
      token = newToken;
      openAppToTimesheet = openTimesheetPref;
    });
  }

  Future<void> _checkAndShowProfileSetupDialog() async {
    final isComplete = await SharedPreferencesService.isProfileSetupComplete();
    final neverAsk = await SharedPreferencesService.isNeverAskProfileSetup();
    final isProfileCompleted =
        await SharedPreferencesService.getIsProfileCompleted();

    if (isComplete || neverAsk || isProfileCompleted) return;
    if (!mounted) return;

    // Show the dialog after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showGlassmorphicDialog(
        context: context,
        barrierDismissible: false,
        child: Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64.0,
                          height: 64.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AuthPalette.coral.withOpacity(0.15),
                            border: Border.all(
                              color: AuthPalette.coral.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            CupertinoIcons.person_crop_circle_badge_exclam,
                            color: AuthPalette.coral,
                            size: 32.0,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Complete Your Profile',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Set up your profile to get the most out of EduMate. Your roll number, branch, and section help us personalise your experience.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14.0,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.of(this.context).push(
                                CupertinoPageRoute(
                                  builder: (context) => ProfileSetupScreen(
                                    userId: userId,
                                    token: token,
                                    onProfileSetupComplete: () {
                                      SharedPreferencesService.setProfileSetupComplete(true);
                                    },
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AuthPalette.coral,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Set up Profile',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Close',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextButton(
                                onPressed: () async {
                                  await SharedPreferencesService.setNeverAskProfileSetup(true);
                                  if (context.mounted) Navigator.pop(context);
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: isDark 
                                      ? Colors.red.withOpacity(0.15)
                                      : Colors.red.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Never Ask',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
            );
          }
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Quick Actions Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),

            // Quick Actions Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Row(
                  children: [
                    Expanded(
                      child: DashboardActionCard(
                        title: 'Settings',
                        subtitle: 'Account',
                        icon: CupertinoIcons.settings,
                        gradientColors: const [Color(0xFF6A11CB), Color(0xFF2575FC)],
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DashboardActionCard(
                        title: 'CGPA',
                        subtitle: 'Calculator',
                        icon: CupertinoIcons.plus_slash_minus,
                        gradientColors: const [Color(0xFFF2709C), Color(0xFFFF9472)], // Replaced AuthPalette references just in case
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => const CGPACalculatorScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DashboardActionCard(
                        title: 'Holidays',
                        subtitle: 'Calendar',
                        icon: CupertinoIcons.calendar,
                        gradientColors: const [Color(0xFF5AB69F), Color(0xFF2E8B57)],
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => const HolidayListScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
