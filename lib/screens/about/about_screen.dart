import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import '../../constants/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: UserColors.background,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        border: null,
        middle: Text('About', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      child: SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding,
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
}
