import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import '../../constants/app_constants.dart';
import '../../services/shared_preferences_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  bool _canSendFeedback = true;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _checkFeedbackCooldown();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _checkFeedbackCooldown() async {
    final lastFeedbackTimeStr = await SharedPreferencesService.getString('last_feedback_time');
    if (lastFeedbackTimeStr != null) {
      final lastFeedbackTime = DateTime.parse(lastFeedbackTimeStr);
      final now = DateTime.now();
      final difference = now.difference(lastFeedbackTime);
      final cooldown = const Duration(hours: 24);

      if (difference < cooldown) {
        setState(() {
          _canSendFeedback = false;
          _timeRemaining = cooldown - difference;
        });
      }
    }
  }

  Future<void> _sendFeedback() async {
    final body = _feedbackController.text.trim();
    if (body.isEmpty) return;

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'edumate.admin.support@gmail.com',
      queryParameters: {
        'subject': 'EduMate App Feedback',
        'body': body,
      },
    );

    try {
      if (await launchUrl(emailLaunchUri)) {
        await SharedPreferencesService.setString('last_feedback_time', DateTime.now().toIso8601String());
        setState(() {
          _canSendFeedback = false;
          _timeRemaining = const Duration(hours: 24);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you! Redirecting to mail client...'),
              backgroundColor: Colors.green,
            ),
          );
          _feedbackController.clear();
        }
      } else {
        throw Exception('Could not launch mail client');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open mail client. Please try again later.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _formatTimeRemaining(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: UserColors.background,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        border: null,
        middle: Text('Feedback', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      child: SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "We'd love to hear from you!",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AuthPalette.coral,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Have a suggestion, found a bug, or just want to say hi? "
                          "Send us your thoughts below. (Limit: 1 feedback per 24 hours).",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (!_canSendFeedback)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "You can send another feedback in ${_formatTimeRemaining(_timeRemaining)}.",
                            style: const TextStyle(color: Colors.orangeAccent, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildGlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _feedbackController,
                      enabled: _canSendFeedback,
                      maxLines: 8,
                      maxLength: 1000,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Write your feedback here...",
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Opacity(
                  opacity: _canSendFeedback ? 1.0 : 0.5,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: AuthPalette.coral,
                    borderRadius: BorderRadius.circular(16),
                    onPressed: _canSendFeedback ? _sendFeedback : null,
                    child: const Text(
                      "Send Feedback",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
