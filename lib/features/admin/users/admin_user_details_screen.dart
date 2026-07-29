import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/shared/config.dart';
import 'package:app/shared/services/shared_preferences_service.dart';
import 'package:app/shared/widgets/dialogs/toast_manager.dart';
import 'package:app/shared/widgets/dialogs/custom_glass_dialog.dart';
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
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _user = Map<String, dynamic>.from(widget.user);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
            color: const Color(0xFF000000),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
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
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Manage Role',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                    color: CupertinoColors.systemRed.withOpacity(0.8),
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141110),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_forward,
              color: Colors.white30,
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? 'N/A' : value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: CupertinoColors.black,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _scrollController,
            builder: (context, child) {
              final fadeIntensity = _scrollController.hasClients
                  ? (_scrollController.offset / 40.0).clamp(0.0, 1.0)
                  : 0.0;
              return ShaderMask(
                shaderCallback: (Rect rect) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(1.0 - fadeIntensity),
                      Colors.black,
                    ],
                    stops: const [0.0, 0.08],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: child,
              );
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: MediaQuery.of(context).padding.top + 16),
                        // Hero back button and title
                        Row(
                          children: [
                            Hero(
                              tag: 'back_button_user_management', // Same tag to animate from previous screen
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.pop(context, true),
                                  customBorder: const CircleBorder(),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white24, width: 1),
                                    ),
                                    child: const Icon(CupertinoIcons.back, color: Colors.white, size: 24),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'User Details',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Profile Info Centered
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: roleColor.withOpacity(0.2),
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
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: roleColor.withOpacity(0.15),
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
                            ],
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
                                    backgroundColor: const Color(0xFF141110),
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(color: Colors.white12),
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
                                  backgroundColor: const Color(0xFF141110),
                                  foregroundColor: CupertinoColors.systemRed,
                                  elevation: 2,
                                  padding: EdgeInsets.zero,
                                  shape: const CircleBorder(),
                                  side: const BorderSide(color: Colors.white12),
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
                            color: const Color(0xFF141110),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('Email', _user['email']?.toString() ?? ''),
                              const Divider(color: Colors.white12),
                              _buildDetailRow('Username', _user['username']?.toString() ?? ''),
                              
                              if (normalizedRole != 'guest') ...[
                                const Divider(color: Colors.white12),
                                _buildDetailRow('Roll Number', _user['rollNo']?.toString() ?? ''),
                                const Divider(color: Colors.white12),
                                _buildDetailRow('Year', _user['year']?.toString() ?? ''),
                                const Divider(color: Colors.white12),
                                Row(
                                  children: [
                                    Expanded(child: _buildDetailRow('Semester', _user['semester']?.toString() ?? '')),
                                    Expanded(child: _buildDetailRow('Section', _user['section']?.toString() ?? '')),
                                  ],
                                ),
                                const Divider(color: Colors.white12),
                                _buildDetailRow('Profile Complete', _user['isProfileCompleted'] == true ? 'Yes' : 'No'),
                              ] else ...[
                                const Divider(color: Colors.white12),
                                _buildDetailRow('Guest Access', '$daysLeft Days Left'),
                              ],

                              const Divider(color: Colors.white12),
                              _buildDetailRow('Joined', createdAtFormatted),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CupertinoActivityIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
