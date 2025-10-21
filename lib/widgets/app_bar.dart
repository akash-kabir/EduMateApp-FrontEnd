import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.8),
      elevation: 0,
      titleSpacing: 16,
      title: const Text(
        'EduMate',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: AnimatedBuilder(
            animation: arrowAnimation,
            builder: (context, child) {
              final curvedValue = CurvedAnimation(
                parent: arrowAnimation,
                curve: Curves.easeInOut,
              ).value;

              return IconButton(
                onPressed: onMenuPressed,
                icon: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(pi * curvedValue),
                  child: const Icon(
                    CupertinoIcons.chevron_down,
                    color: CupertinoColors.activeBlue,
                    size: 24,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
