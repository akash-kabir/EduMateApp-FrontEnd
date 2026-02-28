import 'package:flutter/material.dart';

class AnimatedCircleGradient extends StatefulWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final double primaryOpacityStart;
  final double primaryOpacityEnd;
  final double secondaryOpacityStart;
  final double secondaryOpacityEnd;
  final AnimationController? externalController;

  const AnimatedCircleGradient({
    super.key,
    this.primaryColor = Colors.purple,
    this.secondaryColor = Colors.blue,
    this.primaryOpacityStart = 0.3,
    this.primaryOpacityEnd = 0.8,
    this.secondaryOpacityStart = 0.2,
    this.secondaryOpacityEnd = 0.56,
    this.externalController,
  });

  @override
  State<AnimatedCircleGradient> createState() => _AnimatedCircleGradientState();
}

class _AnimatedCircleGradientState extends State<AnimatedCircleGradient>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Use external controller if provided, otherwise create internal one
    if (widget.externalController != null) {
      _pulseController = widget.externalController!;
    } else {
      _pulseController = AnimationController(
        duration: const Duration(seconds: 5),
        vsync: this,
      )..repeat(reverse: true);
    }

    _pulseAnimation =
        Tween<double>(
          begin: widget.primaryOpacityStart,
          end: widget.primaryOpacityEnd,
        ).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    // Only dispose if we created the controller internally
    if (widget.externalController == null) {
      _pulseController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-left purple gradient circle with pulse
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      widget.primaryColor.withValues(
                        alpha: _pulseAnimation.value,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Bottom-right blue gradient circle with pulse
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      widget.secondaryColor.withOpacity(
                        _pulseAnimation.value * 0.7,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
