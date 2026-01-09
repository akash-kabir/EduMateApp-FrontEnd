import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../animated_background/animated_circle_gradient.dart';
import '../provider/animation_provider.dart';

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
        // Animated background circles using provider's controller
        AnimatedCircleGradient(
          primaryColor: Colors.purple,
          secondaryColor: Colors.blue,
          externalController: animationProvider.backgroundCircleController,
        ),
        // Content
        child,
      ],
    );
  }
}
