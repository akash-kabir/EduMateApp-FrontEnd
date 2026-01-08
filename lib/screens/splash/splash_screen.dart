import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main_page.dart';
import '../auth/getting_started_screen.dart';
import 'splash_progress_bar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
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
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => token != null && token.isNotEmpty
              ? const MainPage()
              : const GettingStartedScreen(),
        ),
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
            const Text(
              'EduMate',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 48),
            SplashProgressBar(animationController: _progressController),
          ],
        ),
      ),
    );
  }
}
