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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.9),
        centerTitle: true,
        title: const Text(
          "About",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            fontFamily: 'Poppins',
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.chevron_back,
            color: CupertinoColors.systemGrey2,
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
          child: isLandscape
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildAppInfoCard()),
                    const SizedBox(width: 20),
                    Expanded(child: _buildSocialLinksCard(context)),
                  ],
                )
              : Column(
                  children: [
                    _buildAppInfoCard(),
                    const SizedBox(height: 20),
                    _buildSocialLinksCard(context),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Card(
      color: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "EduMate ",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.activeBlue,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "EduMate is your personal campus companion — keeping you updated "
              "with events, schedules, and campus life in one place.\n\n"
              "Built with Flutter for a seamless, modern experience.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinksCard(BuildContext context) {
    return Card(
      color: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        children: [
          _buildLinkButton(
            title: "LinkedIn",
            iconPath: "assets/linkedin.png",
            onTap: () => _launchUrl("https://linkedin.com"),
          ),
          _divider(),
          _buildLinkButton(
            title: "GitHub",
            iconPath: "assets/github.png",
            onTap: () => _launchUrl("https://github.com/akash-kabir"),
          ),
          _divider(),
          _buildLinkButton(
            title: "Gmail",
            iconPath: "assets/gmail.png",
            onTap: () => _launchUrl("mailto:2405359@kiit.ac.in"),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 5, thickness: 0.5, color: Colors.white12);

  Widget _buildLinkButton({
    required String title,
    required String iconPath,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Image.asset(iconPath, width: 28, height: 28),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
      trailing: const Icon(
        CupertinoIcons.chevron_forward,
        size: 18,
        color: CupertinoColors.activeBlue,
      ),
      onTap: onTap,
    );
  }
}
