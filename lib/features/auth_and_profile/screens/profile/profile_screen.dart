import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Profile'),
        backgroundColor: isDark
            ? CupertinoColors.black.withOpacity(0.6)
            : CupertinoColors.white.withOpacity(0.6),
      ),
      child: const Center(child: Text('Profile Screen')),
    );
  }
}
