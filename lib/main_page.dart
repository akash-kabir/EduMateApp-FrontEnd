// ignore_for_file: unused_import, unused_element

import 'package:flutter/material.dart';
import 'app_navigation/nav_bar.dart';
import 'app_navigation/app_navigator.dart';
import 'screens/schedule/schedule_screen.dart';
import 'screens/map/map_screen.dart';
import 'screens/event/event_screen.dart';
import 'screens/home/home_screen.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
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
