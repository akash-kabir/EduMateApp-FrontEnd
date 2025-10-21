import 'package:edumate/screens/menu/settings_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class ThemeOption extends StatelessWidget {
  final AppThemeMode mode;
  final AppThemeMode selectedTheme;
  final String imagePath;
  final String label;
  final ValueChanged<AppThemeMode> onSelected;

  const ThemeOption({
    super.key,
    required this.mode,
    required this.selectedTheme,
    required this.imagePath,
    required this.label,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = mode == selectedTheme;

    return Column(
      children: [
        
        Image.asset(imagePath, width: 80, height: 80),
        const SizedBox(height: 6),
       
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14, 
            fontWeight: FontWeight.normal, 
          ),
        ),
        const SizedBox(height: 6),
        
        Radio<AppThemeMode>(
          value: mode,
          groupValue: selectedTheme,
          activeColor: CupertinoColors.activeBlue,
          onChanged: (AppThemeMode? value) {
            if (value != null) {
              onSelected(value);
            }
          },
        ),
      ],
    );
  }
}
