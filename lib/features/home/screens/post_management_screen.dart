import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/shared/config.dart';
import 'package:app/shared/services/shared_preferences_service.dart';
import 'package:app/shared/widgets/dialogs/toast_manager.dart';
import 'package:app/shared/widgets/dialogs/custom_glass_dialog.dart';
import 'package:app/theme/theme.dart';
import 'package:app/shared/widgets/skeletons/skeleton_loading_card.dart';

class PostManagementScreen extends StatefulWidget {
  const PostManagementScreen({super.key});

  @override
  State<PostManagementScreen> createState() => _PostManagementScreenState();
}

class _PostManagementScreenState extends State<PostManagementScreen> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMyPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await SharedPreferencesService.getToken();
      final userId = await SharedPreferencesService.getUserId();
      
      if (token == null || userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('${Config.postsEndpoint}?author=$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _posts = data['posts'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('SocketException') 
            ? 'No internet connection' 
            : 'Error loading posts';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePost(String postId) async {
    final confirm = await showConfirmationDialog(
      context: context,
      title: 'Delete Post',
      description: 'Are you sure you want to delete this post? This action cannot be undone.',
      confirmButtonText: 'Delete',
      iconData: CupertinoIcons.delete,
      primaryColor: CupertinoColors.systemRed,
    );

    if (confirm != true) return;

    try {
      final token = await SharedPreferencesService.getToken();
      final response = await http.delete(
        Uri.parse('${Config.postsEndpoint}/$postId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          EduMateToast.showCompact(context, message: 'Post deleted successfully', isSuccess: true);
          setState(() {
            _posts.removeWhere((post) => post['_id'] == postId);
          });
        }
      } else {
        throw Exception('Failed to delete post');
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(context, message: 'Error deleting post', isSuccess: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _scrollController,
              builder: (context, child) {
                final fadeIntensity = _scrollController.hasClients ? (_scrollController.offset / 40.0).clamp(0.0, 1.0) : 0.0;
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
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                      child: Stack(
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
                                  child: const Icon(CupertinoIcons.back, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const Text(
                            'Manage Posts',
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
                    ),
                  ),
                  
                  if (_isLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: SkeletonLoadingList(),
                      ),
                    )
                  else if (_errorMessage != null)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: Colors.white54),
                            const SizedBox(height: 16),
                            Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 16),
                            CupertinoButton(
                              onPressed: _fetchMyPosts,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_posts.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'You have not created any posts yet.',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final post = _posts[index];
                            return _buildPostCard(post);
                          },
                          childCount: _posts.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(dynamic post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF141110),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['title'] ?? 'No Title',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  post['body'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post['postType']?.toString().toUpperCase() ?? 'POST',
                  style: const TextStyle(
                    color: AuthPalette.coral,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _deletePost(post['_id']),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(CupertinoIcons.delete, color: Colors.red, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
