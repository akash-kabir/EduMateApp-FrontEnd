import 'dart:ui';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/events_screen.dart';
import 'screens/campus_nav_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/calender_screen.dart';
import 'widgets/bottom_nav_pill.dart';
import 'widgets/app_bar.dart';
import 'widgets/custom_dropdown_menu.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isMenuOpen = false;
  late AnimationController _arrowController;
  late AnimationController _menuItemsController;

  final List<Widget> _pages = const [
    HomeScreen(),
    CalendarScreen(),
    EventsScreen(),
    CampusNavScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _menuItemsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _arrowController.dispose();
    _menuItemsController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _arrowController.forward();
        _menuItemsController.forward(from: 0.0);
      } else {
        _arrowController.reverse();
        _menuItemsController.reverse();
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isMenuOpen = false;
      _arrowController.reverse();
      _menuItemsController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          _pages[_selectedIndex],

          if (_isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMenu,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(color: Colors.black.withOpacity(0.4)),
                ),
              ),
            ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBarWidget(
                onMenuPressed: _toggleMenu,
                arrowAnimation: _arrowController,
              ),

              if (_isMenuOpen)
                CustomDropdownMenu(
                  menuItemsController: _menuItemsController,
                  onClose: _toggleMenu,
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavPill(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
