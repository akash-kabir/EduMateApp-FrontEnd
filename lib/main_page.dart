// ignore_for_file: unused_import, unused_element

import 'package:flutter/material.dart';
import 'app_navigation/nav_bar.dart';
import 'app_navigation/app_navigator.dart';
import 'screens/schedule/schedule_screen.dart';
import 'screens/map/map_screen.dart';
import 'screens/event/event_screen.dart';
import 'screens/home/home_screen.dart';

import 'dart:async';
import 'package:http/http.dart' as http;
import 'services/shared_preferences_service.dart';
import 'services/token_refresh_service.dart';
import 'config.dart';
import 'screens/auth/getting_started_screen.dart';

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
      if (response.statusCode == 401) {
        await _handleLogout();
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

// Custom wrapper for HomeScreen to pass navigation callbacks
class _HomeScreenWrapper extends StatelessWidget {
  final Function(int) onNavigate;

  const _HomeScreenWrapper({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      onNavigateToEvent: () {
        onNavigate(2); // Index 2 is EventScreen
      },
      onNavigateToSchedule: () {
        onNavigate(1); // Index 1 is ScheduleScreen
      },
    );
  }
}
