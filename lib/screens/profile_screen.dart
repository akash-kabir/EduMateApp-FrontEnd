import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../widgets/profile_cards/profile_card.dart';
import '../theme/theme_provider.dart';
import '../widgets/navigation/profile_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userFirstName = '';
  String userLastName = '';
  String userEmail = '';
  String userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userFirstName = prefs.getString('userFirstName') ?? '';
      userLastName = prefs.getString('userLastName') ?? '';
      userEmail = prefs.getString('userEmail') ?? '';
      userName = prefs.getString('userName') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: ProfileAppBar(
        themeProvider: themeProvider,
        username: userName,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            ProfileCard(
              fullName: '$userFirstName $userLastName',
              email: userEmail,
              backgroundColor: isDark ? Colors.grey[900]! : Colors.grey[200]!,
              textColor: isDark ? Colors.white : Colors.black87,
              iconColor: CupertinoColors.systemGreen,
            ),
          ],
        ),
      ),
    );
  }
}
