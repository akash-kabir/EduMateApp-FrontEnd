import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config.dart';
import '../../../services/shared_preferences_service.dart';
import '../../../widgets/toast_manager.dart';
import '../../../widgets/custom_glass_dialog.dart';
import 'package:intl/intl.dart';

class AdminUserDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String currentUserRole;

  const AdminUserDetailsScreen({
    super.key,
    required this.user,
    required this.currentUserRole,
  });

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> {
  late Map<String, dynamic> _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _user = Map<String, dynamic>.from(widget.user);
  }

  String _normalizeRole(String? role) {
    final r = (role ?? 'student').toLowerCase().trim();
    if (r == 'admin') return 'admin';
    if (r == 'contributor' || r == 'contributer') return 'contributer';
    if (r == 'society' || r == 'societ' || r == 'society_head') return 'societ';
    if (r == 'guest') return 'guest';
    return 'student';
  }

  String _roleLabel(String normalizedRole) {
    switch (normalizedRole) {
      case 'admin':
        return 'Admin';
      case 'contributer':
        return 'Contributer';
      case 'societ':
        return 'Society Head';
      case 'guest':
        return 'Guest';
      default:
        return 'Student';
    }
  }

  Color _roleColor(String normalizedRole) {
    switch (normalizedRole) {
      case 'admin':
        return Colors.red;
      case 'contributer':
        return Colors.purple;
      case 'societ':
        return Colors.orange;
      case 'guest':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  Future<void> _updateUserRole(String newRole) async {
    setState(() => _isLoading = true);
    try {
      final token = await SharedPreferencesService.getToken();
      final response = await http.put(
        Uri.parse('${Config.BASE_URL}/api/users/${_user['_id']}/role'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'role': newRole}),
      );

      if (response.statusCode == 200) {
        EduMateToast.showCompact(
          context,
          message: 'Role updated successfully',
          isSuccess: true,
        );
        setState(() {
          _user['role'] = newRole;
        });
      } else {
        EduMateToast.showCompact(
          context,
          message: 'Failed to update role',
          isSuccess: false,
        );
      }
    } catch (e) {
      EduMateToast.showCompact(
        context,
        message: 'Error updating role',
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRoleManagementSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentRole = _normalizeRole(_user['role']?.toString());

    if (currentRole == 'admin' && _normalizeRole(widget.currentUserRole) != 'superadmin') {
      EduMateToast.showCompact(
        context,
        message: 'Cannot modify another Admin',
        isSuccess: false,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E24) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Manage Role',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 32),
                
                if (currentRole != 'student')
                  _buildRoleOption(
                    context: context,
                    title: 'Student',
                    description: 'Standard access to community features.',
                    icon: CupertinoIcons.person,
                    color: CupertinoColors.systemGrey,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      _updateUserRole('Student');
                    },
                  ),
                if (currentRole != 'student') const SizedBox(height: 12),
                if (currentRole != 'societ')
                  _buildRoleOption(
                    context: context,
                    title: 'Society Head',
                    description: 'Can manage society posts and events.',
                    icon: CupertinoIcons.group,
                    color: CupertinoColors.activeBlue,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      _updateUserRole('Society');
                    },
                  ),
                if (currentRole != 'societ') const SizedBox(height: 12),
                if (currentRole != 'contributer')
                  _buildRoleOption(
                    context: context,
                    title: 'Contributor',
                    description: 'Can create content for curriculum and schedules.',
                    icon: CupertinoIcons.doc_text,
                    color: CupertinoColors.systemRed.withValues(alpha: 0.8),
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      _updateUserRole('Contributer');
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleOption({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
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
                      color: isDark ? Colors.white : Colors.black,
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
            Icon(
              CupertinoIcons.chevron_forward,
              color: isDark ? Colors.white30 : Colors.black26,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser() async {
    final bool? confirm = await showDeleteConfirmationDialog(
      context: context,
      title: 'Delete User',
      description: 'Are you sure you want to permanently delete ${_user['firstName']} ${_user['lastName']}? This cannot be undone.',
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final token = await SharedPreferencesService.getToken();
      final response = await http.delete(
        Uri.parse('${Config.BASE_URL}/api/users/${_user['_id']}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          EduMateToast.showCompact(
            context,
            message: 'User deleted successfully',
            isSuccess: true,
          );
          Navigator.pop(context, true); // Pop and signal a deletion
        }
      } else {
        EduMateToast.showCompact(
          context,
          message: 'Failed to delete user',
          isSuccess: false,
        );
      }
    } catch (e) {
      EduMateToast.showCompact(
        context,
        message: 'Error deleting user',
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: isDark ? CupertinoColors.systemGrey : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? 'N/A' : value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalizedRole = _normalizeRole(_user['role']?.toString());
    final roleColor = _roleColor(normalizedRole);
    final firstName = _user['firstName']?.toString() ?? '';
    final lastName = _user['lastName']?.toString() ?? '';
    final initials = '${firstName.isNotEmpty ? firstName[0].toUpperCase() : ''}${lastName.isNotEmpty ? lastName[0].toUpperCase() : ''}';
    
    // Format date if available
    String createdAtFormatted = 'Unknown';
    if (_user['createdAt'] != null) {
      try {
        final date = DateTime.parse(_user['createdAt']);
        createdAtFormatted = DateFormat('MMM dd, yyyy').format(date);
      } catch (_) {}
    }

    int daysLeft = 0;
    if (normalizedRole == 'guest' && _user['createdAt'] != null) {
      try {
        final date = DateTime.parse(_user['createdAt']);
        final diff = DateTime.now().difference(date).inDays;
        daysLeft = 7 - diff;
        if (daysLeft < 0) daysLeft = 0;
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.systemGroupedBackground,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: roleColor.withValues(alpha: 0.2),
                    child: Text(
                      initials.isEmpty ? '?' : initials,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: roleColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$firstName $lastName',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _roleLabel(normalizedRole),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: roleColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _showRoleManagementSheet(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                              foregroundColor: isDark ? Colors.white : Colors.black,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Manage Role',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        height: 56,
                        width: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _deleteUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                            foregroundColor: CupertinoColors.systemRed,
                            elevation: 2,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Icon(CupertinoIcons.trash, size: 24),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
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
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Email', _user['email']?.toString() ?? '', isDark),
                        Divider(color: isDark ? Colors.white12 : Colors.black12),
                        _buildDetailRow('Username', _user['username']?.toString() ?? '', isDark),
                        
                        if (normalizedRole != 'guest') ...[
                          Divider(color: isDark ? Colors.white12 : Colors.black12),
                          _buildDetailRow('Roll Number', _user['rollNo']?.toString() ?? '', isDark),
                          Divider(color: isDark ? Colors.white12 : Colors.black12),
                          _buildDetailRow('Year', _user['year']?.toString() ?? '', isDark),
                          Divider(color: isDark ? Colors.white12 : Colors.black12),
                          Row(
                            children: [
                              Expanded(child: _buildDetailRow('Semester', _user['semester']?.toString() ?? '', isDark)),
                              Expanded(child: _buildDetailRow('Section', _user['section']?.toString() ?? '', isDark)),
                            ],
                          ),
                          Divider(color: isDark ? Colors.white12 : Colors.black12),
                          _buildDetailRow('Profile Complete', _user['isProfileComplete'] == true ? 'Yes' : 'No', isDark),
                        ] else ...[
                          Divider(color: isDark ? Colors.white12 : Colors.black12),
                          _buildDetailRow('Guest Access', '$daysLeft Days Left', isDark),
                        ],

                        Divider(color: isDark ? Colors.white12 : Colors.black12),
                        _buildDetailRow('Joined', createdAtFormatted, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Hero Back Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context, true),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black45 : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(CupertinoIcons.back, color: isDark ? Colors.white : Colors.black),
                ),
              ),
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CupertinoActivityIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
