import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoBottomTabBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CupertinoBottomTabBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoTabBar(
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      height: 60,
      backgroundColor: isDark
          ? CupertinoColors.black.withOpacity(0.6)
          : CupertinoColors.white.withOpacity(0.6),
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
            child: Icon(CupertinoIcons.calendar),
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Icon(CupertinoIcons.doc_text),
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Icon(CupertinoIcons.map),
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Icon(CupertinoIcons.person),
          ),
          label: '',
        ),
      ],
    );
  }
}
