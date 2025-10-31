import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../widgets/profile_cards/profile_card.dart';
import '../theme/theme_provider.dart';
import 'settings_screen.dart';
import 'manage_posts_screen.dart';

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
  String userRole = 'student';

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
      userRole = prefs.getString('userRole') ?? 'student';
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSocietyHead = userRole.toLowerCase() == 'society_head';

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Colors.black : CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDark
            ? CupertinoColors.black.withOpacity(0.6)
            : CupertinoColors.white.withOpacity(0.6),
        middle: Text('@$userName'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(themeProvider: themeProvider),
              ),
            );
          },
          child: const Icon(CupertinoIcons.settings),
        ),
      ),
      child: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 16),
            ProfileCard(
              fullName: '$userFirstName $userLastName',
              email: userEmail,
              role: userRole,
              backgroundColor: isDark ? Colors.grey[900]! : Colors.grey[200]!,
              textColor: isDark ? Colors.white : Colors.black87,
              iconColor: CupertinoColors.activeBlue,
            ),

            if (isSocietyHead) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManagePostsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemPurple.withOpacity(
                              0.2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            CupertinoIcons.doc_text,
                            color: CupertinoColors.systemPurple,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manage Your Posts',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'View and delete your posts',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_forward,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
