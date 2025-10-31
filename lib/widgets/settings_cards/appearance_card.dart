import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../screens/settings_screen.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Appearance",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Divider(
              height: 2,
              thickness: 1,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Follow System Theme",
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                CupertinoSwitch(
                  value: followSystemTheme,
                  activeTrackColor: CupertinoColors.activeGreen,
                  onChanged: onSystemThemeChanged,
                ),
              ],
            ),
            if (!followSystemTheme) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ThemeOption(
                    mode: AppThemeMode.light,
                    selectedTheme: selectedTheme,
                    label: "Light",
                    onSelected: onThemeSelected,
                  ),
                  ThemeOption(
                    mode: AppThemeMode.dark,
                    selectedTheme: selectedTheme,
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
