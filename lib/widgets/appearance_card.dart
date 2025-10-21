import 'package:edumate/screens/menu/settings_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'theme_option.dart';

class AppearanceCard extends StatelessWidget {
  final bool followSystemTheme;
  final AppThemeMode selectedTheme;
  final ValueChanged<bool> onSystemThemeChanged;
  final ValueChanged<AppThemeMode> onThemeSelected;

  const AppearanceCard({
    super.key,
    required this.followSystemTheme,
    required this.selectedTheme,
    required this.onSystemThemeChanged,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Appearance",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.activeBlue,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 2, thickness: 1, color: Colors.white24),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Follow System Theme",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                CupertinoSwitch(
                  value: followSystemTheme,
                  activeColor: CupertinoColors.activeBlue,
                  onChanged: onSystemThemeChanged,
                ),
              ],
            ),
            if (!followSystemTheme) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ThemeOption(
                    mode: AppThemeMode.light,
                    selectedTheme: selectedTheme,
                    imagePath: "assets/github.png",
                    label: "Light",
                    onSelected: onThemeSelected,
                  ),
                  ThemeOption(
                    mode: AppThemeMode.dark,
                    selectedTheme: selectedTheme,
                    imagePath: "assets/github.png",
                    label: "Dark",
                    onSelected: onThemeSelected,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
