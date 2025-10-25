import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../widgets/navigation/app_bar.dart';
import '../widgets/menu/custom_dropdown_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isMenuOpen = false;
  late AnimationController _arrowController;
  late AnimationController _menuItemsController;
  late AnimationController _blurController;

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _menuItemsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _blurController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _arrowController.dispose();
    _menuItemsController.dispose();
    _blurController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (!_isMenuOpen) {
      setState(() => _isMenuOpen = true);
      _arrowController.forward();
      _blurController.forward();
      _menuItemsController.forward(from: 0.0);
    } else {
      _arrowController.reverse();
      _blurController.reverse();
      _menuItemsController.reverse().then((_) {
        if (mounted) setState(() => _isMenuOpen = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [

          Center(
            child: Text(
              'Home',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          
          if (_isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMenu,
                child: AnimatedBuilder(
                  animation: _blurController,
                  builder: (context, child) {
                    return BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 8 * _blurController.value,
                        sigmaY: 8 * _blurController.value,
                      ),
                      child: Container(
                        color: (isDark ? Colors.black : Colors.white).withOpacity(
                          0.4 * _blurController.value,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBarWidget(
                onMenuPressed: _toggleMenu,
                arrowAnimation: _arrowController,
              ),
              if (_isMenuOpen)
                CustomDropdownMenu(
                  menuItemsController: _menuItemsController,
                  onClose: _toggleMenu,
                  themeProvider: themeProvider,
                ),
            ],
          ),
        ],
      ),
    );
  }
}