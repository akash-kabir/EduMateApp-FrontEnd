import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
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
              'Admin Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Welcome to the admin panel',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? CupertinoColors.systemGrey : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            _AdminCard(
              title: 'Curriculum Management',
              description: 'Upload and manage course curriculum',
              icon: Icons.school_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _AdminCard(
              title: 'Users',
              description: 'View and manage user accounts',
              icon: Icons.people_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _AdminCard(
              title: 'Posts & Events',
              description: 'Manage posts and upcoming events',
              icon: Icons.event_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isDark;

  const _AdminCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.systemGrey6.withOpacity(0.3)
            : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF1744).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF1744).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFFF1744), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? CupertinoColors.systemGrey
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(CupertinoIcons.forward, color: const Color(0xFFFF1744)),
        ],
      ),
    );
  }
}
