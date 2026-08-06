// ignore_for_file: unused_field

import 'dart:ui';

import 'package:app/features/home/widgets/dashboard_action_card.dart';
import 'package:app/features/settings/screens/settings_screen.dart';
import 'package:app/screens/about/about_screen.dart';
import 'package:app/features/feedback/screens/feedback_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/shared/widgets/dialogs/custom_glass_dialog.dart';
import 'package:app/theme/theme.dart';
import 'package:app/features/friends/screens/friends_schedule_screen.dart';
import 'package:app/shared/services/shared_preferences_service.dart';
import 'package:app/shared/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/shared/widgets/dialogs/toast_manager.dart';

import 'package:app/features/auth_and_profile/screens/profile_setup/profile_setup_dialog_flow.dart';

import 'package:app/features/home/screens/holiday_list_screen.dart';
import 'package:app/features/home/widgets/todays_schedule_card.dart';
import 'package:app/features/sapsync/widgets/sapsync_entry_card.dart';
import 'package:app/features/auth_and_profile/screens/profile/profile_details_screen.dart';
import 'package:app/features/splash/screens/splash_screen.dart';
import 'package:app/features/home/screens/cgpa_calculator_screen.dart';
import 'package:provider/provider.dart';
import 'package:app/features/sapsync/provider/sap_provider.dart';

