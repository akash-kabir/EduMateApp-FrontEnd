import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/event/event_screen.dart';
import '../screens/home/home_screen.dart';
import '../services/shared_preferences_service.dart';
import '../services/map_navigation_store.dart';
import '../widgets/custom_glass_dialog.dart';
import '../constants/app_constants.dart';
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
  String _userRole = '';

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadInitialPage();
    MapNavigationStore.instance.tabChangeNotifier.addListener(_onTabChangeRequested);
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

  void _onTabChangeRequested() {
    final targetIndex = MapNavigationStore.instance.tabChangeNotifier.value;
    if (targetIndex != null) {
      _onItemTapped(targetIndex);
    }
  }

  @override
  void dispose() {
    MapNavigationStore.instance.tabChangeNotifier.removeListener(_onTabChangeRequested);
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    // Restrict Guests from Events (2) and Map (3)
    if (_userRole == 'guest' && (index == 2 || index == 3)) {
      _showGuestRestrictionDialog();
      return;
    }

    setState(() {
      _slideFromRight = index > _selectedIndex;
      _selectedIndex = index;
    });
  }

  void _showGuestRestrictionDialog() {
    showGlassmorphicDialog(
      context: context,
      barrierDismissible: true,
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.0,
                height: 64.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AuthPalette.coral.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AuthPalette.coral.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.lock_fill,
                  color: AuthPalette.coral,
                  size: 32.0,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Access Restricted',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Map and Events are only available to registered students. Sign up to unlock full access!',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14.0,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthPalette.coral,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _loadInitialPage() async {
    final role = await SharedPreferencesService.getUserRole();
    if (mounted) {
      setState(() {
        _userRole = role?.toLowerCase() ?? '';
      });
    }

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
