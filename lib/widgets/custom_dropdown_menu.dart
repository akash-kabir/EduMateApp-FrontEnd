import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/menu/settings_screen.dart';
import '../screens/menu/about_screen.dart';

class CustomDropdownMenu extends StatelessWidget {
  final AnimationController menuItemsController;
  final VoidCallback onClose;

  const CustomDropdownMenu({
    super.key,
    required this.menuItemsController,
    required this.onClose,
  });

  Route _createSlideUpRoute(Widget screen) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0); 
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        final opacityTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn));

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation.drive(opacityTween),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 15, 15, 15).withOpacity(0.85),
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
                  title: const Text(
                    'Settings',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  onTap: () {
                    onClose();
                    Navigator.push(
                      context,
                      _createSlideUpRoute(const SettingsScreen()),
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
                  title: const Text(
                    'About',
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
    );
  }
}
