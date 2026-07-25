import 'package:flutter/material.dart';
import 'package:app/features/auth_and_profile/widgets/auth_background_wrapper.dart';
import 'package:app/theme/theme.dart';
import 'package:app/shared/services/api_service.dart';
import 'package:app/shared/widgets/dialogs/toast_manager.dart';
import 'package:app/features/auth_and_profile/screens/auth/otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;
  bool _isError = false;

  Future<void> _sendOTP() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _isError = true);
      EduMateToast.showCompact(context, message: 'Please enter a valid email', isSuccess: false);
      return;
    }

    setState(() {
      _loading = true;
      _isError = false;
    });

    final result = await ApiService.forgotPassword(email);

    setState(() => _loading = false);

    if (result['success'] == true) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OTPVerificationScreen(email: email)),
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
    _emailController.dispose();
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
                  'Forgot Password',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enter your email address to receive a 6-digit OTP for resetting your password.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
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
                          onPressed: _sendOTP,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                            backgroundColor: AuthPalette.deepTeal,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Send OTP'),
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
