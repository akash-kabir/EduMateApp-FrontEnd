import 'package:flutter/material.dart';
import 'signup_screen2.dart';
import 'login_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/cupertino.dart';
import '../../widgets/auth_background_wrapper.dart';
import '../../constants/app_constants.dart';

import '../../widgets/toast_manager.dart';

class SignupScreen1 extends StatefulWidget {
  const SignupScreen1({super.key});

  @override
  State<SignupScreen1> createState() => _SignupScreen1State();
}

class _SignupScreen1State extends State<SignupScreen1>
    with SingleTickerProviderStateMixin {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  late AnimationController _animationController;
  bool _isFirstNameError = false;
  bool _isLastNameError = false;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(
          duration: const Duration(milliseconds: 400),
          vsync: this,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _animationController.reverse();
          } else if (status == AnimationStatus.dismissed) {
            setState(() {
              _isFirstNameError = false;
              _isLastNameError = false;
            });
          }
        });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _goToNext() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isEmpty && lastName.isEmpty) {
      setState(() {
        _isFirstNameError = true;
        _isLastNameError = true;
      });
      _animationController.forward(from: 0);
      EduMateToast.showCompact(
        context,
        message: 'Please fill both first and last name',
        isSuccess: false,
      );
      return;
    }

    if (firstName.isEmpty) {
      setState(() {
        _isFirstNameError = true;
        _isLastNameError = false;
      });
      _animationController.forward(from: 0);
      EduMateToast.showCompact(
        context,
        message: 'Please fill the first name',
        isSuccess: false,
      );
      return;
    }

    if (lastName.isEmpty) {
      setState(() {
        _isFirstNameError = false;
        _isLastNameError = true;
      });
      _animationController.forward(from: 0);
      EduMateToast.showCompact(
        context,
        message: 'Please fill the last name',
        isSuccess: false,
      );
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SignupScreen2(firstName: firstName, lastName: lastName),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: AuthBackgroundWrapper(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 200),
                  const Text(
                    'May I know your name?',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return TextField(
                              controller: _firstNameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                labelStyle: TextStyle(
                                  color: _isFirstNameError
                                      ? CupertinoColors.systemRed
                                      : AuthPalette.blush,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _isFirstNameError
                                        ? CupertinoColors.systemRed
                                        : AuthPalette.coral.withOpacity(0.55),
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _isFirstNameError
                                        ? CupertinoColors.systemRed
                                        : AuthPalette.blush,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return TextField(
                              controller: _lastNameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                labelStyle: TextStyle(
                                  color: _isLastNameError
                                      ? CupertinoColors.systemRed
                                      : AuthPalette.blush,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _isLastNameError
                                        ? CupertinoColors.systemRed
                                        : AuthPalette.coral.withOpacity(0.55),
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _isLastNameError
                                        ? CupertinoColors.systemRed
                                        : AuthPalette.blush,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _goToNext,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 12,
                            ),
                            backgroundColor: AuthPalette.deepTeal,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Next'),
                        ),
                        const SizedBox(height: 16),
                        RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            children: [
                              TextSpan(
                                text: 'Login',
                                style: const TextStyle(
                                  color: AuthPalette.blush,
                                  fontWeight: FontWeight.bold,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushReplacement(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                            ) => const LoginScreen(),
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
                                      ),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
