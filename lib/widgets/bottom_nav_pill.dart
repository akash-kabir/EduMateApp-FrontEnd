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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navIcon(Icons.home_rounded, 0, isDark),
            _navIcon(Icons.calendar_today, 1, isDark),
            _navIcon(Icons.feed_rounded, 2, isDark),
            _navIcon(Icons.navigation_rounded, 3, isDark),
            _navIcon(Icons.person, 4, isDark),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, int index, bool isDark) {
    final bool isActive = selectedIndex == index;
    return IconButton(
      onPressed: () => onItemTapped(index),
      icon: Icon(
        icon,
        color: isActive
            ? const Color(0xFF007AFF)
            : (isDark ? Colors.white : Colors.black54),
      ),
    );
  }
}
