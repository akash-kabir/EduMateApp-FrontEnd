import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'admin_screens/admin_home_screen.dart';
import 'admin_screens/admin_upload_screen.dart';
import 'admin_screens/admin_settings_screen.dart';

import '../../widgets/custom_glass_dialog.dart';

class AdminMainApp extends StatefulWidget {
  final bool fromStudentView;
  const AdminMainApp({super.key, this.fromStudentView = false});

  @override
  State<AdminMainApp> createState() => _AdminMainAppState();
}

class _AdminMainAppState extends State<AdminMainApp> {
  int _selectedIndex = 1; // Default to Home (middle tab)

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, dynamic result) async {
          if (didPop) return;
          final bool? confirm = await showConfirmationDialog(
            context: context,
            title: 'Exit Admin Panel',
            description: 'Return to Student View?',
            confirmButtonText: 'Yes',
            iconData: CupertinoIcons.arrow_turn_up_left,
          );
          if (confirm == true && context.mounted) {
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
          body: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                const AdminUploadScreen(),
                AdminHomeScreen(fromStudentView: widget.fromStudentView),
                const AdminSettingsScreen(),
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
              child: Icon(CupertinoIcons.cloud_upload),
            ),
            label: '',
          ),
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
              child: Icon(CupertinoIcons.settings),
            ),
            label: '',
          ),
        ],
      ),
    );
  }
}
