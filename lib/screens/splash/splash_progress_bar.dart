import 'package:flutter/material.dart';

class SplashProgressBar extends StatelessWidget {
  final AnimationController animationController;

  const SplashProgressBar({super.key, required this.animationController});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return LinearProgressIndicator(
            value: animationController.value,
            backgroundColor: Colors.grey[800],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 4,
          );
        },
      ),
    );
  }
}
