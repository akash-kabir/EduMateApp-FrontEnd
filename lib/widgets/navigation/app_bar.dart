import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'buttons/animated_chevron_down.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed;
  final AnimationController arrowAnimation;

  const AppBarWidget({
    super.key,
    required this.onMenuPressed,
    required this.arrowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: (isDark ? Colors.black : Colors.white).withOpacity(0.8),
      elevation: 0,
      titleSpacing: 16,
      title: Text(
        'EduMate',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: IconButton(
            onPressed: onMenuPressed,
            icon: AnimatedChevronDown(
              isExpanded: false,
              controller: arrowAnimation,
              color: CupertinoColors.activeBlue,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}