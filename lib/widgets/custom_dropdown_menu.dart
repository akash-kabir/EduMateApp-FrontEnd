import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import '../screens/menu/settings_screen.dart';
import '../screens/menu/about_screen.dart';

class CustomDropdownMenu extends StatelessWidget {
  final AnimationController menuItemsController;
  final VoidCallback onClose;
  final ThemeProvider themeProvider;

  const CustomDropdownMenu({
    super.key,
    required this.menuItemsController,
    required this.onClose,
    required this.themeProvider,
  });

  Route _createSlideUpRoute(Widget screen) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation =
            Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        final opacityAnimation = Tween<double>(
          begin: 0,
          end: 1,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: opacityAnimation, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: menuItemsController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF0F0F0F) : Colors.grey[200])!
                  .withOpacity(0.95),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: menuItemsController,
                    curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.only(left: 40, right: 20),
                    title: Text(
                      'Settings',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 20,
                      ),
                    ),
                    onTap: () {
                      onClose();
                      Navigator.push(
                        context,
                        _createSlideUpRoute(
                          SettingsScreen(themeProvider: themeProvider),
                        ),
                      );
                    },
                  ),
                ),
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: menuItemsController,
                    curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.only(left: 40, right: 20),
                    title: Text(
                      'About',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 20,
                      ),
                    ),
                    onTap: () {
                      onClose();
                      Navigator.push(
                        context,
                        _createSlideUpRoute(const AboutScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
