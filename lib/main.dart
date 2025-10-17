import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/events_screen.dart';
import 'screens/campus_nav_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/calender_screen.dart';
import 'widgets/bottom_nav_pill.dart';
import 'widgets/app_bar.dart'; 
import 'package:flutter/material.dart';

void main() {
  runApp(const CampusConnectApp());
}

class CampusConnectApp extends StatelessWidget {
  const CampusConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    CalendarScreen(),
    EventsScreen(),
    CampusNavScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: const AppBarWidget(), 
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavPill(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
