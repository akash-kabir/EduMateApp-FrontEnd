import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/getting_started_screen.dart';
import '../../../services/api_service.dart';
import '../admin_main_app.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;

  late AnimationController _animationController;
  bool _isUsernameError = false;
  bool _isPasswordError = false;
  bool _isLoading = false;

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
              _isUsernameError = false;
              _isPasswordError = false;
            });
          }
        });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginAdmin() async {
    final usernameOrEmail = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (usernameOrEmail.isEmpty || password.isEmpty) {
      setState(() {
        _isUsernameError = usernameOrEmail.isEmpty;
        _isPasswordError = password.isEmpty;
      });
      _animationController.forward(from: 0);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.login(
        usernameOrEmail: usernameOrEmail,
        password: password,
      );

      if (result['success'] ?? false) {
        final user = result['data']['user'];
        final role = user['role'];

        // Check if user is society_head
        if (role == 'society_head') {
          final token = result['data']['token'];
          final prefs = await SharedPreferences.getInstance();

          // Save admin credentials (use 'authToken' to match upload screen)
          await prefs.setString('authToken', token);
          await prefs.setString(
            'token',
            token,
          ); // Keep for backward compatibility
          await prefs.setString('userId', user['id'] ?? user['_id'] ?? '');
          await prefs.setString('userRole', role);
          await prefs.setString('userName', user['username']);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminMainApp()),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Access Denied: Only society heads can login as admin',
                ),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Login failed'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 100,
                      color: Color(0xFFFF1744),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Edumate',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF1744),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFF1744), Color(0xFFFF6B35)],
                          ).createShader(bounds),
                          child: const Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                Center(
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return TextField(
                            controller: _usernameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Username or Email',
                              labelStyle: TextStyle(
                                color: _isUsernameError
                                    ? CupertinoColors.systemRed
                                    : Colors.grey,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: _isUsernameError
                                      ? CupertinoColors.systemRed
                                      : Colors.grey,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: _isUsernameError
                                      ? CupertinoColors.systemRed
                                      : const Color(0xFFFF1744),
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
                                      : const Color(0xFFFF1744),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _loginAdmin,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 12,
                          ),
                          backgroundColor: const Color(0xFFFF1744),
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Login'),
                      ),
                      const SizedBox(height: 24),
                      RichText(
                        text: TextSpan(
                          text: 'Lost? ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          children: [
                            TextSpan(
                              text: 'Back to Getting Started',
                              style: const TextStyle(
                                color: Color(0xFFFF1744),
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const GettingStartedScreen(),
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
    );
  }
}
