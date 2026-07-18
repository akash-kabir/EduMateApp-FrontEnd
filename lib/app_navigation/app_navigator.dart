import 'package:flutter/material.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/event/event_screen.dart';
import '../screens/home/home_screen.dart';
import '../services/shared_preferences_service.dart';
import 'nav_bar.dart';

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  int _selectedIndex = 0;
  bool _slideFromRight = true;
  bool _isMapNavBarVisible = true;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadInitialPage();
    _pages = [
      _HomeScreenWrapper(onNavigate: _onItemTapped),
      const ScheduleScreen(),
      const EventScreen(),
      MapScreen(onNavBarVisibilityChange: (visible) {
        if (mounted && _isMapNavBarVisible != visible) {
          setState(() {
            _isMapNavBarVisible = visible;
          });
        }
      }),
    ];
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _slideFromRight = index > _selectedIndex;
      _selectedIndex = index;
    });
  }

  void _loadInitialPage() async {
    final openTimesheet = await SharedPreferencesService.getBool('openToTimesheet');
    if (openTimesheet && mounted) {
      setState(() {
        _selectedIndex = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          final isIncoming = child.key == ValueKey<int>(_selectedIndex);
          
          if (isIncoming) {
            final offsetBegin = _slideFromRight
                ? const Offset(1.0, 0.0)
                : const Offset(-1.0, 0.0);
            final offsetAnimation = Tween<Offset>(
              begin: offsetBegin,
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));
            
            return SlideTransition(
              position: offsetAnimation,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: child,
              ),
            );
          } else {
            // Outgoing screen remains stationary and fully visible underneath
            return child;
          }
        },
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: Duration(milliseconds: _isMapNavBarVisible ? 250 : 800),
        curve: Curves.easeInOut,
        offset: (_selectedIndex == 3 && !_isMapNavBarVisible)
            ? const Offset(0, 1.2) // slide down below the screen
            : Offset.zero,
        child: CupertinoBottomTabBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }
}

// Wrapper to pass navigation callbacks into HomeScreen
class _HomeScreenWrapper extends StatelessWidget {
  final Function(int) onNavigate;

  const _HomeScreenWrapper({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      onNavigateToEvent: () => onNavigate(2),
      onNavigateToSchedule: () => onNavigate(1),
    );
  }
}
