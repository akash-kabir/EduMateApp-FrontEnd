import 'package:flutter/material.dart';

class AnimationProvider extends ChangeNotifier {
  late AnimationController _backgroundCircleController;
  late AnimationController _pageEntranceController;
  late AnimationController _textRevealController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _revealAnimation;

  // Getters
  AnimationController get backgroundCircleController =>
      _backgroundCircleController;

  AnimationController get pageEntranceController => _pageEntranceController;

  AnimationController get textRevealController => _textRevealController;

  Animation<double> get fadeAnimation => _fadeAnimation;

  Animation<double> get scaleAnimation => _scaleAnimation;

  Animation<double> get revealAnimation => _revealAnimation;

  AnimationProvider(TickerProvider vsync) {
    _initializeBackgroundCircleAnimation(vsync);
    _initializePageEntranceAnimations(vsync);
  }

  void _initializeBackgroundCircleAnimation(TickerProvider vsync) {
    _backgroundCircleController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: vsync,
    );

    // Start the infinite animation loop
    _backgroundCircleController.repeat(reverse: true);
  }

  void _initializePageEntranceAnimations(TickerProvider vsync) {
    // Page entrance animation (scale + fade)
    _pageEntranceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: vsync,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageEntranceController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _pageEntranceController, curve: Curves.easeOut),
    );

    // Text reveal animation
    _textRevealController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: vsync,
    );

    _revealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textRevealController, curve: Curves.easeInOut),
    );
  }

  /// Start page entrance animations
  void startPageEntranceAnimations() {
    _pageEntranceController.forward(from: 0.0);
    _textRevealController.forward(from: 0.0);
  }

  /// Reset page entrance animations
  void resetPageEntranceAnimations() {
    _pageEntranceController.reset();
    _textRevealController.reset();
  }

  /// Update the ticker provider (needed when navigator changes)
  void updateTickerProvider(TickerProvider vsync) {
    _backgroundCircleController.dispose();
    _pageEntranceController.dispose();
    _textRevealController.dispose();
    _initializeBackgroundCircleAnimation(vsync);
    _initializePageEntranceAnimations(vsync);
  }

  @override
  void dispose() {
    _backgroundCircleController.dispose();
    _pageEntranceController.dispose();
    _textRevealController.dispose();
    super.dispose();
  }
}
