import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/shared/config.dart';
import 'package:app/shared/services/shared_preferences_service.dart';
import 'package:app/shared/widgets/dialogs/toast_manager.dart';
import 'package:app/shared/widgets/dialogs/custom_glass_dialog.dart';
import 'package:intl/intl.dart';

class AdminPostManagementScreen extends StatefulWidget {
  const AdminPostManagementScreen({super.key});

  @override
  State<AdminPostManagementScreen> createState() => _AdminPostManagementScreenState();
}

class _AdminPostManagementScreenState extends State<AdminPostManagementScreen> {
  bool _isLoading = true;
  List<dynamic> _posts = [];
  String? _currentUserRole;
  late ScrollController _scrollController;

  String _searchQuery = '';
  String _selectedTypeFilter = 'All';
  String _sortBy = 'Date';
  bool _sortAsc = false; // default newest first

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadCurrentUserRole();
    _fetchPosts();
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

  Future<void> _fetchPosts() async {
    try {
      final token = await SharedPreferencesService.getToken();
      final response = await http.get(
        Uri.parse('${Config.BASE_URL}/api/posts'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _posts = data['posts'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Failed to fetch posts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePost(String postId) async {
    try {
      final token = await SharedPreferencesService.getToken();
      final response = await http.delete(
        Uri.parse('${Config.BASE_URL}/api/posts/$postId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        EduMateToast.showCompact(context, message: 'Post deleted successfully', isSuccess: true);
        _fetchPosts();
      } else {
        EduMateToast.showCompact(context, message: 'Failed to delete post', isSuccess: false);
      }
    } catch (e) {
      EduMateToast.showCompact(context, message: 'Error deleting post', isSuccess: false);
    }
  }

  Future<void> _showDeleteConfirm(BuildContext context, String postId) async {
    if (_currentUserRole != 'admin') {
      EduMateToast.showCompact(context, message: 'Only Admins can delete posts', isSuccess: false);
      return;
    }

    final bool? confirm = await showDeleteConfirmationDialog(
      context: context,
      title: 'Delete Post',
      description: 'Are you sure you want to delete this post? This action cannot be undone.',
    );

    if (confirm == true) {
      _deletePost(postId);
    }
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final filteredPosts = _posts.where((post) {
      final body = post['body']?.toString().toLowerCase() ?? '';
      final authorUsername = post['authorUsername']?.toString().toLowerCase() ?? '';
      
      final author = post['author'];
      final authorName = (author != null ? '${author['firstName']} ${author['lastName']}' : '').toLowerCase();
      
      final matchesSearch = body.contains(_searchQuery.toLowerCase()) || 
                            authorUsername.contains(_searchQuery.toLowerCase()) ||
                            authorName.contains(_searchQuery.toLowerCase());
      
      final type = post['postType']?.toString().toLowerCase() ?? '';
      final matchesFilter = _selectedTypeFilter == 'All' || 
                            (_selectedTypeFilter == 'News' && type == 'news') ||
                            (_selectedTypeFilter == 'Event' && type == 'event');
      return matchesSearch && matchesFilter;
    }).toList();

    filteredPosts.sort((a, b) {
      final dateA = a['createdAt'] != null ? DateTime.tryParse(a['createdAt'].toString()) : DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = b['createdAt'] != null ? DateTime.tryParse(b['createdAt'].toString()) : DateTime.fromMillisecondsSinceEpoch(0);
      if (dateA != null && dateB != null) {
        final res = dateB.compareTo(dateA); // newest first default
        return _sortAsc ? -res : res;
      }
      return 0;
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
                              tag: 'back_button_post_management',
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.pop(context),
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
                                'Post Management',
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
                                  placeholder: 'Search by content or author...',
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
                                      _sortAsc = false; // default newest first for Date
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
                                        '$_sortBy ${_sortAsc ? '↑' : '↓'}',
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
                                  const PopupMenuItem(value: 'Date', child: Text('Sort by Date')),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PopupMenuButton<String>(
                                initialValue: _selectedTypeFilter,
                                onSelected: (value) {
                                  setState(() {
                                    _selectedTypeFilter = value;
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
                                        _selectedTypeFilter == 'All' ? 'Filter Type' : _selectedTypeFilter,
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
                                  const PopupMenuItem(value: 'All', child: Text('All Posts')),
                                  const PopupMenuItem(value: 'News', child: Text('News')),
                                  const PopupMenuItem(value: 'Event', child: Text('Events')),
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
                          final post = filteredPosts[index];
                          final author = post['author'];
                          final authorName = author != null ? '${author['firstName']} ${author['lastName']}' : 'Unknown';
                          final date = DateTime.tryParse(post['createdAt']?.toString() ?? '') ?? DateTime.now();
                          final String postType = post['postType']?.toString().toLowerCase() ?? 'news';
                          final String body = post['body']?.toString() ?? 'No content';
                          final String? imageUrl = post['imageUrl'];
                          final eventDetails = post['eventDetails'];
                          
                          final bool isEvent = postType == 'event';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141110),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isEvent 
                                            ? Colors.orange.withOpacity(0.2) 
                                            : Colors.blue.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isEvent ? 'EVENT' : 'NEWS',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isEvent ? Colors.orange : Colors.blue,
                                        ),
                                      ),
                                    ),
                                    if (_currentUserRole == 'admin')
                                      GestureDetector(
                                        onTap: () => _showDeleteConfirm(context, post['_id']),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: CupertinoColors.destructiveRed.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed, size: 18),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      imageUrl,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                Text(
                                  body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
                                ),
                                
                                if (isEvent && eventDetails != null && eventDetails['startDate'] != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(CupertinoIcons.calendar, size: 14, color: CupertinoColors.systemGrey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          DateFormat('MMM d, yyyy').format(DateTime.parse(eventDetails['startDate'].toString())),
                                          style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                const SizedBox(height: 12),
                                const Divider(color: Colors.white12),
                                const SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'By $authorName (@${post['authorUsername'] ?? 'unknown'})',
                                        style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      _timeAgo(date),
                                      style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: filteredPosts.length,
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
