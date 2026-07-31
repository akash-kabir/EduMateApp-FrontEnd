import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'package:app/features/auth_and_profile/widgets/auth_background_wrapper.dart';
import 'package:app/theme/theme.dart';
import 'package:app/shared/services/api_service.dart';
import 'package:app/shared/widgets/dialogs/toast_manager.dart';
import 'package:app/features/auth_and_profile/screens/auth/reset_password_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  const OTPVerificationScreen({super.key, required this.email});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _loading = false;
  bool _isError = false;

  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _isError = true);
      EduMateToast.showCompact(context, message: 'OTP must be 6 digits', isSuccess: false);
      return;
    }

    setState(() {
      _loading = true;
      _isError = false;
    });

    final result = await ApiService.verifyOTP(widget.email, otp);

    setState(() => _loading = false);

    if (result['success'] == true) {
      final resetToken = result['resetToken'];
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResetPasswordScreen(resetToken: resetToken)),
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
    _otpController.dispose();
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
                  'Enter OTP',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We sent a 6-digit code to ${widget.email}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _otpController,
                  cursorColor: AuthPalette.coral,
                  style: const TextStyle(color: Colors.white, letterSpacing: 8, fontSize: 24),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '000000',
                    hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 8, fontSize: 24),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _isError ? Colors.red : AuthPalette.coral.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _isError ? Colors.red : AuthPalette.coral, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: _loading
                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AuthPalette.coral))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: InkWell(
                              onTap: _verifyOTP,
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
                                    'Verify',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
