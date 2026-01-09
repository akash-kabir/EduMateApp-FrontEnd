import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/cupertino.dart';
import '../../widgets/auth_background_wrapper.dart';
import '../../utils/validators.dart';
import '../../services/api_service.dart';
import '../splash/splash_screen_loading.dart';

class SignupScreen2 extends StatefulWidget {
  final String firstName;
  final String lastName;

  const SignupScreen2({
    super.key,
    required this.firstName,
    required this.lastName,
  });

  @override
  State<SignupScreen2> createState() => _SignupScreen2State();
}

class _SignupScreen2State extends State<SignupScreen2>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;
  bool _checkingUsername = false;
  bool _checkingEmail = false;
  bool _usernameAvailable = true;
  bool _emailAvailable = true;

  late AnimationController _animationController;
  bool _isUsernameError = false;
  bool _isEmailError = false;
  bool _isPasswordError = false;

  String _usernameErrorMsg = '';
  String _emailErrorMsg = '';
  String _passwordErrorMsg = '';

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
              _isEmailError = false;
              _isPasswordError = false;
            });
          }
        });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  double _getPasswordStrengthValue() {
    final strength = Validators.getPasswordStrength(_passwordController.text);
    switch (strength) {
      case 'Weak':
        return 0.33;
      case 'Medium':
        return 0.66;
      case 'Strong':
        return 1.0;
      default:
        return 0;
    }
  }

  bool _hasMinLength() => _passwordController.text.length >= 8;
  bool _hasUpperCase() => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool _hasLowerCase() => _passwordController.text.contains(RegExp(r'[a-z]'));
  bool _hasNumber() => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool _hasSpecialChar() =>
      _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  Widget _buildRequirementWidget(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.circle_outlined,
          size: 16,
          color: isMet ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isMet ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  Future<void> _checkUsernameAvailability(String username) async {
    String? usernameError = Validators.validateUsername(username);
    if (usernameError != null) {
      setState(() {
        _isUsernameError = true;
        _usernameErrorMsg = usernameError;
        _checkingUsername = false;
        _usernameAvailable = false;
      });
      return;
    }

    setState(() {
      _checkingUsername = true;
      _isUsernameError = false;
    });

    try {
      final result = await ApiService.checkUsernameAvailability(username);

      if (mounted) {
        setState(() {
          _checkingUsername = false;
          if (result['available'] == true) {
            _isUsernameError = false;
            _usernameErrorMsg = '';
            _usernameAvailable = true;
          } else {
            _isUsernameError = true;
            _usernameErrorMsg = result['message'] ?? 'Username already taken';
            _usernameAvailable = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingUsername = false;
          _isUsernameError = true;
          _usernameErrorMsg = 'Error checking username';
          _usernameAvailable = false;
        });
      }
    }
  }

  Future<void> _checkEmailAvailability(String email) async {
    String? basicError = Validators.validateEmail(email);
    if (basicError != null) {
      setState(() {
        _isEmailError = true;
        _emailErrorMsg = 'Please enter a valid email address';
        _checkingEmail = false;
        _emailAvailable = false;
      });
      return;
    }

    setState(() {
      _checkingEmail = true;
      _isEmailError = false;
    });

    try {
      final result = await ApiService.checkEmailAvailability(email);

      if (mounted) {
        setState(() {
          _checkingEmail = false;
          if (result['available'] == true) {
            _isEmailError = false;
            _emailErrorMsg = '';
            _emailAvailable = true;
          } else {
            _isEmailError = true;
            _emailErrorMsg = result['message'] ?? 'Email already registered';
            _emailAvailable = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingEmail = false;
          _isEmailError = true;
          _emailErrorMsg = 'Error checking email';
          _emailAvailable = false;
        });
      }
    }
  }

  Future<void> _signupUser() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool hasError = false;

    String? usernameError = Validators.validateUsername(username);
    if (usernameError != null) {
      setState(() {
        _isUsernameError = true;
        _usernameErrorMsg = usernameError;
      });
      hasError = true;
    } else if (!_usernameAvailable) {
      setState(() {
        _isUsernameError = true;
        _usernameErrorMsg = 'Username already taken';
      });
      hasError = true;
    } else {
      setState(() {
        _isUsernameError = false;
        _usernameErrorMsg = '';
      });
    }

    String? emailError = Validators.validateEmail(email);
    if (emailError != null) {
      setState(() {
        _isEmailError = true;
        _emailErrorMsg = emailError;
      });
      hasError = true;
    } else if (!_emailAvailable) {
      setState(() {
        _isEmailError = true;
        _emailErrorMsg = 'Email already registered';
      });
      hasError = true;
    } else {
      setState(() {
        _isEmailError = false;
        _emailErrorMsg = '';
      });
    }

    String? passwordError = Validators.validatePassword(password);
    if (passwordError != null) {
      setState(() {
        _isPasswordError = true;
        _passwordErrorMsg = passwordError;
      });
      hasError = true;
    } else {
      setState(() {
        _isPasswordError = false;
        _passwordErrorMsg = '';
      });
    }

    if (hasError) {
      _animationController.forward(from: 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the validation errors'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await ApiService.register(
        firstName: widget.firstName,
        lastName: widget.lastName,
        username: username,
        email: email,
        password: password,
      );

      if (result['success'] ?? false) {
        final data = result['data'];
        final token = data['token'];
        final user = data['user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('userId', user['id'] ?? user['_id'] ?? '');
        await prefs.setString('userFirstName', user['firstName']);
        await prefs.setString('userLastName', user['lastName']);
        await prefs.setString('userName', user['username']);
        await prefs.setString('userEmail', user['email']);
        await prefs.setString('userRole', user['role']);
        await prefs.setBool(
          'isProfileCompleted',
          user['isProfileCompleted'] ?? false,
        );

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Registration failed'),
              duration: const Duration(seconds: 2),
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
          ),
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
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 120),
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Welcome\n',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: '${widget.firstName} ${widget.lastName}',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Let\'s create an account',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _usernameController,
                                  style: const TextStyle(color: Colors.white),
                                  onChanged: (value) {
                                    if (value.trim().isNotEmpty) {
                                      _checkUsernameAvailability(value.trim());
                                    } else {
                                      setState(() {
                                        _isUsernameError = false;
                                        _usernameErrorMsg = '';
                                        _checkingUsername = false;
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    labelStyle: TextStyle(
                                      color: _isUsernameError
                                          ? CupertinoColors.systemRed
                                          : Colors.grey,
                                    ),
                                    suffixIcon: _checkingUsername
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: Padding(
                                              padding: EdgeInsets.all(12),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          )
                                        : _usernameAvailable &&
                                              _usernameController
                                                  .text
                                                  .isNotEmpty &&
                                              !_isUsernameError
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: CupertinoColors.systemGreen,
                                          )
                                        : null,
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
                                            : Colors.blue,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_isUsernameError)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      _usernameErrorMsg,
                                      style: const TextStyle(
                                        color: CupertinoColors.systemRed,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _emailController,
                                  style: const TextStyle(color: Colors.white),
                                  onChanged: (value) {
                                    if (value.trim().isNotEmpty) {
                                      _checkEmailAvailability(value.trim());
                                    } else {
                                      setState(() {
                                        _isEmailError = false;
                                        _emailErrorMsg = '';
                                        _checkingEmail = false;
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: TextStyle(
                                      color: _isEmailError
                                          ? CupertinoColors.systemRed
                                          : Colors.grey,
                                    ),
                                    suffixIcon: _checkingEmail
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: Padding(
                                              padding: EdgeInsets.all(12),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          )
                                        : _emailAvailable &&
                                              _emailController
                                                  .text
                                                  .isNotEmpty &&
                                              !_isEmailError
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: CupertinoColors.systemGreen,
                                          )
                                        : null,
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: _isEmailError
                                            ? CupertinoColors.systemRed
                                            : Colors.grey,
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: _isEmailError
                                            ? CupertinoColors.systemRed
                                            : Colors.blue,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_isEmailError)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      _emailErrorMsg,
                                      style: const TextStyle(
                                        color: CupertinoColors.systemRed,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _passwordController,
                                  obscureText: !_showPassword,
                                  style: const TextStyle(color: Colors.white),
                                  onChanged: (value) {
                                    setState(() {});
                                  },
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
                                ),
                                if (_passwordController.text.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value: _getPasswordStrengthValue(),
                                          backgroundColor: Colors.grey[300],
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Validators.getPasswordStrengthColor(
                                              _passwordController.text,
                                            )['color'],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        Validators.getPasswordStrengthColor(
                                          _passwordController.text,
                                        )['text'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Validators.getPasswordStrengthColor(
                                                _passwordController.text,
                                              )['color'],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (_isPasswordError)
                                    Text(
                                      _passwordErrorMsg,
                                      style: const TextStyle(
                                        color: CupertinoColors.systemRed,
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (_passwordController.text.isNotEmpty &&
                                      !_isPasswordError) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Password Requirements:',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildRequirementWidget(
                                            'At least 8 characters',
                                            _hasMinLength(),
                                          ),
                                          const SizedBox(height: 6),
                                          _buildRequirementWidget(
                                            'Uppercase letter (A-Z)',
                                            _hasUpperCase(),
                                          ),
                                          const SizedBox(height: 6),
                                          _buildRequirementWidget(
                                            'Lowercase letter (a-z)',
                                            _hasLowerCase(),
                                          ),
                                          const SizedBox(height: 6),
                                          _buildRequirementWidget(
                                            'Number (0-9)',
                                            _hasNumber(),
                                          ),
                                          const SizedBox(height: 6),
                                          _buildRequirementWidget(
                                            'Special character (!@#\$%^&*)',
                                            _hasSpecialChar(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        _loading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _signupUser,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 48,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('Sign Up'),
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
                        const SizedBox(height: 24),
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
