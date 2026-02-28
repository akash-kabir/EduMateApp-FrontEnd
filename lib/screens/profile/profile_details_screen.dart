import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import '../../config.dart';
import '../../services/shared_preferences_service.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  String? error;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _fetchProfileData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    try {
      final token = await SharedPreferencesService.getToken();

      if (token == null) {
        setState(() {
          error = 'No authentication token found';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(Config.profileEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          profileData = data['data'] ?? data;
          isLoading = false;
        });
        _animController.forward();
      } else {
        setState(() {
          error = 'Failed to load profile data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = CupertinoColors.systemBlue;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Profile'),
        previousPageTitle: 'Home',
        backgroundColor: isDark
            ? CupertinoColors.black.withOpacity(0.7)
            : CupertinoColors.white.withOpacity(0.7),
      ),
      child: Material(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: SafeArea(
          child: isLoading
              ? const Center(child: CupertinoActivityIndicator(radius: 16))
              : error != null
              ? _buildErrorState(isDark)
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildContent(isDark, accentColor),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 48,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  error = null;
                });
                _fetchProfileData();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, Color accentColor) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Hero header with gradient
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildProfileHeader(isDark, accentColor),
          ),
          // Info cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick stats row
                _buildQuickStats(isDark, accentColor),
                const SizedBox(height: 24),
                // Personal info section
                _buildSectionHeader(
                  'Personal Information',
                  CupertinoIcons.person_fill,
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildGroupedCard(isDark, [
                  _InfoRow(
                    icon: CupertinoIcons.mail,
                    label: 'Email',
                    value: profileData?['email'] ?? 'N/A',
                  ),
                  _InfoRow(
                    icon: CupertinoIcons.number,
                    label: 'Roll Number',
                    value: profileData?['rollNo'] ?? 'N/A',
                  ),
                ]),
                const SizedBox(height: 24),
                // Academic info section
                _buildSectionHeader(
                  'Academic Information',
                  CupertinoIcons.book_fill,
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildGroupedCard(isDark, [
                  _InfoRow(
                    icon: CupertinoIcons.rectangle_grid_1x2,
                    label: 'Section',
                    value: profileData?['section'] ?? 'N/A',
                  ),
                  _InfoRow(
                    icon: CupertinoIcons.calendar,
                    label: 'Year',
                    value: profileData?['year'] ?? 'N/A',
                  ),
                ]),
                const SizedBox(height: 24),
                // Account section
                _buildSectionHeader(
                  'Account',
                  CupertinoIcons.shield_fill,
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildGroupedCard(isDark, [
                  _InfoRow(
                    icon: CupertinoIcons.star_fill,
                    label: 'Role',
                    value: _formatRole(profileData?['role'] ?? 'student'),
                  ),
                  _InfoRow(
                    icon: CupertinoIcons.checkmark_seal_fill,
                    label: 'Profile Status',
                    value: (profileData?['isProfileCompleted'] == true)
                        ? 'Complete'
                        : 'Incomplete',
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark, Color accentColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor,
            accentColor.withOpacity(0.7),
            isDark ? const Color(0xFF1A1A2E) : const Color(0xFF667EEA),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          children: [
            // Avatar with border
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2.5,
                ),
              ),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: Center(
                  child: Text(
                    _getInitials(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Full name
            Text(
              _getFullName(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            // Username badge
            if (profileData?['username'] != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '@${profileData!['username']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            // Email
            Text(
              profileData?['email'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(bool isDark, Color accentColor) {
    final branch = profileData?['branch'] ?? '—';
    final semester = profileData?['semester']?.toString() ?? '—';
    final role = _formatRole(profileData?['role'] ?? 'student');

    return Row(
      children: [
        Expanded(child: _buildStatChip(branch, 'Branch', isDark, accentColor)),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatChip(semester, 'Semester', isDark, accentColor),
        ),
        const SizedBox(width: 10),
        Expanded(child: _buildStatChip(role, 'Role', isDark, accentColor)),
      ],
    );
  }

  Widget _buildStatChip(
    String value,
    String label,
    bool isDark,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black45,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? Colors.white54 : Colors.black45),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black45,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedCard(bool isDark, List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: List.generate(rows.length, (index) {
          final row = rows[index];
          final isLast = index == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isDark
                            ? CupertinoColors.systemBlue.withOpacity(0.15)
                            : CupertinoColors.systemBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        row.icon,
                        size: 17,
                        color: CupertinoColors.systemBlue,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            row.value,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 64),
                  child: Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.06),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  String _getInitials() {
    final firstName = profileData?['firstName'] ?? '';
    final lastName = profileData?['lastName'] ?? '';
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
        .toUpperCase();
  }

  String _getFullName() {
    final firstName = profileData?['firstName'] ?? '';
    final lastName = profileData?['lastName'] ?? '';
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : 'User';
  }

  String _formatRole(String role) {
    if (role == 'society_head') {
      return 'Society Head';
    } else if (role == 'admin') {
      return 'Admin';
    } else {
      return 'Student';
    }
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
}
