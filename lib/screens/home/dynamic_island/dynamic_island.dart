import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'states/minimized/minimized_state.dart';
import 'states/normal/normal_state.dart';
import 'states/maximized/maximized_state.dart';
import 'states/profile_setup/profile_setup_state.dart';

enum DynamicIslandState { minimized, normal, maximized, profileSetup }

class DynamicIsland extends StatefulWidget {
  final String greeting;
  final String userName;
  final bool isDark;
  final bool showProfileSetup;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNavigateToEvent;
  final VoidCallback? onNavigateToSchedule;
  final VoidCallback? onProfileSetupComplete;

  const DynamicIsland({
    super.key,
    required this.greeting,
    required this.userName,
    required this.isDark,
    this.showProfileSetup = false,
    this.onProfileTap,
    this.onNavigateToEvent,
    this.onNavigateToSchedule,
    this.onProfileSetupComplete,
  });

  @override
  State<DynamicIsland> createState() => _DynamicIslandState();
}

class _DynamicIslandState extends State<DynamicIsland>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _buttonOpacity;
  late Animation<double> _normalStateOpacity;
  late Animation<double> _maximizedStateOpacity;
  DynamicIslandState _currentState = DynamicIslandState.minimized;

  @override
  void initState() {
    super.initState();

    if (widget.showProfileSetup) {
      _currentState = DynamicIslandState.profileSetup;
    } else {
      _currentState = DynamicIslandState.normal;
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _buttonOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );
    _normalStateOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );
    _maximizedStateOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void didUpdateWidget(DynamicIsland oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update internal state if showProfileSetup changed
    if (oldWidget.showProfileSetup != widget.showProfileSetup) {
      setState(() {
        if (widget.showProfileSetup) {
          _currentState = DynamicIslandState.profileSetup;
        } else {
          _currentState = DynamicIslandState.normal;
          _animationController.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleState() {
    setState(() {
      if (_currentState == DynamicIslandState.minimized) {
        _currentState = DynamicIslandState.maximized;
        _animationController.forward();
      } else if (_currentState == DynamicIslandState.normal) {
        _currentState = DynamicIslandState.maximized;
        _animationController.forward();
      } else if (_currentState == DynamicIslandState.maximized) {
        _currentState = DynamicIslandState.minimized;
        _animationController.reverse();
      }
    });
  }

  double _getHeight() {
    switch (_currentState) {
      case DynamicIslandState.minimized:
        return 80;
      case DynamicIslandState.normal:
        return 140;
      case DynamicIslandState.maximized:
        return 380;
      case DynamicIslandState.profileSetup:
        return 150;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: GestureDetector(
        onTap: _toggleState,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              height: _getHeight(),
              width: double.infinity,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? const Color(0xFF0F0F11)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.only(
                top: _currentState == DynamicIslandState.minimized
                    ? 12.0
                    : 24.0,
                bottom: 8.0,
                left: 8.0,
                right: 8.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: _currentState == DynamicIslandState.minimized
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_currentState ==
                              DynamicIslandState.minimized) ...[
                            MinimizedState(isDark: widget.isDark),
                          ] else if (_currentState ==
                              DynamicIslandState.normal) ...[
                            NormalState(
                              normalStateOpacity: _normalStateOpacity,
                              greeting: widget.greeting,
                              userName: widget.userName,
                              isDark: widget.isDark,
                            ),
                          ] else if (_currentState ==
                              DynamicIslandState.maximized) ...[
                            MaximizedState(
                              maximizedStateOpacity: _maximizedStateOpacity,
                              buttonOpacity: _buttonOpacity,
                              isDark: widget.isDark,
                              onProfileTap: widget.onProfileTap,
                              onNavigateToEvent: widget.onNavigateToEvent,
                              onNavigateToSchedule: widget.onNavigateToSchedule,
                            ),
                          ] else if (_currentState ==
                              DynamicIslandState.profileSetup) ...[
                            ProfileSetupState(
                              isDark: widget.isDark,
                              onSkip: () {
                                setState(() {
                                  _currentState = DynamicIslandState.minimized;
                                  _animationController.reverse();
                                });
                              },
                              onComplete: widget.onProfileSetupComplete,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_currentState == DynamicIslandState.maximized)
                    const SizedBox.shrink(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
