import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config.dart';
import '../../../services/shared_preferences_service.dart';
import '../../../widgets/toast_manager.dart';


class AdminPostManagementScreen extends StatefulWidget {
  const AdminPostManagementScreen({super.key});

  @override
  State<AdminPostManagementScreen> createState() => _AdminPostManagementScreenState();
}

class _AdminPostManagementScreenState extends State<AdminPostManagementScreen> {
  bool _isLoading = true;
  List<dynamic> _posts = [];
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserRole();
    _fetchPosts();
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

  void _showDeleteConfirm(BuildContext context, String postId) {
    if (_currentUserRole != 'admin') {
      EduMateToast.showCompact(context, message: 'Only Admins can delete posts', isSuccess: false);
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _deletePost(postId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? CupertinoColors.black.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
        middle: const Text('Post Management'),
        previousPageTitle: 'Settings',
      ),
      child: SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  final author = post['author'];
                  final authorName = author != null ? '${author['firstName']} ${author['lastName']}' : 'Unknown';
                  final date = DateTime.parse(post['createdAt']);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              post['postType'].toString().toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: post['postType'] == 'event' ? Colors.orange : Colors.blue,
                              ),
                            ),
                            if (_currentUserRole == 'admin')
                              GestureDetector(
                                onTap: () => _showDeleteConfirm(context, post['_id']),
                                child: const Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed, size: 20),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post['heading'] ?? 'No Title',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'By $authorName • ${_timeAgo(date)}',
                          style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
      ),
    );
  }
}
