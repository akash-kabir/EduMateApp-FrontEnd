import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../services/shared_preferences_service.dart';
import '../../services/sap/sap_auth_service.dart';
import '../../services/schedule_database_helper.dart';
import '../splash/splash_screen.dart';
import '../../constants/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SapAuthService _sapAuthService = SapAuthService();

  bool _scheduleUpdatesEnabled = true;
  bool _holidayRemindersEnabled = true;
  bool _announcementsEnabled = true;
  bool _startUpToTimeSheetEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    // Load existing preferences, defaulting to true if not set
    final scheduleStr = await SharedPreferencesService.getString('pref_schedule_updates');
    final holidayStr = await SharedPreferencesService.getString('pref_holiday_reminders');
    final announceStr = await SharedPreferencesService.getString('pref_announcements');
    final startUpBool = await SharedPreferencesService.getBool('openToTimesheet');
    
    if (mounted) {
      setState(() {
        _scheduleUpdatesEnabled = scheduleStr != 'false';
        _holidayRemindersEnabled = holidayStr != 'false';
        _announcementsEnabled = announceStr != 'false';
        _startUpToTimeSheetEnabled = startUpBool;
      });
    }
  }

  Future<void> _togglePreference(String key, bool value) async {
    await SharedPreferencesService.setString(key, value.toString());
  }

  Future<void> _handleDisconnectSap() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Disconnect SAP?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to clear your SAP credentials? You will need to log in again to view your attendance.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect', style: TextStyle(color: AuthPalette.coral)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _sapAuthService.saveCredentials('', '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SAP Credentials cleared successfully.')),
        );
      }
    }
  }

  Future<void> _handleClearPreferences() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Clear App Cache?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will clear local cache including timetable and saved preferences. Are you sure?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: AuthPalette.coral)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ScheduleDatabaseHelper.instance.clearCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App cache and preferences cleared.')),
        );
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Account', style: TextStyle(color: AuthPalette.coral, fontWeight: FontWeight.bold)),
        content: const Text(
          'This action is irreversible. All your data will be permanently deleted from the device. Are you absolutely sure?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AuthPalette.coral),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: child,
          ),
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
    return CupertinoPageScaffold(
      backgroundColor: UserColors.background,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        border: null,
        middle: Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      child: SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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

            const SizedBox(height: 10),

            // Notifications Section
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 8),
              child: Text(
                'Notifications',
                style: TextStyle(color: AuthPalette.coral, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            _buildGlassCard(
              child: Column(
                children: [
                  _buildListTile(
                    title: 'Schedule Updates',
                    subtitle: 'Alerts when your timetable changes',
                    trailing: CupertinoSwitch(
                      activeColor: AuthPalette.coral,
                      value: _scheduleUpdatesEnabled,
                      onChanged: (val) {
                        setState(() => _scheduleUpdatesEnabled = val);
                        _togglePreference('pref_schedule_updates', val);
                      },
                    ),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.1), height: 1, indent: 20),
                  _buildListTile(
                    title: 'Holiday Reminders',
                    subtitle: 'Get notified at 9 PM the day before',
                    trailing: CupertinoSwitch(
                      activeColor: AuthPalette.coral,
                      value: _holidayRemindersEnabled,
                      onChanged: (val) {
                        setState(() => _holidayRemindersEnabled = val);
                        _togglePreference('pref_holiday_reminders', val);
                      },
                    ),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.1), height: 1, indent: 20),
                  _buildListTile(
                    title: 'Announcements',
                    subtitle: 'New events and feed posts',
                    trailing: CupertinoSwitch(
                      activeColor: AuthPalette.coral,
                      value: _announcementsEnabled,
                      onChanged: (val) {
                        setState(() => _announcementsEnabled = val);
                        _togglePreference('pref_announcements', val);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Accessibility Section
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 8),
              child: Text(
                'Accessibility',
                style: TextStyle(color: AuthPalette.coral, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            _buildGlassCard(
              child: _buildListTile(
                title: 'Starts up to TimeSheet',
                subtitle: 'Open timetable automatically on launch',
                trailing: CupertinoSwitch(
                  activeColor: AuthPalette.coral,
                  value: _startUpToTimeSheetEnabled,
                  onChanged: (val) {
                    setState(() => _startUpToTimeSheetEnabled = val);
                    SharedPreferencesService.setBool('openToTimesheet', val);
                  },
                ),
              ),
            ),

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
    ));
  }
}
