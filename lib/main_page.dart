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
import 'package:app/shared/widgets/dialogs/role_change_dialog.dart';
import 'package:app/main.dart';

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
        final newRole = body['role']?.toString().toLowerCase();
        if (newRole != null) {
          final oldRole = await SharedPreferencesService.getUserRole();
          if (oldRole != null && oldRole.isNotEmpty && newRole != oldRole.toLowerCase()) {
            await SharedPreferencesService.setUserRole(newRole);
            // Force token refresh to immediately load new role into JWT payload
            await TokenRefreshService.refreshToken();
            if (mounted && navigatorKey.currentContext != null) {
              showGlobalRoleChangeDialog(navigatorKey.currentContext!, oldRole, newRole);
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

  Future<void> _handleLogout() async {
    _pollingTimer?.cancel();
    await SharedPreferencesService.clearUserData();
    if (!mounted) return;
    
    // Clear SAP provider data
    await Provider.of<SapProvider>(context, listen: false).logout();
    
    if (!mounted) return;

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
