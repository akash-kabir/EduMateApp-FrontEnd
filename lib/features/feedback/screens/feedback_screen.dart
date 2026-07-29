import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/theme/theme.dart';
import 'package:app/shared/services/shared_preferences_service.dart';
import 'package:app/shared/widgets/dialogs/toast_manager.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  late ScrollController _scrollController;
  bool _canSendFeedback = true;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _checkFeedbackCooldown();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
          EduMateToast.showCompact(
            context,
            message: 'Thank you! Redirecting to mail client...',
            isSuccess: true,
          );
          _feedbackController.clear();
        }
      } else {
        throw Exception('Could not launch mail client');
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(
          context,
          message: 'Could not open mail client. Please try again later.',
          isSuccess: false,
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
        color: const Color(0xFF141110),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _scrollController,
              builder: (context, child) {
                final fadeIntensity = _scrollController.hasClients
                    ? (_scrollController.offset / 40.0).clamp(0.0, 1.0)
                    : 0.0;
                return ShaderMask(
                  shaderCallback: (Rect rect) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(1.0 - fadeIntensity),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.08],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: child,
                );
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 16.0),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Hero(
                                  tag: 'back_button',
                                  child: CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () => Navigator.pop(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF141110),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(CupertinoIcons.back,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                              const Text(
                                'Feedback',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'Salena',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Color(0xFFFF9B7A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
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
                                      color: Colors.white.withOpacity(0.8),
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
                                color: Colors.orangeAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
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
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(16),
                                  counterStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
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
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
