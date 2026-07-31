import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/animated_background/animated_circle_gradient.dart';
import 'package:app/shared/provider/animation_provider.dart';
import 'package:app/theme/theme.dart';

/// Wrapper widget that provides animated background with content overlay
/// Used consistently across all authentication screens
class AuthBackgroundWrapper extends StatelessWidget {
  final Widget child;

  const AuthBackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final animationProvider = Provider.of<AnimationProvider>(context);

    return Stack(
      children: [
        // Solid Pitch Black Background
        Container(color: Colors.black),
        // Animated background circles using provider's controller
        AnimatedCircleGradient(
          primaryColor: AuthPalette.coral,
          secondaryColor: AuthPalette.coral.withValues(alpha: 0.4),
          primaryOpacityStart: 0.15,
          primaryOpacityEnd: 0.35,
          secondaryOpacityStart: 0.1,
          secondaryOpacityEnd: 0.25,
          externalController: animationProvider.backgroundCircleController,
        ),
        // Content
        child,
      ],
    );
  }
}
