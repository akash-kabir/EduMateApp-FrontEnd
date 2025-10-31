import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../screens/accounts/getting_started_screen.dart';
import '../../theme/theme_provider.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  Future<void> _logout(BuildContext context) async {

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.resetThemeToDefault();

    final prefs = await SharedPreferences.getInstance();

    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      if (key != 'isDarkMode' && key != 'followSystemTheme') {
        await prefs.remove(key);
      }
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const GettingStartedScreen()),
      (route) => false,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _logout(context);
            },
            isDestructiveAction: true,
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(CupertinoIcons.square_arrow_left, color: Colors.red),
      title: const Text('Logout', style: TextStyle(color: Colors.red)),
      onTap: () => _showLogoutDialog(context),
    );
  }
}
