import '../../../services/api_service.dart';

enum UserType { newUser, existingUser }

enum DynamicIslandDisplayMode { setupProfile, normalView, minimized, maximized }

class DynamicIslandBehavior {
  bool _isProfileCompleted = false;
  UserType _userType = UserType.newUser;
  DynamicIslandDisplayMode _currentDisplayMode =
      DynamicIslandDisplayMode.setupProfile;
  bool _hasUserInteracted = false;
  bool _isAppJustLaunched = true;

  DynamicIslandBehavior({bool isProfileCompleted = false}) {
    _isProfileCompleted = isProfileCompleted;
    _determineUserType();
    _initializeDisplayMode();
  }

  void _determineUserType() {
    _userType = _isProfileCompleted ? UserType.existingUser : UserType.newUser;
  }

  void _initializeDisplayMode() {
    if (_userType == UserType.newUser) {
      _currentDisplayMode = DynamicIslandDisplayMode.setupProfile;
      _hasUserInteracted = false;
    } else {
      _currentDisplayMode = DynamicIslandDisplayMode.normalView;
      _hasUserInteracted = false;
    }
  }

  UserType get userType => _userType;
  DynamicIslandDisplayMode get currentDisplayMode => _currentDisplayMode;
  bool get isProfileCompleted => _isProfileCompleted;
  bool get hasUserInteracted => _hasUserInteracted;
  bool get isAppJustLaunched => _isAppJustLaunched;
  String get displayModeName => _currentDisplayMode.toString();

  void onProfileSetupComplete() {
    _isProfileCompleted = true;
    _determineUserType();
    _currentDisplayMode = DynamicIslandDisplayMode.normalView;
    _hasUserInteracted = false;
  }

  void onIslandTapped() {
    _hasUserInteracted = true;
    _isAppJustLaunched = false;

    switch (_currentDisplayMode) {
      case DynamicIslandDisplayMode.setupProfile:
        break;

      case DynamicIslandDisplayMode.normalView:
        _currentDisplayMode = DynamicIslandDisplayMode.maximized;
        break;

      case DynamicIslandDisplayMode.minimized:
        _currentDisplayMode = DynamicIslandDisplayMode.maximized;
        break;

      case DynamicIslandDisplayMode.maximized:
        _currentDisplayMode = DynamicIslandDisplayMode.minimized;
        break;
    }
  }

  void onAppResumed() {
    _isAppJustLaunched = true;

    // Only reset display mode if profile is actually not completed
    // This prevents flashing the profile setup screen during navigation
    if (_isProfileCompleted) {
      _currentDisplayMode = DynamicIslandDisplayMode.normalView;
    } else {
      _currentDisplayMode = DynamicIslandDisplayMode.setupProfile;
    }

    _hasUserInteracted = false;
  }

  void onProfileSetupSkipped() {
    _currentDisplayMode = DynamicIslandDisplayMode.setupProfile;
  }

  double getHeightForMode() {
    switch (_currentDisplayMode) {
      case DynamicIslandDisplayMode.setupProfile:
        return 300;
      case DynamicIslandDisplayMode.normalView:
        return 140;
      case DynamicIslandDisplayMode.minimized:
        return 80;
      case DynamicIslandDisplayMode.maximized:
        return 380;
    }
  }

  bool shouldShowNormalView() {
    return _currentDisplayMode == DynamicIslandDisplayMode.normalView &&
        !_hasUserInteracted;
  }

  bool shouldShowSetupProfile() {
    return _currentDisplayMode == DynamicIslandDisplayMode.setupProfile;
  }

  bool shouldShowMinimized() {
    return _currentDisplayMode == DynamicIslandDisplayMode.minimized;
  }

  bool shouldShowMaximized() {
    return _currentDisplayMode == DynamicIslandDisplayMode.maximized;
  }

  Map<String, dynamic> getStateSummary() {
    return {
      'userType': _userType.toString(),
      'isProfileCompleted': _isProfileCompleted,
      'currentDisplayMode': _currentDisplayMode.toString(),
      'hasUserInteracted': _hasUserInteracted,
      'isAppJustLaunched': _isAppJustLaunched,
      'height': getHeightForMode(),
    };
  }

  // ==================== State Restoration ====================

  /// Load user profile status from backend
  /// Call this when app starts or user resumes
  Future<bool> loadUserProfileStatusFromBackend({
    required String userId,
    required String token,
  }) async {
    try {
      final result = await ApiService.checkProfileStatus(
        userId: userId,
        token: token,
      );

      if (result['success'] ?? false) {
        _isProfileCompleted = result['isProfileCompleted'] ?? false;
        _determineUserType();
        _initializeDisplayMode();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Save profile completion status to backend
  /// Call this when user completes profile setup
  Future<bool> saveProfileToBackend({
    required String token,
    required String rollNo,
    required String year,
    required String semester,
    required String branch,
  }) async {
    try {
      final result = await ApiService.updateUserProfile(
        token: token,
        rollNo: rollNo,
        year: year,
        semester: semester,
        branch: branch,
      );

      if (result['success'] ?? false) {
        _isProfileCompleted = true;
        _determineUserType();
        _initializeDisplayMode();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Get full user profile data from backend
  Future<Map<String, dynamic>?> getUserProfileFromBackend({
    required String token,
  }) async {
    try {
      final result = await ApiService.getUserProfile(token: token);

      if (result['success'] ?? false) {
        return result['data'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Update user profile with additional fields
  Future<bool> updateUserProfileWithAdditionalFields({
    required String token,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final result = await ApiService.updateUserProfileWithFields(
        token: token,
        profileData: profileData,
      );

      if (result['success'] ?? false) {
        _isProfileCompleted = true;
        _determineUserType();
        _initializeDisplayMode();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
