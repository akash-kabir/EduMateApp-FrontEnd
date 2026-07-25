import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MapActionButtons extends StatelessWidget {
  final bool isFullScreenSearch;
  final bool isMapMenuExpanded;
  final bool is3DMode;
  final bool isDark;
  final VoidCallback onToggleMenu;
  final VoidCallback onRecenter;
  final VoidCallback onCompass;
  final VoidCallback onToggle3D;

  const MapActionButtons({
    super.key,
    required this.isFullScreenSearch,
    required this.isMapMenuExpanded,
    required this.is3DMode,
    required this.isDark,
    required this.onToggleMenu,
    required this.onRecenter,
    required this.onCompass,
    required this.onToggle3D,
  });

  @override
  Widget build(BuildContext context) {
    if (isFullScreenSearch) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: isMapMenuExpanded
            ? Row(
                key: const ValueKey('expanded_row'),
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.3),
                          ),
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: onRecenter,
                            child: Icon(
                              CupertinoIcons.location_fill,
                              color: isDark ? Colors.white : Colors.black,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.3),
                          ),
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: onCompass,
                            child: Icon(
                              CupertinoIcons.compass,
                              color: isDark ? Colors.white : Colors.black,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.3),
                          ),
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: onToggle3D,
                            child: Icon(
                              is3DMode ? CupertinoIcons.view_2d : CupertinoIcons.view_3d,
                              color: isDark ? Colors.white : Colors.black,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Align(
                key: const ValueKey('collapsed_circle'),
                alignment: Alignment.centerRight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.3),
                      ),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: onToggleMenu,
                        child: Icon(
                          CupertinoIcons.slider_horizontal_3,
                          color: isDark ? Colors.white : Colors.black,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
