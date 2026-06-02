import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class SuccessCardWidget extends StatefulWidget {
  final String title;
  final String? description;
  final VoidCallback onDismiss;

  const SuccessCardWidget({
    super.key,
    required this.title,
    this.description,
    required this.onDismiss,
  });

  @override
  State<SuccessCardWidget> createState() => _SuccessCardWidgetState();
}

class _SuccessCardWidgetState extends State<SuccessCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  late AnimationController _iconController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconRotateAnimation;

  bool _showGlow = false;

  @override
  void initState() {
    super.initState();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: Curves.easeOut,
      ),
    );

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Curves.bounceOut,
      ),
    );

    _iconRotateAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Curves.easeOut,
      ),
    );

    // Trigger card entrance
    _cardController.forward();

    // Trigger icon entrance & radial glow with a slight delay
    Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        _iconController.forward();
        setState(() {
          _showGlow = true;
        });
      }
    });

    // Auto-dismiss timeline
    Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        setState(() {
          _showGlow = false;
        });
        _cardController.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 600 ? 320.0 : screenWidth * 0.75;

    return Stack(
      children: [
        // Dimmed backdrop
        AnimatedBuilder(
          animation: _cardController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value * 0.5,
              child: Container(
                color: Colors.black,
              ),
            );
          },
        ),
        // Center content card
        Center(
          child: AnimatedBuilder(
            animation: _cardController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: cardWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.0),
                      boxShadow: [
                        BoxShadow(
                          color: _showGlow 
                              ? const Color(0xFF10B981).withOpacity(0.08) 
                              : Colors.transparent,
                          blurRadius: 40.0,
                          spreadRadius: 10.0,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 30.0,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24.0),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 28.0, sigmaY: 28.0),
                        child: Material(
                          type: MaterialType.transparency,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 32.0,
                              horizontal: 24.0,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F0F11).withOpacity(0.45), // Premium high translucency (45% opacity)
                              borderRadius: BorderRadius.circular(24.0),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Animated large Emerald checkmark icon
                                AnimatedBuilder(
                                  animation: _iconController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _iconScaleAnimation.value,
                                      child: Transform.rotate(
                                        angle: _iconRotateAnimation.value,
                                        child: Container(
                                          width: 72.0,
                                          height: 72.0,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFF10B981).withOpacity(0.12),
                                            border: Border.all(
                                              color: const Color(0xFF10B981).withOpacity(0.3),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.check_rounded,
                                            color: Color(0xFF10B981),
                                            size: 40.0,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24.0),
                                // Title Text
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (widget.description != null) ...[
                                  const SizedBox(height: 8.0),
                                  // Subtitle / Description Text
                                  Text(
                                    widget.description!,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.normal,
                                      color: Color(0xFFA1A1AA), // Secondary grey/charcoal
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
