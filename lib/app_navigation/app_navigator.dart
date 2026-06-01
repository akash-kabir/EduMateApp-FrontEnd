import 'package:flutter/material.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/event/event_screen.dart';
import '../screens/home/home_screen.dart';
import 'nav_bar.dart';

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  int _selectedIndex = 0;
  bool _slideFromRight = true;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _HomeScreenWrapper(onNavigate: _onItemTapped),
      const ScheduleScreen(),
      const EventScreen(),
      const MapScreen(),
    ];
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _slideFromRight = index > _selectedIndex;
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          final offsetBegin = _slideFromRight
              ? const Offset(1.0, 0.0)
              : const Offset(-1.0, 0.0);
          final offsetAnimation = Tween<Offset>(
            begin: offsetBegin,
            end: Offset.zero,
          ).animate(animation);
          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(opacity: animation, child: child),
          );
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
      bottomNavigationBar: CupertinoBottomTabBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
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
