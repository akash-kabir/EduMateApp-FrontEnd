import 'package:flutter/material.dart';

class BottomNavPill extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavPill({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navIcon(Icons.home_rounded, 0),
            _navIcon(Icons.calendar_today, 1),
            _navIcon(Icons.feed_rounded, 2),
            _navIcon(Icons.navigation_rounded, 3),
            _navIcon(Icons.person, 4),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, int index) {
    final bool isActive = selectedIndex == index;
    return IconButton(
      onPressed: () => onItemTapped(index),
      icon: Icon(
        icon,
        color: isActive ? const Color(0xFF007AFF) : Colors.white,
      ),
    );
  }
}
