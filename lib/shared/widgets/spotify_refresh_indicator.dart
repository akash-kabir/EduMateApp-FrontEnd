import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

class SpotifyRefreshState extends ChangeNotifier {
  double dragOffset = 0.0;
  bool isRefreshing = false;
  bool isRetracting = false; 
  final double threshold = 100.0; // New activation threshold
  final Future<void> Function() onRefresh;

  SpotifyRefreshState({required this.onRefresh});

  void addDrag(double delta) {
    if (isRefreshing || isRetracting) return;
    
    // Hard clamp to prevent infinite scrolling off-screen
    dragOffset += delta;
    if (dragOffset < 0) {
      dragOffset = 0;
    } else if (dragOffset > 140) {
      dragOffset = 140; // New max limit
    }
    
    notifyListeners();
  }

  void releaseDrag() async {
    if (isRefreshing || isRetracting || dragOffset == 0) return;

    if (dragOffset >= threshold) {
      isRefreshing = true;
      isRetracting = true;
      dragOffset = 120.0; // Snap to 120 pixels while loading
      notifyListeners();

      try {
        await onRefresh();
      } finally {
        isRefreshing = false;
        isRetracting = true;
        dragOffset = 0.0;
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 300));
        isRetracting = false;
      }
      return;
    }
    
    // Didn't reach threshold, retract
    isRetracting = true;
    dragOffset = 0.0;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    isRetracting = false;
  }

  Future<void> show() async {
    if (isRefreshing || isRetracting) return;
    
    isRefreshing = true;
    isRetracting = true; // Use retracting state to animate the drop down smoothly
    dragOffset = 120.0;
    notifyListeners();

    try {
      await onRefresh();
    } finally {
      isRefreshing = false;
      isRetracting = true;
      dragOffset = 0.0;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 300));
      isRetracting = false;
    }
  }
}

class SpotifyRefreshPhysics extends ScrollPhysics {
  final SpotifyRefreshState refreshState;

  const SpotifyRefreshPhysics(this.refreshState, {ScrollPhysics? parent})
      : super(parent: parent);

  @override
  SpotifyRefreshPhysics applyTo(ScrollPhysics? ancestor) {
    return SpotifyRefreshPhysics(refreshState, parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    return true; // Always allow drag to ensure pull-to-refresh works even on short/empty lists
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (position.pixels <= 0.0) {
      if (offset > 0) {
        // Dragging down at the top edge
        refreshState.addDrag(offset * 0.6); // 0.6 adds a bit of natural friction
        return 0.0; // Completely swallow the scroll so the list doesn't move
      } else if (offset < 0 && refreshState.dragOffset > 0) {
        // Pushing back up while the icon is pulled down
        refreshState.addDrag(offset * 0.6);
        return 0.0; // Completely swallow the scroll!
      }
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }

  // We leave createBallisticSimulation to normal because we rely on ScrollEndNotification now
}

class SpotifyRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color color;
  final double edgeOffset;

  const SpotifyRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color = const Color(0xFF4CD97B),
    this.edgeOffset = 0.0,
  });

  @override
  SpotifyRefreshIndicatorState createState() => SpotifyRefreshIndicatorState();
}

class SpotifyRefreshIndicatorState extends State<SpotifyRefreshIndicator> {
  late SpotifyRefreshState _refreshState;

  Future<void> show() async {
    await _refreshState.show();
  }

  @override
  void initState() {
    super.initState();
    _refreshState = SpotifyRefreshState(onRefresh: widget.onRefresh);
  }

  @override
  void dispose() {
    _refreshState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        // 100% reliable way to detect when the user lets go of the screen
        if (notification is ScrollEndNotification) {
          _refreshState.releaseDrag();
        }
        return false;
      },
      child: Stack(
        children: [
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              physics: SpotifyRefreshPhysics(
                _refreshState,
                parent: const ClampingScrollPhysics(),
              ),
            ),
            child: widget.child,
          ),

          AnimatedBuilder(
            animation: _refreshState,
            builder: (context, child) {
              final offset = _refreshState.dragOffset;
              final isRefreshing = _refreshState.isRefreshing;
              final isRetracting = _refreshState.isRetracting;
              final threshold = _refreshState.threshold;
              
              final percentage = (offset / threshold).clamp(0.0, 1.0);
              
              // Map the drag offset to screen position.
              // Max drag is 140, so max visual offset is 140 * 0.8 = 112
              final double topPosition;
              if (offset == 0.0 && !isRefreshing && !isRetracting) {
                topPosition = widget.edgeOffset - 100.0; // Hidden completely off-screen
              } else {
                topPosition = widget.edgeOffset + (offset * 0.8) - 40.0;
              }

              // Visual feedback when threshold is met
              final bool thresholdMet = offset >= threshold;

              return AnimatedPositioned(
                duration: isRetracting 
                    ? const Duration(milliseconds: 300) 
                    : const Duration(milliseconds: 0), 
                curve: Curves.easeOutCubic,
                top: topPosition,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: thresholdMet 
                              ? widget.color.withValues(alpha: 0.6) // Glow green when ready
                              : Colors.black45,
                          blurRadius: thresholdMet ? 15 : 10,
                          spreadRadius: thresholdMet ? 2 : 0,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: isRefreshing
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: widget.color,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Opacity(
                            opacity: percentage,
                            child: Transform.scale(
                              scale: 0.5 + (percentage * 0.5),
                              child: Transform.rotate(
                                angle: percentage * 3.14 * 2,
                                child: Icon(
                                  Icons.sync, // Use Material sync icon instead of Cupertino
                                  color: widget.color,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