enum SyncState { idle, loading, success, failed, incomplete, incompleteNeverAsk }

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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  String userFullName = '';
  String? userId;
  String? token;
  bool openAppToTimesheet = false;
  String _userRole = '';
  Key _scheduleCardKey = UniqueKey();
  bool _hideSapSync = false;
  
  SyncState _syncState = SyncState.idle;
  late AnimationController _syncAnimationController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _syncAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _initializePreferences();
  }
  
  @override
  void dispose() {
    _syncAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializePreferences() async {
    await _loadUserData();
    _checkAndShowProfileSetupDialog();
    _performProfileSync();
    _triggerSapSync();
  }

  void _triggerSapSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sapProvider = Provider.of<SapProvider>(context, listen: false);
      if (sapProvider.isConnected && !_hideSapSync) {
        sapProvider.fetchAttendance(); // Silent background sync
      }
    });
  }

  Future<void> _performProfileSync() async {
    if (_userRole.toLowerCase() == 'guest') return;
    
    final isComplete = await SharedPreferencesService.isProfileSetupComplete();
    final neverAsk = await SharedPreferencesService.isNeverAskProfileSetup();
    final isProfileCompleted = await SharedPreferencesService.getIsProfileCompleted();
    
    if (!isComplete && !isProfileCompleted) {
      if (!mounted) return;
      setState(() {
        _syncState = neverAsk ? SyncState.incompleteNeverAsk : SyncState.incomplete;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _syncState = SyncState.loading;
    });
    _syncAnimationController.repeat();
    
    if (token != null) {
      try {
        final result = await ApiService.getUserProfile(token: token!);
        if (result['success'] == true) {
          final data = result['data'];
          if (data != null && data['data'] != null) {
            await SharedPreferencesService.saveFullUserProfile(data['data'] as Map<String, dynamic>);
            if (!mounted) return;
            _syncAnimationController.stop();
            setState(() {
              _syncState = SyncState.success;
            });
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted && _syncState == SyncState.success) {
                setState(() {
                  _syncState = SyncState.idle;
                });
              }
            });
            return;
          }
        }
      } catch (e) {
        debugPrint('Profile sync error: $e');
      }
    }
    
    if (!mounted) return;
    _syncAnimationController.stop();
    setState(() {
      _syncState = SyncState.failed;
    });
  }

  Future<void> _loadUserData() async {
    final firstName = await SharedPreferencesService.getFirstName();
    final lastName = await SharedPreferencesService.getLastName();
    String newFullName = '';
    
    if (firstName != null && firstName.isNotEmpty) {
      newFullName = firstName;
      if (lastName != null && lastName.isNotEmpty) {
        newFullName += ' $lastName';
      }
    } else {
      newFullName = await SharedPreferencesService.getUserName() ?? 'User';
    }
    
    final newUserId = await SharedPreferencesService.getUserId();
    final newToken = await SharedPreferencesService.getToken();
    final openTimesheetPref = await SharedPreferencesService.getBool('openToTimesheet');
    final role = await SharedPreferencesService.getUserRole();
    final hideSap = await SharedPreferencesService.getBool('hideSapSync');

    if (!mounted) return;
    setState(() {
      userFullName = newFullName;
      userId = newUserId;
      token = newToken;
      openAppToTimesheet = openTimesheetPref;
      _userRole = role ?? '';
      _hideSapSync = hideSap;
      _scheduleCardKey = UniqueKey(); // Force TodaysScheduleCard to re-fetch data
    });
  }

  Future<void> _checkAndShowProfileSetupDialog() async {
    final role = await SharedPreferencesService.getUserRole();
    if (role?.toLowerCase() == 'guest') {
      final hasSeenDialog = await SharedPreferencesService.getBool('hasSeenGuestDialog');
      if (hasSeenDialog != true) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showGuestWelcomeDialog();
        });
      }
      return;
    }

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

            return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Complete Your Profile',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Please set up your profile to personalise your timetable and schedule.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14.0,
                            color: Colors.grey[400],
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Close this prompt
                              showGlassmorphicDialog(
                                context: context,
                                barrierDismissible: false,
                                child: ProfileSetupDialogFlow(
                                  userId: userId,
                                  token: token,
                                  onComplete: () {
                                    _loadUserData();
                                  },
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
                                    color: Colors.white70,
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
                                  backgroundColor: Colors.red.withValues(alpha: 0.15),
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

  void _showGuestWelcomeDialog() {
    SharedPreferencesService.setBool('hasSeenGuestDialog', true);
    showGlassmorphicDialog(
      context: context,
      barrierDismissible: false,
      child: Builder(
        builder: (context) {

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.0,
                height: 64.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AuthPalette.coral.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AuthPalette.coral.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.person_crop_circle_badge_exclam,
                  color: AuthPalette.coral,
                  size: 32.0,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome, Guest!',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You are logged in as a Guest. You have access to the Home and Schedule screens for 3 days. Map and Events are restricted.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14.0,
                  color: Colors.grey[400],
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
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthPalette.coral,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                  child: const Text(
                    'Got it!',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      child: Stack(
        children: [
          ShaderMask(
            shaderCallback: (Rect rect) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const [
                  Colors.transparent,
                  Colors.black,
                ],
                stops: const [0.0, 0.08], // Fades top 8% of the scroll view
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Welcome Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, MediaQuery.of(context).padding.top + 16, 12, 24),
                  child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userRole.toLowerCase() == 'guest' ? 'Welcome' : 'Welcome back,',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFFFF9B7A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _userRole.toLowerCase() == 'guest' ? 'Guest' : (userFullName.isEmpty ? 'User' : userFullName),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Sync Status Indicator
                    if (_syncState != SyncState.idle)
                      Hero(
                        tag: 'sync_button',
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            if (_syncState == SyncState.incompleteNeverAsk || _syncState == SyncState.incomplete) {
                                showGlassmorphicDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  child: ProfileSetupDialogFlow(
                                    onComplete: () {
                                      _performProfileSync();
                                    },
                                  ),
                                );
                            } else if (_syncState == SyncState.failed) {
                                _performProfileSync();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141110),
                              shape: BoxShape.circle,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _buildSyncIcon(),
                            ),
                          ),
                        ),
                      ),
                    if (_syncState != SyncState.idle) const SizedBox(width: 8),
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
                                return FullScreenDrawer(animation: animation, userFullName: userFullName);
                              },
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141110),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.ellipsis,
                            color: Colors.white,
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
                child: TodaysScheduleCard(key: _scheduleCardKey),
              ),
            ),

            // SapSync Entry Card
            if (!_hideSapSync)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SapSyncEntryCard(),
                ),
              ),

            // Quick Actions Grid
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildListDelegate([

                  DashboardActionCard(
                    title: 'CGPA',
                    subtitle: 'Calculator',
                    icon: CupertinoIcons.plus_slash_minus,
                    gradientColors: const [Color(0xFFF2709C), Color(0xFFFF9472)],
                    onTap: () {
                      Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const CGPACalculatorScreen()));
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
                  DashboardActionCard(
                    title: 'Friends',
                    subtitle: 'Schedule',
                    icon: CupertinoIcons.person_2,
                    gradientColors: const [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const FriendsScheduleScreen(),
                        ),
                      );
                    },
                  ),
                  DashboardActionCard(
                    title: 'More features',
                    subtitle: 'Coming soon',
                    icon: CupertinoIcons.sparkles,
                    gradientColors: const [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                    onTap: () {
                      // Placeholder for future feature
                    },
                  ),
                ]),
              ),
            ),
            // Extra padding at the bottom so the last item can clear the nav bar
            const SliverToBoxAdapter(
              child: SizedBox(height: 65),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSyncIcon() {
    switch (_syncState) {
      case SyncState.loading:
        return RotationTransition(
          turns: _syncAnimationController,
          key: const ValueKey('loading'),
          child: const Icon(CupertinoIcons.arrow_2_circlepath, color: AuthPalette.coral, size: 22),
        );
      case SyncState.success:
        return const Icon(CupertinoIcons.checkmark_alt_circle_fill, color: Color(0xFF4CD97B), size: 22, key: ValueKey('success'));
      case SyncState.failed:
        return const Icon(CupertinoIcons.clear_circled, color: Colors.redAccent, size: 22, key: ValueKey('failed'));
      case SyncState.incomplete:
        return Icon(CupertinoIcons.cloud, color: Colors.grey.withValues(alpha: 0.5), size: 22, key: const ValueKey('incomplete'));
      case SyncState.incompleteNeverAsk:
        return const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.redAccent, size: 22, key: ValueKey('neverAsk'));
      default:
        return const SizedBox.shrink(key: ValueKey('idle'));
    }
  }
}

