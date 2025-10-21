import 'package:edumate/widgets/appearance_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


enum AppThemeMode { light, dark }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _followSystemTheme = true;
  AppThemeMode _selectedTheme = AppThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.9),
        centerTitle: true,
        title: const Text(
          "Settings",
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: AppearanceCard(
            followSystemTheme: _followSystemTheme,
            selectedTheme: _selectedTheme,
            onSystemThemeChanged: (val) {
              setState(() {
                _followSystemTheme = val;
              });
            },
            onThemeSelected: (mode) {
              setState(() {
                _selectedTheme = mode;
                // TODO: Apply theme dynamically
              });
            },
          ),
        ),
      ),
    );
  }
}
