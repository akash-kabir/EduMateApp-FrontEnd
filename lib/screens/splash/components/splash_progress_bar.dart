import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../services/shared_preferences_service.dart';

class SplashProgressBar extends StatefulWidget {
  final Function(double) onProgressUpdate;
  final VoidCallback onLoadingComplete;

  const SplashProgressBar({
    super.key,
    required this.onProgressUpdate,
    required this.onLoadingComplete,
  });

  @override
  State<SplashProgressBar> createState() => _SplashProgressBarState();
}

class _SplashProgressBarState extends State<SplashProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _startLoadingSequence();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startLoadingSequence() async {
    try {
      // Get user data from SharedPreferencesService
      final userId = await SharedPreferencesService.getUserId();
      final token = await SharedPreferencesService.getToken();

      if (userId == null || token == null) {
        _finishLoading();
        return;
      }

      // Step 1: Update progress to 20% (simulating initial data load)
      _updateProgress(0.2);
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 2: Fetch full user profile from backend (50% progress)
      _updateProgress(0.5);
      await _getUserProfile(token: token);

      // Step 3: Update progress to 80%
      _updateProgress(0.8);
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 4: Complete progress (100%)
      _updateProgress(1.0);
      await Future.delayed(const Duration(milliseconds: 300));

      _finishLoading();
    } catch (e) {
      // On error, still finish loading
      _finishLoading();
    }
  }

  void _updateProgress(double newProgress) {
    setState(() {
      _progress = newProgress;
    });
    widget.onProgressUpdate(newProgress);
  }

  Future<void> _getUserProfile({required String token}) async {
    try {
      final result = await ApiService.getUserProfile(token: token);

      if (result['success'] ?? false) {
        if (result['data'] != null) {
          final data = result['data'];
          // The getUserProfile response wraps user data in 'data' key
          final userData =
              data is Map<String, dynamic> && data.containsKey('data')
              ? data['data'] as Map<String, dynamic>
              : data as Map<String, dynamic>;

          // Save full user profile to SharedPreferences
          await SharedPreferencesService.saveFullUserProfile(userData);

          // If profile is completed, also save branch/section for timesheet
          if (userData['isProfileCompleted'] == true) {
            if (userData['branch'] != null) {
              await SharedPreferencesService.setString(
                'selectedBranch',
                userData['branch'],
              );
            }
            if (userData['section'] != null) {
              await SharedPreferencesService.setString(
                'selectedClass',
                userData['section'],
              );
              await SharedPreferencesService.setBool('savePreference', true);
            }
          }
        }
      }
    } catch (e) {
      // Silently fail - profile data is optional for navigation
    }
  }

  void _finishLoading() {
    if (mounted) {
      widget.onLoadingComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey[800],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 4,
          );
        },
      ),
    );
  }
}
