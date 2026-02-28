import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/shared_preferences_service.dart';

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

      // Step 2: Check profile status from backend (30% progress)
      _updateProgress(0.3);
      final profileStatusResult = await _checkProfileStatus(
        userId: userId,
        token: token,
      );

      bool isProfileCompleted = false;

      if (!profileStatusResult['success']) {
        // New user - profile status check failed, jump to 100% and finish
        await SharedPreferencesService.setBool('isProfileCompleted', false);

        // Jump directly to 100%
        _updateProgress(1.0);
        await Future.delayed(const Duration(milliseconds: 300));
        _finishLoading();
        return;
      }

      // Existing user - continue with normal progression
      isProfileCompleted = profileStatusResult['isProfileCompleted'] ?? false;

      // Step 3: Update progress to 60%
      _updateProgress(0.6);
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 4: If profile completed, fetch full user profile (80% progress)
      if (isProfileCompleted) {
        _updateProgress(0.8);
        await _getUserProfile(token: token);
      }

      // Step 5: Complete progress (100%)
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

  Future<Map<String, dynamic>> _checkProfileStatus({
    required String userId,
    required String token,
  }) async {
    try {
      final result = await ApiService.checkProfileStatus(
        userId: userId,
        token: token,
      );

      if (result['success'] ?? false) {
        final isProfileCompleted = result['isProfileCompleted'] ?? false;

        // Save to SharedPreferencesService
        await SharedPreferencesService.setBool(
          'isProfileCompleted',
          isProfileCompleted,
        );

        return {'success': true, 'isProfileCompleted': isProfileCompleted};
      }

      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  Future<void> _getUserProfile({required String token}) async {
    try {
      final result = await ApiService.getUserProfile(token: token);

      if (result['success'] ?? false) {
        // Save user profile data to SharedPreferencesService if needed
        if (result['data'] != null) {
          final userData = result['data'];
          await SharedPreferencesService.setUserEmail(userData['email'] ?? '');
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
