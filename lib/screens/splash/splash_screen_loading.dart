import 'package:flutter/material.dart';
import '../../main_page.dart';
import 'components/splash_progress_bar.dart';

class SplashScreenWithApiLoading extends StatefulWidget {
  const SplashScreenWithApiLoading({super.key});

  @override
  State<SplashScreenWithApiLoading> createState() =>
      _SplashScreenWithApiLoadingState();
}

class _SplashScreenWithApiLoadingState
    extends State<SplashScreenWithApiLoading> {
  double _progress = 0.0;

  void _handleProgressUpdate(double newProgress) {
    setState(() {
      _progress = newProgress;
    });
  }

  void _handleLoadingComplete() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainPage()),
    );
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
            const SizedBox(height: 16),
            // Progress bar with API loading logic
            SplashProgressBar(
              onProgressUpdate: _handleProgressUpdate,
              onLoadingComplete: _handleLoadingComplete,
            ),
            const SizedBox(height: 12),
            // Progress text
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
