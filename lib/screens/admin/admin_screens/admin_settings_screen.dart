import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_user_management.dart';
import 'admin_post_management.dart';
import '../../../config.dart';
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
  bool _isNavigationActive = true;
  int _currentMonthCount = 0;
  int _monthlyLimit = 85000;
  bool _isLoadingConfig = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _fetchSystemConfig();
  }

  bool get _isAdmin => (_currentUserRole ?? '').toLowerCase() == 'admin';

  Future<void> _loadRole() async {
    final role = await SharedPreferencesService.getUserRole();
    if (!mounted) return;
    setState(() {
      _currentUserRole = role?.toLowerCase();
    });
  }

  Future<void> _fetchSystemConfig() async {
    try {
      setState(() => _isLoadingConfig = true);
      final token = await SharedPreferencesService.getToken();
      final url = Uri.parse('${Config.BASE_URL}/api/admin/system-config');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && mounted) {
          final config = data['data'];
          setState(() {
            _isNavigationActive = config['isNavigationActive'] ?? true;
            _currentMonthCount = config['currentMonthDirectionsCount'] ?? 0;
            _monthlyLimit = config['monthlyDirectionsLimit'] ?? 85000;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching system config: $e');
    } finally {
      if (mounted) setState(() => _isLoadingConfig = false);
    }
  }

  Future<void> _toggleNavigation(bool active) async {
    try {
      setState(() => _isLoadingConfig = true);
      final token = await SharedPreferencesService.getToken();
      final url = Uri.parse('${Config.BASE_URL}/api/admin/system-config');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'isNavigationActive': active,
        }),
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _isNavigationActive = active;
        });
        EduMateToast.showCompact(
          context,
          message: active ? 'Campus Navigation Enabled' : 'Campus Navigation Disabled',
          isSuccess: active,
        );
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(
          context,
          message: 'Failed to update system settings',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingConfig = false);
    }
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
              'Admin Settings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Salena',
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Manage users, services, and system content',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? CupertinoColors.systemGrey : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),

            // ── Kill Switch Card ──
            if (_isAdmin) ...[
              _MapKillSwitchCard(
                isDark: isDark,
                isNavigationActive: _isNavigationActive,
                currentMonthCount: _currentMonthCount,
                monthlyLimit: _monthlyLimit,
                isLoading: _isLoadingConfig,
                onToggle: _toggleNavigation,
              ),
              const SizedBox(height: 20),
            ],

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

class _MapKillSwitchCard extends StatelessWidget {
  final bool isDark;
  final bool isNavigationActive;
  final int currentMonthCount;
  final int monthlyLimit;
  final bool isLoading;
  final ValueChanged<bool> onToggle;

  const _MapKillSwitchCard({
    required this.isDark,
    required this.isNavigationActive,
    required this.currentMonthCount,
    required this.monthlyLimit,
    required this.isLoading,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isNavigationActive
        ? (currentMonthCount >= monthlyLimit ? Colors.orange : Colors.green)
        : Colors.red;

    final statusText = !isNavigationActive
        ? 'Disabled by Admin'
        : (currentMonthCount >= monthlyLimit ? 'Quota Exceeded (85k Limit)' : 'Active (Zero Billing Shield)');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF2C2C2E), Color(0xFF1C1C1E)]
              : const [Color(0xFFF2F2F7), Color(0xFFE5E5EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.map_fill,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campus Navigation Kill Switch',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const CupertinoActivityIndicator(radius: 10)
              else
                CupertinoSwitch(
                  value: isNavigationActive,
                  activeColor: Colors.green,
                  onChanged: onToggle,
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Directions Usage:',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
                ),
              ),
              Text(
                '$currentMonthCount / $monthlyLimit routes',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ],
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
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF303030), Color(0xFF1a1a1a)]
                : const [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
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
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
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
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_forward,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}
