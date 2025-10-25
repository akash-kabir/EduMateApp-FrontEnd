import 'package:flutter/material.dart';
import 'widgets/navigation/bottom_nav_pill.dart';
import 'screens/calender_screen.dart';
import 'screens/campus_nav_screen.dart';
import 'screens/events_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    CalenderScreen(),
    EventsScreen(),
    CampusNavScreen(),
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
      bottomNavigationBar: BottomNavPill(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}