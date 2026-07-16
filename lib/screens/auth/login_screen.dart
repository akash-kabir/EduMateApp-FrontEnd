import 'package:flutter/material.dart';
import 'signup_screen1.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/cupertino.dart';
import '../../widgets/auth_background_wrapper.dart';
import '../splash/splash_screen_loading.dart';
import '../../services/api_service.dart';
import '../../services/shared_preferences_service.dart';
import '../../constants/app_constants.dart';
import '../../widgets/toast_manager.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;

  late AnimationController _animationController;
  bool _isLoginError = false;
  bool _isPasswordError = false;

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
              _isLoginError = false;
              _isPasswordError = false;
            });
          }
        });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    final usernameOrEmail = _loginController.text.trim();
    final password = _passwordController.text.trim();

    if (usernameOrEmail.isEmpty || password.isEmpty) {
      setState(() {
        _isLoginError = usernameOrEmail.isEmpty;
        _isPasswordError = password.isEmpty;
      });
      _animationController.forward(from: 0);

      String message = '';
      if (usernameOrEmail.isEmpty && password.isEmpty) {
        message = 'Please fill all fields';
      } else if (usernameOrEmail.isEmpty) {
        message = 'Please fill the username or email';
      } else if (password.isEmpty) {
        message = 'Please fill the password';
      }

      EduMateToast.showCompact(
        context,
        message: message,
        isSuccess: false,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await ApiService.login(
        usernameOrEmail: usernameOrEmail,
        password: password,
      );

      if (result['success'] ?? false) {
        final data = result['data'];
        final token = data['token'];
        final refreshToken = data['refreshToken'];
        final user = data['user'];

        // Save token and login state
        await SharedPreferencesService.setToken(token);
        if (refreshToken != null) {
          await SharedPreferencesService.setRefreshToken(refreshToken);
        }
        await SharedPreferencesService.setIsLoggedIn(true);

        // Save full user profile to SharedPreferences
        await SharedPreferencesService.saveFullUserProfile(user);

        // If profile is completed, also save branch as selectedBranch for timesheet
        if (user['isProfileCompleted'] == true && user['branch'] != null) {
          await SharedPreferencesService.setString(
            'selectedBranch',
            user['branch'],
          );
          if (user['section'] != null) {
            await SharedPreferencesService.setString(
              'selectedClass',
              user['section'],
            );
            await SharedPreferencesService.setBool('savePreference', true);
          }
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const SplashScreenWithApiLoading(),
            ),
          );
        }
      } else {
        if (mounted) {
          EduMateToast.showCompact(
            context,
            message: result['message'] ?? 'Login failed',
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(
          context,
          message: 'Error: $e',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: AuthBackgroundWrapper(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 200),
                  const Text(
                    'Welcome Back',
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
                              controller: _loginController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Username or Email',
                                labelStyle: TextStyle(
                                  color: _isLoginError
                                      ? CupertinoColors.systemRed
                                      : AuthPalette.blush,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _isLoginError
                                        ? CupertinoColors.systemRed
                                        : AuthPalette.coral.withOpacity(0.55),
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _isLoginError
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
                              controller: _passwordController,
                              obscureText: !_showPassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(
                                  color: _isPasswordError
                                      ? CupertinoColors.systemRed
                                      : AuthPalette.blush,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: _isPasswordError
                                        ? CupertinoColors.systemRed
                                        : AuthPalette.coral,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showPassword = !_showPassword;
                                    });
                                  },
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _isPasswordError
                                        ? CupertinoColors.systemRed
                                        : AuthPalette.coral.withOpacity(0.55),
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _isPasswordError
                                        ? CupertinoColors.systemRed
                                        : AuthPalette.blush,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                              );
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AuthPalette.blush,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _loading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AuthPalette.deepTeal,
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _loginUser,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 48,
                                    vertical: 12,
                                  ),
                                  backgroundColor: AuthPalette.deepTeal,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Login'),
                              ),
                        const SizedBox(height: 16),
                        RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign Up',
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
