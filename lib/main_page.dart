import 'package:flutter/material.dart';
import 'package:app/app_navigation/app_navigator.dart';

import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:app/shared/services/shared_preferences_service.dart';
import 'package:app/features/auth_and_profile/services/token_refresh_service.dart';
import 'package:app/shared/config.dart';
import 'package:app/features/auth_and_profile/screens/auth/getting_started_screen.dart';
import 'package:provider/provider.dart';
import 'package:app/features/sapsync/provider/sap_provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  Timer? _pollingTimer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start polling every 5 minutes while active
    _pollingTimer = Timer.periodic(const Duration(minutes: 5), (_) => _checkSession());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSession();
    }
  }

  Future<void> _checkSession() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final token = await SharedPreferencesService.getToken();
      if (token == null || token.isEmpty) {
        _isChecking = false;
        return;
      }

      final response = await TokenRefreshService.authenticatedGet(
        '${Config.BASE_URL}/api/users/me'
      );

      // If it's STILL 401 after the refresh service attempted to refresh, the user is truly invalid/deleted.
      // 404 means the backend DB lookup explicitly failed (user deleted).
      if (response.statusCode == 401 || response.statusCode == 404) {
        await _handleLogout();
        return;
      }

      // Check for role updates
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['user'] != null) {
          final newRole = body['user']['role']?.toString().toLowerCase();
          if (newRole != null) {
            final oldRole = await SharedPreferencesService.getString('user_role');
            if (oldRole != null && oldRole.isNotEmpty && newRole != oldRole.toLowerCase()) {
              await SharedPreferencesService.setString('user_role', newRole);
              // Force token refresh to immediately load new role into JWT payload
              await TokenRefreshService.refreshToken();
              if (mounted) {
                _showRoleChangeDialog(newRole);
              }
            }
          }
        }
      }
    } catch (e) {
      // Ignore network errors, only act on 401
    } finally {
      if (mounted) _isChecking = false;
    }
  }

  void _showRoleChangeDialog(String newRole) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Color(0xFF6366F1),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Role Updated',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your account role has been updated to ${newRole.toUpperCase()} by an administrator. Your permissions have been automatically refreshed.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Got it',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    _pollingTimer?.cancel();
    await SharedPreferencesService.clearUserData();
    if (!mounted) return;
    
    // Clear SAP provider data
    await Provider.of<SapProvider>(context, listen: false).logout();
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const GettingStartedScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const AppNavigator();
  }
}
