import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/shared/services/shared_preferences_service.dart';
import 'package:app/features/auth_and_profile/services/token_refresh_service.dart';
import 'dart:convert';
import 'package:app/shared/config.dart';
import 'package:app/features/events/widgets/event_card.dart';
import 'package:app/features/events/screens/create_post_screen.dart';

import 'package:app/shared/widgets/dialogs/toast_manager.dart';
import 'package:app/shared/widgets/skeletons/skeleton_event_card.dart';

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

  double _dragOffset = 0.0;
  bool _isRefreshing = false;
  bool _isFlashing = false;
  final double _refreshThreshold = 80.0;

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

  Future<void> _fetchPosts({bool showSkeleton = true}) async {
    if (mounted && showSkeleton) setState(() => isLoading = true);

    try {
      String url = Config.postsEndpoint;
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

  Future<void> _handleRefresh() async {
    if (_isRefreshing || isLoading) return;

    setState(() {
      _isRefreshing = true;
      _dragOffset = _refreshThreshold;
    });

    await _fetchPosts(showSkeleton: false);

    if (mounted) {
      setState(() {
        _isFlashing = true;
        _isRefreshing = false;
        _dragOffset = 0.0;
      });
    }

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isFlashing = false;
      });
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (_isRefreshing || isLoading || _isFlashing) return false;

    if (notification is OverscrollNotification && notification.overscroll < 0) {
      setState(() {
        _dragOffset += notification.overscroll.abs();
      });
    } else if (notification is ScrollUpdateNotification) {
      if (notification.metrics.pixels <= 0 && notification.scrollDelta != null && notification.scrollDelta! < 0) {
        setState(() {
          _dragOffset += notification.scrollDelta!.abs();
        });
      } else if (notification.metrics.pixels > 0 && _dragOffset > 0) {
        setState(() {
          _dragOffset = 0.0;
        });
      }
    } else if (notification is ScrollEndNotification) {
      if (_dragOffset >= _refreshThreshold) {
        _handleRefresh();
      } else {
        setState(() { _dragOffset = 0.0; });
      }
    }
    return false;
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
    final canPost =
        userRole != null &&
        [
          'society',
          'contributor',
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
        backgroundColor: CupertinoColors.black.withValues(alpha: 0.6),
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
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
              if (_isFlashing || isLoading)
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
                      color: Colors.white70,
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
      if (_dragOffset > 0 || _isRefreshing || _isFlashing)
        Positioned(
          top: MediaQuery.of(context).padding.top + 44.0,
          left: 0,
          right: 0,
          child: _isRefreshing || _isFlashing
              ? const LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9B7A)),
                  minHeight: 3,
                )
              : Container(
                  height: 3,
                  alignment: Alignment.center,
                  child: FractionallySizedBox(
                    widthFactor: (_dragOffset / _refreshThreshold).clamp(0.0, 1.0),
                    child: Container(
                      color: const Color(0xFFFF9B7A),
                    ),
                  ),
                ),
        ),
      ],
    ),
      ),
    );
  }
}
