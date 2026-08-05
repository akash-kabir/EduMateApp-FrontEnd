import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/shared/config.dart';
import 'package:app/shared/services/shared_preferences_service.dart';
import 'package:app/features/admin/users/admin_user_details_screen.dart';

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
  late ScrollController _scrollController;

  String _normalizeRole(String? role) {
    final r = (role ?? 'student').toLowerCase().trim();
    if (r == 'admin') return 'admin';
    if (r == 'contributor' || r == 'contributor') return 'contributor';
    if (r == 'society' || r == 'societ' || r == 'society_head') return 'society';
    if (r == 'guest') return 'guest';
    return 'student';
  }

  String _roleLabel(String normalizedRole) {
    switch (normalizedRole) {
      case 'admin':
        return 'Admin';
      case 'contributor':
        return 'contributor';
      case 'society':
        return 'Society';
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
      case 'contributor':
        return 3;
      case 'society':
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
    _scrollController = ScrollController();
    _loadCurrentUserRole();
    _fetchUsers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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


  @override
  Widget build(BuildContext context) {
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
                      Colors.black.withValues(alpha: 1.0 - fadeIntensity),
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
                              tag: 'back_button_user_management',
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.pop(context),
                                  customBorder: const CircleBorder(),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.black.withValues(alpha: 0.5),
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
                                'User Management',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Search and Filter Header
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF141110),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white12),
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
                                  style: const TextStyle(
                                    color: Colors.white,
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
                                color: const Color(0xFF2C2C2E),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141110),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(CupertinoIcons.sort_down, size: 16, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$_sortBy ${_sortAsc ? '↓' : '↑'}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
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
                                color: const Color(0xFF2C2C2E),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141110),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(CupertinoIcons.line_horizontal_3_decrease, size: 16, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        _selectedRoleFilter == 'All' ? 'Filter Roles' : _selectedRoleFilter,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'All', child: Text('All Roles')),
                                  const PopupMenuItem(value: 'Admin', child: Text('Admin')),
                                  const PopupMenuItem(value: 'contributor', child: Text('contributor')),
                                  const PopupMenuItem(value: 'Society', child: Text('Society')),
                                  const PopupMenuItem(value: 'Student', child: Text('Student')),
                                  const PopupMenuItem(value: 'guest', child: Text('Guest')),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CupertinoActivityIndicator()),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
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
                            case 'contributor':
                              roleColor = Colors.purple;
                              break;
                            case 'society':
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
                              color: const Color(0xFF141110),
                              borderRadius: BorderRadius.circular(24),
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
                                      backgroundColor: roleColor.withValues(alpha: 0.2),
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$firstName $lastName',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            user['email'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: CupertinoColors.systemGrey,
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
                                        color: roleColor.withValues(alpha: 0.15),
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
                        childCount: filteredUsers.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
