import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'signup_screen1.dart';

class GettingStartedScreen extends StatelessWidget {
  const GettingStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const buttonWidth = 220.0; 

    return Scaffold(
      backgroundColor: Colors.black, 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to EduMate',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Your personal campus companion to stay updated with events, schedules, and campus life.',
                style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: buttonWidth,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen1()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: CupertinoColors.activeBlue,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Get Started'),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: buttonWidth,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.white,
                    foregroundColor: CupertinoColors.systemRed,
                    textStyle: const TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Exit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
