import 'package:flutter/cupertino.dart';

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
    return CupertinoTabBar(
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      height: 60,
      backgroundColor: const Color(0xFF000000).withValues(alpha: 0.6),
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
            child: Icon(CupertinoIcons.bell),
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
      ],
    );
  }
}
