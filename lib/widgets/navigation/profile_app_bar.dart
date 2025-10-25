import 'package:flutter/material.dart';
import '../../theme/theme_provider.dart';
import '../../screens/menu/settings_screen.dart';

class ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ThemeProvider themeProvider;
  final String username;

  const ProfileAppBar({
    super.key,
    required this.themeProvider,
    required this.username,
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

    return AppBar(
      backgroundColor: isDark ? Colors.black : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.edit, color: Colors.blue), 
        onPressed: () {
          
        },
      ),
      title: Text(
        '@$username',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.settings, color: isDark ? Colors.white : Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              _createSlideUpRoute(SettingsScreen(themeProvider: themeProvider)),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
