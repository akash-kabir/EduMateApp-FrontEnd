import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/shared_preferences_service.dart';
import '../../services/token_refresh_service.dart';
import 'dart:convert';
import '../../config.dart';
import 'event_card.dart';
import 'create_post_screen.dart';

import '../../widgets/toast_manager.dart';
import '../../widgets/skeleton_event_card.dart';

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
    if (mounted) {
      setState(() {
        userRole = role;
      });
    }
  }

  Future<void> _fetchPosts() async {
    if (mounted) setState(() => isLoading = true);

    try {
      String url = '${Config.postsEndpoint}';
      if (selectedFilter != 'all') {
        url += '?postType=$selectedFilter';
      }

      final response = await TokenRefreshService.authenticatedGet(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            posts = data['posts'] ?? [];
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
        if (mounted) {
          EduMateToast.showCompact(
            context,
            message: 'Failed to load posts',
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
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
    final canPost =
        userRole != null &&
        [
          'societ',
          'society',
          'society_head',
          'contributer',
          'contributor',
          'admin',
        ].contains(userRole!.toLowerCase());

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        middle: const Text(
          'Events & News',
          style: TextStyle(
            fontFamily: 'Salena',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark
            ? CupertinoColors.black.withOpacity(0.6)
            : CupertinoColors.white.withOpacity(0.6),
        leading: canPost
            ? CupertinoButton(
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
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
      child: RefreshIndicator(
        onRefresh: () async {
          await _fetchPosts();
        },
        edgeOffset: MediaQuery.of(context).padding.top + 44.0,
        color: const Color(0xFFFF9B7A),
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
          if (isLoading)
            SliverPadding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 60.0),
              sliver: const SliverFillRemaining(
                child: SkeletonEventList(),
              ),
            )
          else if (posts.isEmpty)
            SliverPadding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 60.0),
              sliver: SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No posts available',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 60.0,
                bottom: 100,
              ),
              sliver: SliverList.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  return EventCard(post: posts[index], onRefresh: _fetchPosts);
                },
              ),
            ),
        ],
      ),
      ),
    );
  }
}
