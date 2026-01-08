import 'package:flutter/material.dart';
import '../admin_auth/admin_login_screen.dart';

class AdminSplashScreen extends StatefulWidget {
  const AdminSplashScreen({super.key});

  @override
  State<AdminSplashScreen> createState() => _AdminSplashScreenState();
}

class _AdminSplashScreenState extends State<AdminSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _progressController.forward();
    _navigateToAdminLogin();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _navigateToAdminLogin() async {
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'EduMate ',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: 'ADMIN',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF1744), // Vibrant red
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 200,
              child: CustomSplashProgressBar(
                animationController: _progressController,
                color: const Color(0xFFFF1744), // Vibrant red
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom progress bar widget for red color
class CustomSplashProgressBar extends StatefulWidget {
  final AnimationController animationController;
  final Color color;

  const CustomSplashProgressBar({
    super.key,
    required this.animationController,
    required this.color,
  });

  @override
  State<CustomSplashProgressBar> createState() =>
      _CustomSplashProgressBarState();
}

class _CustomSplashProgressBarState extends State<CustomSplashProgressBar> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return LinearProgressIndicator(
          value: widget.animationController.value,
          backgroundColor: Colors.grey[800],
          valueColor: AlwaysStoppedAnimation<Color>(widget.color),
          minHeight: 6,
        );
      },
    );
  }
}
