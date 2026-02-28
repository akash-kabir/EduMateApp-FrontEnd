import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/shared_preferences_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import 'event_card.dart';
import 'create_post_screen.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  String userRole = 'student';
  List<dynamic> posts = [];
  bool isLoading = true;
  String selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchPosts();
  }

  Future<void> _loadUserRole() async {
    final role = await SharedPreferencesService.getUserRole() ?? 'student';
    setState(() {
      userRole = role;
    });
  }

  Future<void> _fetchPosts() async {
    setState(() => isLoading = true);

    try {
      final token = await SharedPreferencesService.getToken();

      String url = '${Config.postsEndpoint}';
      if (selectedFilter != 'all') {
        url += '?postType=$selectedFilter';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          posts = data['posts'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Failed to load posts')));
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showFilterDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 300,
        padding: const EdgeInsets.only(top: 6.0),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () {
                      _fetchPosts();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: _getFilterIndex(selectedFilter),
                  ),
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      selectedFilter = ['all', 'news', 'event'][index];
                    });
                  },
                  children: const [
                    Center(child: Text('All Posts')),
                    Center(child: Text('News Only')),
                    Center(child: Text('Events Only')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getFilterIndex(String filter) {
    switch (filter) {
      case 'news':
        return 1;
      case 'event':
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSocietyHead = userRole.toLowerCase() == 'society_head';

    return CupertinoPageScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            automaticallyImplyLeading: false,
            largeTitle: const Text('Events & News'),
            backgroundColor: isDark
                ? CupertinoColors.black.withOpacity(0.6)
                : CupertinoColors.white.withOpacity(0.6),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _fetchPosts,
              child: Icon(
                CupertinoIcons.refresh,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSocietyHead)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const CreatePostScreen(),
                        ),
                      );
                      if (result == true) {
                        _fetchPosts();
                      }
                    },
                    child: const Icon(
                      CupertinoIcons.add_circled_solid,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _showFilterDialog,
                  child: Icon(
                    CupertinoIcons.slider_horizontal_3,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            SliverFillRemaining(
              child: Center(
                child: CupertinoActivityIndicator(radius: 15, animating: true),
              ),
            )
          else if (posts.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'No posts available',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  return EventCard(post: posts[index], onRefresh: _fetchPosts);
                },
              ),
            ),
        ],
      ),
    );
  }
}
