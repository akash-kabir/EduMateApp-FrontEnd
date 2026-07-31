import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:app/features/auth_and_profile/screens/auth/signup_screen2.dart';
import 'package:app/features/auth_and_profile/screens/auth/login_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/cupertino.dart';
import 'package:app/features/auth_and_profile/widgets/auth_background_wrapper.dart';
import 'package:app/theme/theme.dart';

import 'package:app/shared/widgets/dialogs/toast_manager.dart';

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
                              cursorColor: AuthPalette.coral,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                labelStyle: TextStyle(
                                  color: _isFirstNameError
                                      ? CupertinoColors.systemRed
                                      : AuthPalette.coral,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _isFirstNameError
                                        ? CupertinoColors.systemRed
                                        : AuthPalette.coral.withValues(alpha: 0.3),
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _isFirstNameError
                                        ? CupertinoColors.systemRed
                                        : AuthPalette.coral,
                                    width: 2,
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
                              cursorColor: AuthPalette.coral,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                labelStyle: TextStyle(
                                  color: _isLastNameError
                                      ? CupertinoColors.systemRed
                                      : AuthPalette.coral,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _isLastNameError
                                        ? CupertinoColors.systemRed
                                        : AuthPalette.coral.withValues(alpha: 0.3),
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _isLastNameError
                                        ? CupertinoColors.systemRed
                                        : AuthPalette.coral,
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: InkWell(
                              onTap: _goToNext,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: AuthPalette.coral.withValues(alpha: 0.22),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Next',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AuthPalette.coral,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: 'Login',
                                style: const TextStyle(
                                  color: AuthPalette.coral,
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
