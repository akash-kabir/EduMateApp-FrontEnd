import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import '../widgets/settings_cards/appearance_card.dart';
import '../widgets/settings_cards/info_card.dart';
import '../widgets/settings_cards/logout_button.dart';

enum AppThemeMode { light, dark }

class SettingsScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const SettingsScreen({super.key, required this.themeProvider});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppThemeMode _getThemeMode() {
    return widget.themeProvider.isDarkMode
        ? AppThemeMode.dark
        : AppThemeMode.light;
  }

  void _onSystemThemeChanged(bool value) {
    widget.themeProvider.setFollowSystemTheme(value);
    setState(() {});
  }

  void _onThemeSelected(AppThemeMode mode) {
    widget.themeProvider.setDarkMode(mode == AppThemeMode.dark);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final followSystem = widget.themeProvider.followSystemTheme;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Colors.black : CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDark
            ? CupertinoColors.black.withOpacity(0.9)
            : CupertinoColors.white.withOpacity(0.9),
        middle: const Text('Settings'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.chevron_back),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppearanceCard(
                followSystemTheme: followSystem,
                selectedTheme: _getThemeMode(),
                onSystemThemeChanged: _onSystemThemeChanged,
                onThemeSelected: _onThemeSelected,
              ),
              const SizedBox(height: 16),
              const InfoCard(),
              const SizedBox(height: 16),

              Card(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                child: const LogoutButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
