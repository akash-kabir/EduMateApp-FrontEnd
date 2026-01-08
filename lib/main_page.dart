import 'package:flutter/material.dart';
import 'app_navigation/nav_bar.dart';
import 'screens/schedule/schedule_screen.dart';
import 'screens/map/map_screen.dart';
import 'screens/event/event_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    ScheduleScreen(),
    EventScreen(),
    MapScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_selectedIndex],
      bottomNavigationBar: CupertinoBottomTabBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
