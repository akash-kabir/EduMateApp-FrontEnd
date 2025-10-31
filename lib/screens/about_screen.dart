import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: (isDark ? Colors.black : Colors.white).withOpacity(
          0.9,
        ),
        centerTitle: true,
        title: Text(
          "About",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            fontFamily: 'Poppins',
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.chevron_back,
            color: isDark ? CupertinoColors.systemGrey2 : Colors.black54,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Center(
            child: Text(
              "Created By Kabir",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildAppInfoCard(isDark),
              const SizedBox(height: 20),
              _buildSocialLinksCard(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color.fromARGB(255, 15, 15, 15)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "EduMate",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.activeBlue,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "EduMate is your personal campus companion — keeping you updated "
            "with events, schedules, and campus life in one place.\n\n"
            "Built with Flutter for a seamless, modern experience.",
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinksCard(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color.fromARGB(255, 15, 15, 15)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildLinkButton(
            title: "LinkedIn",
            iconPath: "assets/linkedin.png",
            onTap: () => _launchUrl("https://linkedin.com"),
            isDark: isDark,
          ),
          _divider(isDark),
          _buildLinkButton(
            title: "GitHub",
            iconPath: "assets/github.png",
            onTap: () => _launchUrl("https://github.com/akash-kabir"),
            isDark: isDark,
          ),
          _divider(isDark),
          _buildLinkButton(
            title: "Gmail",
            iconPath: "assets/gmail.png",
            onTap: () => _launchUrl("mailto:2405359@kiit.ac.in"),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(
    height: 5,
    thickness: 0.5,
    color: isDark ? Colors.white12 : Colors.black12,
  );

  Widget _buildLinkButton({
    required String title,
    required String iconPath,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      leading: Image.asset(iconPath, width: 28, height: 28),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing: const Icon(
        CupertinoIcons.chevron_forward,
        size: 25,
        color: CupertinoColors.activeBlue,
      ),
      onTap: onTap,
    );
  }
}
