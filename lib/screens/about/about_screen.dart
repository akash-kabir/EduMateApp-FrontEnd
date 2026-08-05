import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/theme/theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding,
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

  Widget _buildAppInfoCard() {
    return _buildGlassCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "EduMate",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AuthPalette.coral,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "EduMate is your personal campus companion — keeping you updated "
            "with events, schedules, and campus life in one place.\n\n"
            "Built with Flutter for a seamless, modern experience.",
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinksCard() {
    return _buildGlassCard(
      child: Column(
        children: [
          _buildLinkButton(
            title: "LinkedIn",
            iconUrl: "https://img.icons8.com/color/48/linkedin.png",
            onTap: () => _launchUrl("https://www.linkedin.com/in/mirza-akash-kabir/"),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1, indent: 60),
          _buildLinkButton(
            title: "GitHub",
            iconUrl: "https://img.icons8.com/fluency/48/github.png",
            onTap: () => _launchUrl("https://github.com/akash-kabir"),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1, indent: 60),
          _buildLinkButton(
            title: "Instagram",
            iconUrl: "https://img.icons8.com/fluency/48/instagram-new.png",
            onTap: () => _launchUrl("https://www.instagram.com/_akashkabir_/"),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkButton({
    required String title,
    required String iconUrl,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Image.network(
          iconUrl,
          width: 28,
          height: 28,
          errorBuilder: (context, error, stackTrace) => const Icon(
            CupertinoIcons.globe, 
            color: Colors.white54, 
            size: 24
          ),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        CupertinoIcons.chevron_forward,
        size: 20,
        color: Colors.white54,
      ),
      onTap: onTap,
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
                        Colors.black.withValues(alpha: 1.0 - fadeIntensity),
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
                                'About',
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
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          _buildAppInfoCard(),
                          const SizedBox(height: 20),
                          _buildSocialLinksCard(),
                          const SizedBox(height: 40),
                          const Center(
                            child: Text(
                              "Created By Kabir",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AuthPalette.coral,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
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
