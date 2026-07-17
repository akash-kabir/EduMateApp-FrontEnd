import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config.dart';
import '../../../services/shared_preferences_service.dart';
import '../../../widgets/toast_manager.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  bool _isLoading = true;
  List<dynamic> _users = [];
  String? _currentUserRole;
  String _searchQuery = '';
  String _selectedRoleFilter = 'All';

  String _normalizeRole(String? role) {
    final r = (role ?? 'student').toLowerCase().trim();
    if (r == 'admin') return 'admin';
    if (r == 'contributor' || r == 'contributer') return 'contributer';
    if (r == 'society' || r == 'societ' || r == 'society_head') return 'societ';
    return 'student';
  }

  String _roleLabel(String normalizedRole) {
    switch (normalizedRole) {
      case 'admin':
        return 'Admin';
      case 'contributer':
        return 'Contributer';
      case 'societ':
        return 'Societ';
      default:
        return 'Student';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUserRole();
    _fetchUsers();
  }

  Future<void> _loadCurrentUserRole() async {
    final role = await SharedPreferencesService.getUserRole();
    setState(() {
      _currentUserRole = role?.toLowerCase();
    });
  }

  Future<void> _fetchUsers() async {
    try {
      final token = await SharedPreferencesService.getToken();
      final response = await http.get(
        Uri.parse('${Config.BASE_URL}/api/users'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _users = data['data'];
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Failed to fetch users: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      final token = await SharedPreferencesService.getToken();
      final response = await http.put(
        Uri.parse('${Config.BASE_URL}/api/users/$userId/role'),
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
        _fetchUsers();
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
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      final token = await SharedPreferencesService.getToken();
      final response = await http.delete(
        Uri.parse('${Config.BASE_URL}/api/users/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        EduMateToast.showCompact(
          context,
          message: 'User deleted successfully',
          isSuccess: true,
        );
        _fetchUsers();
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
    }
  }

  void _showUserOptions(BuildContext context, Map<String, dynamic> user) {
    if (_currentUserRole != 'admin') {
      EduMateToast.showCompact(
        context,
        message: 'Only Admins can modify users',
        isSuccess: false,
      );
      return;
    }

    if (_normalizeRole(user['role']?.toString()) == 'admin') {
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final currentRole = _normalizeRole(user['role']?.toString());
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
                  'Manage User',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${user['firstName']} ${user['lastName']} • ${user['email']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? CupertinoColors.systemGrey
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'CHANGE ROLE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 12),
                if (currentRole != 'student')
                  _buildRoleOption(
                    context: context,
                    title: 'Student',
                    description: 'Read-only access to community.',
                    icon: CupertinoIcons.person,
                    color: CupertinoColors.systemGrey,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      _updateUserRole(user['_id'], 'Student');
                    },
                  ),
                if (currentRole != 'student') const SizedBox(height: 12),
                if (currentRole != 'societ')
                  _buildRoleOption(
                    context: context,
                    title: 'Societ',
                    description: 'Can create posts and events.',
                    icon: CupertinoIcons.group,
                    color: CupertinoColors.activeBlue,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      _updateUserRole(user['_id'], 'societ');
                    },
                  ),
                if (currentRole != 'societ') const SizedBox(height: 12),
                if (currentRole != 'contributer')
                  _buildRoleOption(
                    context: context,
                    title: 'Contributer',
                    description: 'Can upload data to the system.',
                    icon: CupertinoIcons.wrench,
                    color: CupertinoColors.activeOrange,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      _updateUserRole(user['_id'], 'contributer');
                    },
                  ),
                if (currentRole != 'contributer') const SizedBox(height: 12),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirm(context, user);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.destructiveRed.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CupertinoColors.destructiveRed.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.trash,
                          color: CupertinoColors.destructiveRed,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Remove User Account',
                          style: TextStyle(
                            color: CupertinoColors.destructiveRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirm(BuildContext context, Map<String, dynamic> user) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Remove User'),
        content: Text(
          'Are you sure you want to permanently delete ${user['firstName']} ${user['lastName']}? This cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(user['_id']);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredUsers = _users.where((user) {
      final role = _normalizeRole(user['role']?.toString());
      final email = (user['email']?.toString() ?? '').toLowerCase();
      final name = '${user['firstName']} ${user['lastName']}'.toLowerCase();

      final matchesSearch =
          email.contains(_searchQuery.toLowerCase()) ||
          name.contains(_searchQuery.toLowerCase());
      final matchesFilter =
          _selectedRoleFilter == 'All' ||
          role == _selectedRoleFilter.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();

    return CupertinoPageScaffold(
      backgroundColor: isDark
          ? CupertinoColors.black
          : CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark
            ? CupertinoColors.black.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.8),
        middle: const Text('User Management'),
        previousPageTitle: 'Settings',
      ),
      child: SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              // Search and Filter Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                color: isDark
                    ? CupertinoColors.black
                    : CupertinoColors.systemGroupedBackground,
                child: Column(
                  children: [
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 16, right: 12),
                            child: Icon(
                              CupertinoIcons.search,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          Expanded(
                            child: CupertinoTextField(
                              placeholder: 'Search by email or name...',
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 16,
                              ),
                              decoration: null, // removes default border
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children:
                            [
                              'All',
                              'Admin',
                              'Contributer',
                              'Societ',
                              'Student',
                            ].map((role) {
                              final isSelected = _selectedRoleFilter == role;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedRoleFilter = role;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? CupertinoColors.activeBlue
                                          : (isDark
                                                ? const Color(0xFF2C2C2E)
                                                : Colors.white),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? CupertinoColors.activeBlue
                                            : (isDark
                                                  ? Colors.white12
                                                  : Colors.black12),
                                      ),
                                    ),
                                    child: Text(
                                      role,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                                  ? Colors.white70
                                                  : Colors.black87),
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CupertinoActivityIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final normalizedRole = _normalizeRole(
                            user['role']?.toString(),
                          );
                          final role = _roleLabel(normalizedRole);
                          final firstName = user['firstName']?.toString() ?? '';
                          final lastName = user['lastName']?.toString() ?? '';
                          final initials =
                              '${firstName.isNotEmpty ? firstName[0].toUpperCase() : ''}${lastName.isNotEmpty ? lastName[0].toUpperCase() : ''}';

                          Color roleColor;
                          switch (normalizedRole) {
                            case 'admin':
                              roleColor = CupertinoColors.systemRed;
                              break;
                            case 'contributer':
                              roleColor = CupertinoColors.activeOrange;
                              break;
                            case 'societ':
                              roleColor = CupertinoColors.activeBlue;
                              break;
                            default:
                              roleColor = CupertinoColors.systemGrey;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1C1C1E)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.3)
                                      : Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showUserOptions(context, user),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: roleColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      child: Text(
                                        initials.isEmpty ? '?' : initials,
                                        style: TextStyle(
                                          color: roleColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$firstName $lastName',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            user['email'] ?? '',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isDark
                                                  ? CupertinoColors.systemGrey
                                                  : Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: roleColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        role,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: roleColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
