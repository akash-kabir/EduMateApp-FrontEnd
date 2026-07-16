import 'package:flutter/material.dart';
import '../../widgets/auth_background_wrapper.dart';
import '../../constants/app_constants.dart';
import '../../services/api_service.dart';
import '../../widgets/toast_manager.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String resetToken;
  const ResetPasswordScreen({super.key, required this.resetToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _loading = false;
  bool _isError = false;
  bool _showPassword = false;

  Future<void> _resetPassword() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.isEmpty || password.length < 6) {
      setState(() => _isError = true);
      EduMateToast.showCompact(context, message: 'Password must be at least 6 characters', isSuccess: false);
      return;
    }

    if (password != confirm) {
      setState(() => _isError = true);
      EduMateToast.showCompact(context, message: 'Passwords do not match', isSuccess: false);
      return;
    }

    setState(() {
      _loading = true;
      _isError = false;
    });

    final result = await ApiService.resetPassword(widget.resetToken, password);

    setState(() => _loading = false);

    if (result['success'] == true) {
      if (mounted) {
        EduMateToast.showCompact(context, message: 'Password reset successful', isSuccess: true);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        EduMateToast.showCompact(context, message: result['message'], isSuccess: false);
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: AuthBackgroundWrapper(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                const Text(
                  'Create New Password',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your new password must be different from previous used passwords.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: TextStyle(color: _isError ? Colors.red : AuthPalette.blush),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                        color: AuthPalette.coral,
                      ),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _isError ? Colors.red : AuthPalette.coral.withOpacity(0.55)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _isError ? Colors.red : AuthPalette.blush),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmController,
                  obscureText: !_showPassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(color: _isError ? Colors.red : AuthPalette.blush),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _isError ? Colors.red : AuthPalette.coral.withOpacity(0.55)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _isError ? Colors.red : AuthPalette.blush),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: _loading
                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AuthPalette.deepTeal))
                      : ElevatedButton(
                          onPressed: _resetPassword,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                            backgroundColor: AuthPalette.deepTeal,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Reset Password'),
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
