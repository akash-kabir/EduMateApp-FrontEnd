import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/features/admin/admin_home_screen.dart';
import 'package:app/features/admin/general/admin_upload_screen.dart';
import 'package:app/features/admin/admin_settings_screen.dart';

import 'package:app/shared/widgets/dialogs/custom_glass_dialog.dart';

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


    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
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
          extendBody: true,
          backgroundColor: CupertinoColors.black,
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


    return Material(
      color: Colors.transparent,
      child: CupertinoTabBar(
        currentIndex: selectedIndex,
        onTap: (index) => onItemTapped(index),
        height: 60,
        backgroundColor: CupertinoColors.black.withValues(alpha: 0.6),
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
              child: Icon(Icons.settings),
            ),
            label: '',
          ),
        ],
      ),
    );
  }
}
