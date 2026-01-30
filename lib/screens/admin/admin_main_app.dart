import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'admin_screens/admin_home_screen.dart';
import 'admin_screens/admin_upload_screen.dart';

class AdminMainApp extends StatefulWidget {
  const AdminMainApp({super.key});

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
            children: const [AdminHomeScreen(), AdminUploadScreen()],
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
            ? CupertinoColors.black.withOpacity(0.6)
            : CupertinoColors.white.withOpacity(0.6),
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
        ],
      ),
    );
  }
}
