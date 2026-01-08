import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'signup_screen1.dart';
import '../../main_page.dart';
import '../../config.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/cupertino.dart';
import '../../animated_background/animated_circle_gradient.dart';
import '../../provider/animation_provider.dart';

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final url = Uri.parse('${Config.BASE_URL}/api/users/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usernameOrEmail': usernameOrEmail,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final user = data['user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('userFirstName', user['firstName']);
        await prefs.setString('userLastName', user['lastName']);
        await prefs.setString('userName', user['username']);
        await prefs.setString('userEmail', user['email']);
        await prefs.setString('userRole', user['role']);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainPage()),
          );
        }
      } else {
        final error = jsonDecode(response.body)['message'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final animationProvider = Provider.of<AnimationProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Animated background circles using provider's controller
          AnimatedCircleGradient(
            primaryColor: Colors.purple,
            secondaryColor: Colors.blue,
            externalController: animationProvider.backgroundCircleController,
          ),
          // Content
          SafeArea(
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
                                        : Colors.grey,
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _isLoginError
                                          ? CupertinoColors.systemRed
                                          : Colors.grey,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _isLoginError
                                          ? CupertinoColors.systemRed
                                          : Colors.blue,
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
                                        : Colors.grey,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: _isPasswordError
                                          ? CupertinoColors.systemRed
                                          : Colors.grey,
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
                                          : Colors.grey,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _isPasswordError
                                          ? CupertinoColors.systemRed
                                          : Colors.blue,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          _loading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: _loginUser,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 48,
                                      vertical: 12,
                                    ),
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
                                    color: CupertinoColors.activeGreen,
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
        ],
      ),
    );
  }
}
