import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config.dart';
import '../../../services/shared_preferences_service.dart';
import '../../../widgets/toast_manager.dart';
import 'admin_user_details_screen.dart';

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
  String _sortBy = 'Role';
  bool _sortAsc = true;

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

  int _getRoleWeight(String normalizedRole) {
    switch (normalizedRole) {
      case 'admin':
        return 4;
      case 'contributer':
        return 3;
      case 'societ':
        return 2;
      case 'student':
        return 1;
      case 'guest':
        return 0;
      default:
        return 0;
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
        if (!mounted) return;
        EduMateToast.showCompact(
          context,
          message: 'Role updated successfully',
          isSuccess: true,
        );
        _fetchUsers();
      } else {
        if (!mounted) return;
        EduMateToast.showCompact(
          context,
          message: 'Failed to update role',
          isSuccess: false,
        );
      }
    } catch (e) {
      if (!mounted) return;
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
        if (!mounted) return;
        EduMateToast.showCompact(
          context,
          message: 'User deleted successfully',
          isSuccess: true,
        );
        _fetchUsers();
      } else {
        if (!mounted) return;
        EduMateToast.showCompact(
          context,
          message: 'Failed to delete user',
          isSuccess: false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      EduMateToast.showCompact(
        context,
        message: 'Error deleting user',
        isSuccess: false,
      );
    }
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

    filteredUsers.sort((a, b) {
      if (_sortBy == 'Role') {
        final weightA = _getRoleWeight(_normalizeRole(a['role']?.toString()));
        final weightB = _getRoleWeight(_normalizeRole(b['role']?.toString()));
        final res = weightB.compareTo(weightA); // higher weight (admin) first
        if (res != 0) return _sortAsc ? res : -res;
      } else if (_sortBy == 'Date Created') {
        final dateA = a['createdAt'] != null ? DateTime.tryParse(a['createdAt'].toString()) : DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b['createdAt'] != null ? DateTime.tryParse(b['createdAt'].toString()) : DateTime.fromMillisecondsSinceEpoch(0);
        if (dateA != null && dateB != null) {
          final res = dateB.compareTo(dateA); // newest first
          if (res != 0) return _sortAsc ? res : -res;
        }
      }
      
      // Fallback sort by name
      final nameA = '${a['firstName']} ${a['lastName']}'.toLowerCase();
      final nameB = '${b['firstName']} ${b['lastName']}'.toLowerCase();
      return _sortAsc ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
    });

    return CupertinoPageScaffold(
      backgroundColor: isDark
          ? CupertinoColors.black
          : CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark
            ? CupertinoColors.black.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.8),
        middle: const Text('User Management'),
        leading: CupertinoNavigationBarBackButton(
          color: CupertinoColors.systemRed,
          onPressed: () => Navigator.pop(context),
        ),
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
                    Row(
                      children: [
                        Expanded(
                          child: PopupMenuButton<String>(
                            initialValue: _sortBy,
                            onSelected: (value) {
                              if (value == _sortBy) {
                                setState(() => _sortAsc = !_sortAsc);
                              } else {
                                setState(() {
                                  _sortBy = value;
                                  _sortAsc = true;
                                });
                              }
                            },
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.sort_down, size: 16, color: isDark ? Colors.white : Colors.black),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$_sortBy ${_sortAsc ? '↓' : '↑'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'Role', child: Text('Sort by Role')),
                              const PopupMenuItem(value: 'Date Created', child: Text('Sort by Date Created')),
                              const PopupMenuItem(value: 'Name', child: Text('Sort by Name')),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PopupMenuButton<String>(
                            initialValue: _selectedRoleFilter,
                            onSelected: (value) {
                              setState(() {
                                _selectedRoleFilter = value;
                              });
                            },
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.line_horizontal_3_decrease, size: 16, color: isDark ? Colors.white : Colors.black),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedRoleFilter == 'All' ? 'Filter Roles' : _selectedRoleFilter,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'All', child: Text('All Roles')),
                              const PopupMenuItem(value: 'Admin', child: Text('Admin')),
                              const PopupMenuItem(value: 'Contributer', child: Text('Contributer')),
                              const PopupMenuItem(value: 'Societ', child: Text('Society')),
                              const PopupMenuItem(value: 'Student', child: Text('Student')),
                              const PopupMenuItem(value: 'guest', child: Text('Guest')),
                            ],
                          ),
                        ),
                      ],
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
                              roleColor = Colors.red;
                              break;
                            case 'contributer':
                              roleColor = Colors.purple;
                              break;
                            case 'societ':
                              roleColor = Colors.orange;
                              break;
                            case 'guest':
                              roleColor = Colors.teal;
                              break;
                            default:
                              roleColor = Colors.blue;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
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
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminUserDetailsScreen(
                                      user: user,
                                      currentUserRole: _currentUserRole ?? '',
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _fetchUsers();
                                }
                              },
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
