import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/shared_preferences_service.dart';
import '../../services/token_refresh_service.dart';
import 'dart:convert';
import '../../config.dart';
import 'event_card.dart';
import 'create_post_screen.dart';

import '../../widgets/toast_manager.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  List<dynamic> posts = [];
  bool isLoading = true;
  String selectedFilter = 'all';
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchPosts();
  }

  Future<void> _loadUserRole() async {
    final role = await SharedPreferencesService.getUserRole();
    setState(() {
      userRole = role;
    });
  }

  Future<void> _fetchPosts() async {
    setState(() => isLoading = true);

    try {
      String url = '${Config.postsEndpoint}';
      if (selectedFilter != 'all') {
        url += '?postType=$selectedFilter';
      }

      final response = await TokenRefreshService.authenticatedGet(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          posts = data['posts'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          EduMateToast.showCompact(
            context,
            message: 'Failed to load posts',
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        EduMateToast.showCompact(
          context,
          message: 'Error: $e',
          isSuccess: false,
        );
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
                  children: [
                    const Center(child: Text('All Posts')),
                    Center(
                      child: Text(
                        'News Only',
                        style: TextStyle(fontFamily: 'Salena'),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Events Only',
                        style: TextStyle(fontFamily: 'Salena'),
                      ),
                    ),
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
    final isSocietyHead = userRole?.toLowerCase() == 'society_head';

    return CupertinoPageScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            automaticallyImplyLeading: false,
            largeTitle: Text(
              'Events & News',
              style: TextStyle(
                fontFamily: 'Salena',
                fontWeight: FontWeight.bold,
              ),
            ),
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
                      color: Color(0xFFFF9B7A),
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
              padding: const EdgeInsets.only(bottom: 100),
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
