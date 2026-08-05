import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:app/shared/config.dart';
import 'package:app/theme/theme.dart';
import 'package:app/shared/services/shared_preferences_service.dart';

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
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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

    _loadEffectiveRole();
    _fetchProfileData();
  }

  Future<void> _loadEffectiveRole() async {
    final role = await SharedPreferencesService.getUserRole();
    if (role != null && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          profileData = data['data'] ?? data;
          isLoading = false;
        });
        _animController.forward();
      } else {
        throw Exception('Failed to load profile data');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        final cachedData = await _buildProfileFromCache();
        if (cachedData != null) {
          if (mounted) {
            setState(() {
              profileData = cachedData;
              isLoading = false;
            });
            _animController.forward();
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          error = e.toString().contains('SocketException')
              ? 'No internet connection. Please try again.'
              : 'Error: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _buildProfileFromCache() async {
    final firstName = await SharedPreferencesService.getFirstName();
    if (firstName == null) return null; // No valid cache exists
    
    return {
      'firstName': firstName,
      'lastName': await SharedPreferencesService.getLastName(),
      'username': await SharedPreferencesService.getUserName(),
      'email': await SharedPreferencesService.getUserEmail(),
      'role': await SharedPreferencesService.getUserRole(),
      'rollNo': await SharedPreferencesService.getRollNo(),
      'branch': await SharedPreferencesService.getBranch(),
      'section': await SharedPreferencesService.getSection(),
      'year': await SharedPreferencesService.getYear(),
      'semester': await SharedPreferencesService.getSemester(),
      'isProfileCompleted': await SharedPreferencesService.getIsProfileCompleted(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = AuthPalette.coral;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CupertinoActivityIndicator(radius: 16))
            : error != null
                ? _buildErrorState()
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildMainLayout(accentColor),
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 48,
              color: Colors.white38,
            ),
            const SizedBox(height: 16),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white60,
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

  Widget _buildMainLayout(Color accentColor) {
    return Stack(
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
                parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Hero(
                              tag: 'back_button',
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF141110),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(CupertinoIcons.back,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'Salena',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Color(0xFFFF9B7A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Streamlined Header
                      _buildProfileHeader(accentColor),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickStats(accentColor),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Personal Information', CupertinoIcons.person_fill),
                      const SizedBox(height: 12),
                      _buildGroupedCard([
                        _InfoRow(icon: CupertinoIcons.mail, label: 'Email', value: profileData?['email'] ?? 'N/A'),
                        _InfoRow(icon: CupertinoIcons.number, label: 'Roll Number', value: profileData?['rollNo'] ?? 'N/A'),
                      ]),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Academic Information', CupertinoIcons.book_fill),
                      const SizedBox(height: 12),
                      _buildGroupedCard([
                        _InfoRow(icon: CupertinoIcons.rectangle_grid_1x2, label: 'Section', value: profileData?['section'] ?? 'N/A'),
                        _InfoRow(icon: CupertinoIcons.calendar, label: 'Year', value: profileData?['year'] ?? 'N/A'),
                      ]),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Account', CupertinoIcons.shield_fill),
                      const SizedBox(height: 12),
                      _buildGroupedCard([
                        _InfoRow(icon: CupertinoIcons.star_fill, label: 'Role', value: _formatRole(profileData?['role'] ?? 'student')),
                        _InfoRow(icon: CupertinoIcons.checkmark_seal_fill, label: 'Profile Status', value: (profileData?['isProfileCompleted'] == true) ? 'Complete' : 'Incomplete'),
                      ]),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(Color accentColor) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF141110),
            border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 2),
          ),
          child: Center(
            child: Text(
              _getInitials(),
              style: TextStyle(
                color: accentColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _getFullName(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        if (profileData?['username'] != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF141110),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '@${profileData!['username']}',
              style: TextStyle(
                fontSize: 14,
                color: accentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          profileData?['email'] ?? '',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(Color accentColor) {
    final branch = profileData?['branch'] ?? '—';
    final semester = profileData?['semester']?.toString() ?? '—';

    return Row(
      children: [
        Expanded(child: _buildStatChip(branch, 'Branch', accentColor)),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatChip(semester, 'Semester', accentColor),
        ),
      ],
    );
  }

  Widget _buildStatChip(String value, String label, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141110),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: accentColor),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white54),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white54,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedCard(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141110),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(rows.length, (index) {
          final row = rows[index];
          final isLast = index == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AuthPalette.coral.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(row.icon, size: 17, color: AuthPalette.coral),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.label,
                            style: const TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            row.value,
                            style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
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
                    color: Colors.white.withValues(alpha: 0.06),
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
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  }

  String _getFullName() {
    final firstName = profileData?['firstName'] ?? '';
    final lastName = profileData?['lastName'] ?? '';
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : 'User';
  }

  String _formatRole(String role) {
    final r = role.toLowerCase();
    if (r == 'society' || r == 'societ' || r == 'society head' || r == 'society_head') {
      return 'Society';
    } else if (r == 'admin') {
      return 'Admin';
    } else if (r == 'contributor' || r == 'contributor') {
      return 'contributor';
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
