import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'admin_user_management.dart';
import 'admin_post_management.dart';
import '../../../services/shared_preferences_service.dart';
import '../../../screens/auth/login_screen.dart';
import '../../../widgets/toast_manager.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  bool get _isAdmin => (_currentUserRole ?? '').toLowerCase() == 'admin';

  Future<void> _loadRole() async {
    final role = await SharedPreferencesService.getUserRole();
    if (!mounted) return;
    setState(() {
      _currentUserRole = role?.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Salena',
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Manage users and system content',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? CupertinoColors.systemGrey : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            _SettingsCard(
              title: 'User Management',
              description: 'View users, change roles, and remove accounts',
              icon: CupertinoIcons.group_solid,
              isDark: isDark,
              onTap: () {
                if (!_isAdmin) {
                  EduMateToast.showCompact(
                    context,
                    message: 'Only Admin can access User Management',
                    isSuccess: false,
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminUserManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              title: 'Post Management',
              description: 'View and moderate community posts',
              icon: CupertinoIcons.bubble_left_bubble_right_fill,
              isDark: isDark,
              onTap: () {
                if (!_isAdmin) {
                  EduMateToast.showCompact(
                    context,
                    message: 'Only Admin can access Post Management',
                    isSuccess: false,
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminPostManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            Center(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                color: const Color(0xFFFF1744),
                onPressed: () async {
                  await SharedPreferencesService.clearUserData();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                child: const Text(
                  'Log Out',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _SettingsCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.white : Colors.black,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? CupertinoColors.systemGrey
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_forward,
              color: isDark ? Colors.white54 : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
