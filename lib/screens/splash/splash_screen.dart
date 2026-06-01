import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/shared_preferences_service.dart';
import '../../main_page.dart';
import '../auth/getting_started_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait a moment for smooth transition
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      final token = await SharedPreferencesService.getToken();

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
      backgroundColor: UserColors.background,
      body: Center(
        child: const Text(
          'EduMate',
          style: TextStyle(
            fontFamily: 'Salena',
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
