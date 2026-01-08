import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'signup_screen1.dart';
import '../admin/adminsplash/admin_splash_screen.dart';
import '../../animated_background/animated_circle_gradient.dart';
import '../../provider/animation_provider.dart';

class GettingStartedScreen extends StatefulWidget {
  const GettingStartedScreen({super.key});

  @override
  State<GettingStartedScreen> createState() => _GettingStartedScreenState();
}

class _GettingStartedScreenState extends State<GettingStartedScreen> {
  @override
  void initState() {
    super.initState();
    // Start animations from provider after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<AnimationProvider>(context, listen: false);
        provider.startPageEntranceAnimations();
      }
    });
  }

  void _showExitConfirmationDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Exit App'),
          content: const Text('Are you sure you want to exit?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                exit(0);
              },
              isDestructiveAction: true,
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final animationProvider = Provider.of<AnimationProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: SizedBox(
          height: screenHeight,
          child: Stack(
            children: [
              // Animated background circles using provider's controller
              AnimatedCircleGradient(
                primaryColor: Colors.purple,
                secondaryColor: Colors.blue,
                externalController:
                    animationProvider.backgroundCircleController,
              ),
              // Main Content with SafeArea
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Top Icon and Content
                      ScaleTransition(
                        scale: animationProvider.scaleAnimation,
                        child: FadeTransition(
                          opacity: animationProvider.fadeAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Main Heading with Animated EduMate Text
                              RichText(
                                textAlign: TextAlign.left,
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Welcome to\n',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.2,
                                      ),
                                    ),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: AnimatedBuilder(
                                        animation:
                                            animationProvider.revealAnimation,
                                        builder: (context, child) {
                                          return ClipRect(
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              widthFactor: animationProvider
                                                  .revealAnimation
                                                  .value,
                                              child: Text(
                                                'EduMate',
                                                style: TextStyle(
                                                  fontSize: 68,
                                                  fontWeight: FontWeight.bold,
                                                  foreground: Paint()
                                                    ..shader =
                                                        LinearGradient(
                                                          begin: Alignment
                                                              .centerLeft,
                                                          end: Alignment
                                                              .centerRight,
                                                          colors: [
                                                            Colors.blue,
                                                            Colors.purple,
                                                          ],
                                                        ).createShader(
                                                          const Rect.fromLTWH(
                                                            0,
                                                            0,
                                                            300,
                                                            100,
                                                          ),
                                                        ),
                                                  height: 1.2,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Subtitle
                              Text(
                                'Your personal campus companion to stay updated with events, schedules, and campus life.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey[400],
                                  height: 1.6,
                                  letterSpacing: 0.2,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Buttons Section with Glass Effect
                      ScaleTransition(
                        scale: animationProvider.scaleAnimation,
                        child: FadeTransition(
                          opacity: animationProvider.fadeAnimation,
                          child: Column(
                            children: [
                              // Sign Up Button with Glass Effect
                              GlassButton(
                                text: 'Get Started',
                                isGradient: true,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                          ) => const SignupScreen1(),
                                      transitionsBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                          ) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                      transitionDuration: const Duration(
                                        milliseconds: 300,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              // Admin Login Button with Glass Effect
                              GlassButton(
                                text: 'Admin Login',
                                isGradient: false,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                          ) => const AdminSplashScreen(),
                                      transitionsBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                          ) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                      transitionDuration: const Duration(
                                        milliseconds: 300,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              // Sign In Button with Glass Effect
                              GlassButton(
                                text: 'Exit',
                                isGradient: false,
                                onPressed: () {
                                  _showExitConfirmationDialog(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassButton extends StatefulWidget {
  final String text;
  final bool isGradient;
  final VoidCallback onPressed;

  const GlassButton({
    super.key,
    required this.text,
    required this.isGradient,
    required this.onPressed,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: widget.isGradient
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          CupertinoColors.activeBlue.withOpacity(
                            _isHovered ? 0.9 : 0.7,
                          ),
                          CupertinoColors.activeBlue.withOpacity(
                            _isHovered ? 0.9 : 0.7,
                          ),
                        ],
                      )
                    : null,
                color: widget.isGradient
                    ? null
                    : Colors.white.withOpacity(_isHovered ? 0.15 : 0.1),
              ),
              child: Center(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: widget.isGradient ? Colors.white : Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
