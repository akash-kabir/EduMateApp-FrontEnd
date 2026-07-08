import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'admin_screens/admin_home_screen.dart';
import 'admin_screens/admin_upload_screen.dart';
import 'admin_screens/admin_poi_management.dart';

class AdminMainApp extends StatefulWidget {
  final bool fromStudentView;
  const AdminMainApp({super.key, this.fromStudentView = false});

  @override
  State<AdminMainApp> createState() => _AdminMainAppState();
}

class _AdminMainAppState extends State<AdminMainApp> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
      child: Scaffold(
        backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              AdminHomeScreen(fromStudentView: widget.fromStudentView),
              const AdminUploadScreen(),
              const AdminPoiManagementScreen(),
            ],
          ),
        ),
        bottomNavigationBar: _AdminNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: (index) {
            setState(() => _selectedIndex = index);
          },
        ),
      ),
    );
  }
}

class _AdminNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const _AdminNavBar({required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? CupertinoColors.black : CupertinoColors.white,
      child: CupertinoTabBar(
        currentIndex: selectedIndex,
        onTap: (index) => onItemTapped(index),
        height: 60,
        backgroundColor: isDark
            ? CupertinoColors.black.withValues(alpha: 0.6)
            : CupertinoColors.white.withValues(alpha: 0.6),
        activeColor: const Color(0xFFFF1744),
        inactiveColor: CupertinoColors.systemGrey,
        items: [
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Icon(CupertinoIcons.home),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Icon(CupertinoIcons.cloud_upload),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Icon(CupertinoIcons.map_pin_ellipse),
            ),
            label: '',
          ),
        ],
      ),
    );
  }
}