class FullScreenDrawer extends StatefulWidget {
  final Animation<double> animation;
  final String userFullName;

  const FullScreenDrawer({
    super.key,
    
    required this.animation,
    required this.userFullName,
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
      leading: Icon(icon, color: color ?? Colors.white70, size: 24),
      title: Text(
        title, 
        style: TextStyle(
          color: color ?? Colors.white,
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
                  color: Colors.black.withValues(alpha: 0.8),
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
                                color: Colors.white,
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
                                  icon: Icons.settings, 
                                  title: 'Settings', 
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) => const SettingsScreen(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return SlideTransition(
                                            position: Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero)
                                                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  }
                                ),
                                _buildDrawerItem(
                                  icon: CupertinoIcons.info_circle, 
                                  title: 'About', 
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) => const AboutScreen(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return SlideTransition(
                                            position: Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero)
                                                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  }
                                ),
                                _buildDrawerItem(
                                  icon: CupertinoIcons.chat_bubble_2, 
                                  title: 'Feedback', 
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) => const FeedbackScreen(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return SlideTransition(
                                            position: Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero)
                                                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  }
                                ),
                                _buildDrawerItem(
                                  icon: CupertinoIcons.doc_text, 
                                  title: 'Privacy Policy', 
                                  onTap: () async {
                                    final Uri url = Uri.parse('https://www.edumateapp.com/privacy-policy.html');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url, mode: LaunchMode.externalApplication);
                                    } else {
                                      if (context.mounted) {
                                        EduMateToast.showCompact(context, message: 'Could not open Privacy Policy', isSuccess: false);
                                      }
                                    }
                                  }
                                ),
                                _buildDrawerItem(
                                  icon: CupertinoIcons.doc_checkmark, 
                                  title: 'Terms of Service', 
                                  onTap: () async {
                                    final Uri url = Uri.parse('https://www.edumateapp.com/terms-of-service.html');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url, mode: LaunchMode.externalApplication);
                                    } else {
                                      if (context.mounted) {
                                        EduMateToast.showCompact(context, message: 'Could not open Terms of Service', isSuccess: false);
                                      }
                                    }
                                  }
                                ),

                                _buildDrawerItem(
                                  icon: CupertinoIcons.square_arrow_right, 
                                  title: 'Logout', 
                                  color: Colors.red,
                                  onTap: () async {
                                    final confirm = await showConfirmationDialog(
                                      context: context,
                                      title: 'Logout',
                                      description: 'Are you sure to logout?',
                                      confirmButtonText: 'Logout',
                                      iconData: CupertinoIcons.square_arrow_right,
                                      primaryColor: CupertinoColors.systemRed,
                                    );
                                    if (confirm != true) return;
                                    
                                    await SharedPreferencesService.clearUserData();
                                    if (context.mounted) {
                                      await Provider.of<SapProvider>(context, listen: false).logout();
                                      if (!context.mounted) return;
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        CupertinoPageRoute(builder: (_) => const SplashScreen()),
                                        (route) => false,
                                      );
                                    }
                                  }
                                ),
                              ],
                            ),
                          ),
                          
                          // User Info Card at bottom (Sleek, transparent)
                          Padding(
                            padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 12 : 24),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(CupertinoIcons.person_solid, size: 20, color: Colors.white70),
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
                                          color: Colors.white54,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _userRole.toLowerCase() == 'guest' ? 'Guest' : _userEmail,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (_userRole.toLowerCase() != 'guest') ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          _userRole.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            letterSpacing: 1.2,
                                            fontWeight: FontWeight.w700,
                                            color: AuthPalette.coral,
                                          ),
                                        ),
                                      ],
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
                      Colors.white.withValues(alpha: 0.1),
                      Colors.red.withValues(alpha: 0.1),
                      widget.animation.value,
                    );
                    final iconColor = Color.lerp(
                      Colors.white,
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
