import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../screens/menu/settings_screen.dart';

class ThemeOption extends StatelessWidget {
  final AppThemeMode mode;
  final AppThemeMode selectedTheme;
  final String label;
  final ValueChanged<AppThemeMode> onSelected;

  const ThemeOption({
    super.key,
    required this.mode,
    required this.selectedTheme,
    required this.label,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = mode == selectedTheme;

    return GestureDetector(
      onTap: () => onSelected(mode),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? CupertinoColors.activeBlue : Colors.white24,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: _buildThemePreview(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: selected
                  ? CupertinoColors
                        .activeBlue // active color
                  : (Theme.of(context).brightness == Brightness.light
                        ? Colors
                              .black // inactive in light mode
                        : Colors.grey), // inactive in dark mode
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),

          const SizedBox(height: 6),
          Radio<AppThemeMode>(
            value: mode,
            groupValue: selectedTheme,
            activeColor: CupertinoColors.activeBlue,
            onChanged: (AppThemeMode? value) {
              if (value != null) onSelected(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemePreview() {
    final bool isLight = mode == AppThemeMode.light;

    return Container(
      color: isLight ? Colors.white : Colors.black,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: isLight ? Colors.grey[200] : const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const SizedBox(width: 6),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isLight ? Colors.black54 : Colors.white54,
                    shape: BoxShape.circle,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isLight ? Colors.black54 : Colors.white54,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isLight ? Colors.grey[100] : const Color(0xFF0F0F0F),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isLight ? Colors.grey[300] : Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 40,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isLight ? Colors.grey[300] : Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isLight ? Colors.grey[300] : Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 50,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isLight ? Colors.grey[300] : Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 16,
            decoration: BoxDecoration(
              color: isLight ? Colors.grey[200] : const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                5,
                (index) => Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: index == 0
                        ? CupertinoColors.activeBlue
                        : (isLight ? Colors.black38 : Colors.white38),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
