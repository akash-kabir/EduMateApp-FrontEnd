import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/shared/services/shared_preferences_service.dart';
import 'package:app/features/sapsync/services/sap_auth_service.dart';
import 'package:app/features/schedule/services/schedule_database_helper.dart';
import 'package:app/features/splash/screens/splash_screen.dart';
import 'package:app/theme/theme.dart';
import 'package:app/shared/widgets/dialogs/toast_manager.dart';
import 'package:app/shared/config.dart';
import 'package:app/shared/widgets/dialogs/custom_glass_dialog.dart';
import 'package:app/features/auth_and_profile/services/token_refresh_service.dart';
import 'package:app/features/home/screens/post_management_screen.dart';
import 'package:app/features/admin/admin_main_app.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SapAuthService _sapAuthService = SapAuthService();
  late ScrollController _scrollController;

  bool _startUpToTimeSheetEnabled = false;
  String _userRole = '';
  bool _hideSapSync = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadPreferences();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final startUpBool = await SharedPreferencesService.getBool('openToTimesheet');
    final role = await SharedPreferencesService.getUserRole() ?? '';
    final hideSap = await SharedPreferencesService.getBool('hideSapSync');
    
    if (mounted) {
      setState(() {
        _startUpToTimeSheetEnabled = startUpBool;
        _userRole = role;
        _hideSapSync = hideSap;
      });
    }
  }


  Future<void> _handleDisconnectSap() async {
    final bool? confirm = await showGlassmorphicDialog<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Disconnect SAP?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Are you sure you want to clear your SAP credentials? You will need to log in again to view your attendance.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Center(
                      child: Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('Disconnect', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _sapAuthService.saveCredentials('', '');
      if (mounted) {
        EduMateToast.showCompact(
          context,
          message: 'SAP Credentials cleared successfully.',
          isSuccess: true,
        );
      }
    }
  }

  Future<void> _handleClearPreferences() async {
    final bool? confirm = await showGlassmorphicDialog<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Clear App Cache?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This will clear local cache including timetable and saved preferences. Are you sure?',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Center(
                      child: Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AuthPalette.coral,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('Clear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ScheduleDatabaseHelper.instance.clearCache();
      if (mounted) {
        EduMateToast.showCompact(
          context,
          message: 'App cache and preferences cleared.',
          isSuccess: true,
        );
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final bool? confirm = await showGlassmorphicDialog<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Delete Account',
            style: TextStyle(
              color: AuthPalette.coral,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This action is irreversible. All your data will be permanently deleted from the device. Are you absolutely sure?',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Center(
                      child: Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AuthPalette.coral,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final token = await SharedPreferencesService.getToken();
        if (token != null) {
          final response = await TokenRefreshService.authenticatedDelete(Config.profileEndpoint);
          
          if (response.statusCode != 200) {
            if (mounted) {
              EduMateToast.showCompact(
                context,
                message: 'Failed to delete account on server.',
                isSuccess: false,
              );
            }
            return;
          }
        }
      } catch (e) {
        if (mounted) {
          EduMateToast.showCompact(
            context,
            message: 'Network error. Could not delete account.',
            isSuccess: false,
          );
        }
        return;
      }

      await SharedPreferencesService.clearAll();
      await ScheduleDatabaseHelper.instance.clearCache();
      
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF141110),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: child,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canManagePosts = _userRole.toLowerCase() == 'admin' || _userRole.toLowerCase() == 'society';
    final bool isAdminOrContributor = _userRole.toLowerCase() == 'admin' || _userRole.toLowerCase() == 'contributor';

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
                                'Settings',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'Salena',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Color(0xFFFF9B7A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: RepaintBoundary(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Connectivity Section
                          const Padding(
                            padding: EdgeInsets.only(left: 8, bottom: 8),
                            child: Text(
                              'Connectivity & Data',
                              style: TextStyle(color: AuthPalette.coral, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          _buildGlassCard(
                            child: Column(
                              children: [
                                _buildListTile(
                                  title: 'Disconnect SAP',
                                  subtitle: 'Clear your portal credentials',
                                  trailing: const Icon(CupertinoIcons.chevron_right, color: Colors.white54, size: 20),
                                  onTap: _handleDisconnectSap,
                                ),
                                Divider(color: Colors.white.withValues(alpha: 0.1), height: 1, indent: 20),
                                _buildListTile(
                                  title: 'Clear Preferences',
                                  subtitle: 'Wipe local cache and configs',
                                  trailing: const Icon(CupertinoIcons.chevron_right, color: Colors.white54, size: 20),
                                  onTap: _handleClearPreferences,
                                ),
                              ],
                            ),
                          ),



                          // Accessibility Section
                          const Padding(
                            padding: EdgeInsets.only(left: 8, bottom: 8),
                            child: Text(
                              'Accessibility',
                              style: TextStyle(color: AuthPalette.coral, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          _buildGlassCard(
                            child: Column(
                              children: [
                                _buildListTile(
                                  title: 'Starts up to TimeSheet',
                                  subtitle: 'Open timetable automatically on launch',
                                  trailing: CupertinoSwitch(
                                    activeTrackColor: AuthPalette.coral,
                                    value: _startUpToTimeSheetEnabled,
                                    onChanged: (val) {
                                      setState(() => _startUpToTimeSheetEnabled = val);
                                      SharedPreferencesService.setBool('openToTimesheet', val);
                                    },
                                  ),
                                ),
                                Divider(color: Colors.white.withValues(alpha: 0.1), height: 1, indent: 20),
                                _buildListTile(
                                  title: 'Hide SAPSync',
                                  subtitle: 'Hide the SAP card from the home screen',
                                  trailing: CupertinoSwitch(
                                    activeTrackColor: AuthPalette.coral,
                                    value: _hideSapSync,
                                    onChanged: (val) async {
                                      if (val) {
                                        final creds = await _sapAuthService.getCredentials();
                                        if (creds != null && creds['username'] != null && creds['username']!.isNotEmpty) {
                                          if (mounted) {
                                            EduMateToast.showCompact(
                                              context,
                                              message: 'Please disconnect SAPSync first to hide it.',
                                              isSuccess: false,
                                            );
                                          }
                                          return;
                                        }
                                      }
                                      setState(() => _hideSapSync = val);
                                      SharedPreferencesService.setBool('hideSapSync', val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (canManagePosts || isAdminOrContributor) ...[
                            const SizedBox(height: 20),
                            const Padding(
                              padding: EdgeInsets.only(left: 8, bottom: 8),
                              child: Text(
                                'Admin Tools',
                                style: TextStyle(color: AuthPalette.coral, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            _buildGlassCard(
                              child: Column(
                                children: [
                                  if (canManagePosts) ...[
                                    _buildListTile(
                                      title: 'Manage Posts',
                                      subtitle: 'View and moderate community posts',
                                      trailing: const Icon(CupertinoIcons.chevron_right, color: Colors.white54, size: 20),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          CupertinoPageRoute(builder: (_) => const PostManagementScreen()),
                                        );
                                      },
                                    ),
                                    if (isAdminOrContributor)
                                      Divider(color: Colors.white.withValues(alpha: 0.1), height: 1, indent: 20),
                                  ],
                                  if (isAdminOrContributor)
                                    _buildListTile(
                                      title: 'Admin Dashboard',
                                      subtitle: 'Manage users, settings, and more',
                                      trailing: const Icon(CupertinoIcons.chevron_right, color: Colors.white54, size: 20),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          CupertinoPageRoute(builder: (_) => const AdminMainApp(fromStudentView: true)),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Danger Zone
                          const Padding(
                            padding: EdgeInsets.only(left: 8, bottom: 8),
                            child: Text(
                              'Danger Zone',
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          _buildGlassCard(
                            child: _buildListTile(
                              title: 'Delete Account',
                              subtitle: 'Permanently remove all your data',
                              trailing: const Icon(CupertinoIcons.chevron_right, color: Colors.white54, size: 20),
                              onTap: _handleDeleteAccount,
                            ),
                          ),
                        ],
                      ),
                    ),
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
