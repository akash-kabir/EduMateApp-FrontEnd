import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Settings Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Placeholder for future settings
            ListTile(
              leading: const Icon(CupertinoIcons.person),
              title: const Text('Account'),
              trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.bell),
              title: const Text('Notifications'),
              trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.moon),
              title: const Text('Appearance'),
              trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.info_circle),
              title: const Text('About EduMate'),
              trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
