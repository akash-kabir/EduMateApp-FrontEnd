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
import 'holiday_list/holiday_list_screen.dart';
import 'widgets/todays_schedule_card.dart';
import '../profile/profile_details_screen.dart';
import '../admin/admin_main_app.dart';

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
      backgroundColor: isDark ? CupertinoColors.black : const Color(0xFFF5F5F7),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Welcome Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 24, 12, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userFirstName.isEmpty ? 'User' : userFirstName,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Trailing Drawer Toggle Button
                    Hero(
                      tag: 'drawer_button',
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          // Open full screen drawer route
                          Navigator.of(context, rootNavigator: true).push(
                            PageRouteBuilder(
                              opaque: false,
                              transitionDuration: const Duration(milliseconds: 400),
                              reverseTransitionDuration: const Duration(milliseconds: 400),
                              pageBuilder: (context, animation, secondaryAnimation) {
                                return FullScreenDrawer(animation: animation, isDark: isDark, userFirstName: userFirstName);
                              },
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.ellipsis,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Today's Schedule Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TodaysScheduleCard(isDark: isDark),
              ),
            ),

            // Quick Actions Grid
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildListDelegate([
                  DashboardActionCard(
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
                  DashboardActionCard(
                    title: 'CGPA',
                    subtitle: 'Calculator',
                    icon: CupertinoIcons.plus_slash_minus,
                    gradientColors: const [Color(0xFFF2709C), Color(0xFFFF9472)],
                    onTap: () {
                      // Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const CGPACalculatorScreen()));
                    },
                  ),
                  DashboardActionCard(
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
                  // Placeholder for future action
                  DashboardActionCard(
                    title: 'More',
                    subtitle: 'Coming soon',
                    icon: CupertinoIcons.app_badge,
                    gradientColors: isDark 
                        ? const [Color(0xFF303030), Color(0xFF1a1a1a)]
                        : const [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
                    onTap: () {},
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

class FullScreenDrawer extends StatefulWidget {
  final Animation<double> animation;
  final bool isDark;
  final String userFirstName;

  const FullScreenDrawer({
    super.key,
    required this.animation,
    required this.isDark,
    required this.userFirstName,
  });

  @override
  State<FullScreenDrawer> createState() => _FullScreenDrawerState();
}

class _FullScreenDrawerState extends State<FullScreenDrawer> {
  String _userEmail = '';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final email = await SharedPreferencesService.getUserEmail();
    final role = await SharedPreferencesService.getUserRole();
    if (mounted) {
      setState(() {
        _userEmail = email ?? 'user@edumate.com';
        _userRole = role ?? 'Student';
      });
    }
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap, Color? color}) {
    return ListTile(
      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Icon(icon, color: color ?? (widget.isDark ? Colors.white70 : Colors.black87), size: 24),
      title: Text(
        title, 
        style: TextStyle(
          color: color ?? (widget.isDark ? Colors.white : Colors.black87),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        )
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bool isAdminOrContributor = _userRole.toLowerCase() == 'admin' || _userRole.toLowerCase() == 'contributor';
    
    return Scaffold(
      backgroundColor: Colors.transparent, // Let underlying app show through
      body: Stack(
        children: [
          // Slide-in Drawer Background & Content
          SlideTransition(
            position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: widget.animation, curve: Curves.easeInOutCubic)),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: widget.isDark 
                      ? Colors.black.withValues(alpha: 0.8) 
                      : Colors.white.withValues(alpha: 0.85),
                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: EdgeInsets.only(top: topPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Edumate Brand Title
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                            child: Text(
                              'EduMate',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1,
                                color: widget.isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          
                          // Drawer Items List
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.zero,
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _buildDrawerItem(
                                  icon: CupertinoIcons.person, 
                                  title: 'Profile', 
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const ProfileDetailsScreen()));
                                  }
                                ),
                                _buildDrawerItem(
                                  icon: CupertinoIcons.settings, 
                                  title: 'Settings', 
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const SettingsScreen()));
                                  }
                                ),
                                _buildDrawerItem(
                                  icon: CupertinoIcons.info_circle, 
                                  title: 'About', 
                                  onTap: () => Navigator.pop(context)
                                ),
                                _buildDrawerItem(
                                  icon: CupertinoIcons.doc_text, 
                                  title: 'Privacy Policy', 
                                  onTap: () => Navigator.pop(context)
                                ),
                                _buildDrawerItem(
                                  icon: CupertinoIcons.doc_checkmark, 
                                  title: 'Terms of Service', 
                                  onTap: () => Navigator.pop(context)
                                ),
                                if (isAdminOrContributor)
                                  _buildDrawerItem(
                                    icon: CupertinoIcons.shield, 
                                    title: 'Admin Dashboard', 
                                    color: AuthPalette.teal,
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const AdminMainApp(fromStudentView: true)));
                                    }
                                  ),
                                _buildDrawerItem(
                                  icon: CupertinoIcons.square_arrow_right, 
                                  title: 'Logout', 
                                  color: Colors.red,
                                  onTap: () async {
                                    await SharedPreferencesService.clearAll();
                                    if (context.mounted) {
                                      Navigator.of(context).pushReplacementNamed('/login');
                                    }
                                  }
                                ),
                              ],
                            ),
                          ),
                          
                          // User Info Card at bottom (Sleek, transparent)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(CupertinoIcons.person_solid, size: 20, color: widget.isDark ? Colors.white70 : Colors.black54),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Logged in as',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: widget.isDark ? Colors.white54 : Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _userEmail,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: widget.isDark ? Colors.white : Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _userRole.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1,
                                          color: widget.isDark ? Colors.white38 : Colors.black38,
                                        ),
                                      ),
                                    ],
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
            ),
          ),
          
          // Floating Button (Top Layer) perfectly positioned to cover the underlying button
          Positioned(
            top: topPadding + 24, // Matches the padding in the header (24) + safe area
            right: 12, // Matches the padding in the header (12)
            child: Hero(
              tag: 'drawer_button',
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  Navigator.pop(context);
                },
                child: AnimatedBuilder(
                  animation: widget.animation,
                  builder: (context, child) {
                    // Interpolate colors based on animation value
                    final bgColor = Color.lerp(
                      widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                      Colors.red.withValues(alpha: 0.1),
                      widget.animation.value,
                    );
                    final iconColor = Color.lerp(
                      widget.isDark ? Colors.white : Colors.black87,
                      Colors.red,
                      widget.animation.value,
                    );
                    
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Transform.rotate(
                        angle: widget.animation.value * 3.14159 / 2, // Rotate 90 degrees as it changes
                        child: Icon(
                          widget.animation.value > 0.5 ? CupertinoIcons.clear : CupertinoIcons.ellipsis,
                          color: iconColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
