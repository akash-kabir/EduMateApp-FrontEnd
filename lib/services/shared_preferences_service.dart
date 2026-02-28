import 'package:shared_preferences/shared_preferences.dart';

/// A master service class for managing all SharedPreferences operations.
/// This file acts as a centralized location for all shared preference data access.
///
/// Usage:
/// ```dart
/// import 'services/shared_preferences_service.dart';
///
/// // Store data
/// await SharedPreferencesService.setToken('your_token_here');
/// await SharedPreferencesService.setUserId('user_id');
///
/// // Retrieve data
/// final token = await SharedPreferencesService.getToken();
/// final userId = await SharedPreferencesService.getUserId();
///
/// // Clear data
/// await SharedPreferencesService.clearAll();
/// ```
class SharedPreferencesService {
  // Private constructor to prevent instantiation
  SharedPreferencesService._();

  // Key constants for all shared preferences
  static const String _tokenKey = 'token';
  static const String _userIdKey = 'user_id';
  static const String _userRoleKey = 'user_role';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userFirstNameKey = 'userFirstName';
  static const String _userLastNameKey = 'userLastName';
  static const String _branchKey = 'branch';
  static const String _sectionKey = 'section';
  static const String _rollNoKey = 'rollNo';
  static const String _yearKey = 'year';
  static const String _semesterKey = 'semester';
  static const String _isProfileCompletedKey = 'isProfileCompleted';
  static const String _themeKey = 'theme_mode';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _profileSetupCompleteKey = 'profile_setup_complete';
  static const String _neverAskProfileSetupKey = 'never_ask_profile_setup';

  // ==================== Token Management ====================

  /// Save authentication token
  static Future<bool> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_tokenKey, token);
  }

  /// Retrieve authentication token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Check if token exists
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Remove authentication token
  static Future<bool> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_tokenKey);
  }

  // ==================== User Information ====================

  /// Save user ID
  static Future<bool> setUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_userIdKey, userId);
  }

  /// Retrieve user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Save user role (e.g., 'student', 'faculty', 'admin', 'society_head')
  static Future<bool> setUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_userRoleKey, role);
  }

  /// Retrieve user role
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  /// Save user name
  static Future<bool> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_userNameKey, name);
  }

  /// Retrieve user name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  /// Save user email
  static Future<bool> setUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_userEmailKey, email);
  }

  /// Retrieve user email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // ==================== Branch and Section ====================

  /// Save user branch
  static Future<bool> setBranch(String branch) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_branchKey, branch);
  }

  /// Retrieve user branch
  static Future<String?> getBranch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_branchKey);
  }

  /// Save user section
  static Future<bool> setSection(String section) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_sectionKey, section);
  }

  /// Retrieve user section
  static Future<String?> getSection() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sectionKey);
  }

  // ==================== Application Settings ====================

  /// Save theme mode preference ('light' or 'dark')
  static Future<bool> setThemeMode(String themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_themeKey, themeMode);
  }

  /// Retrieve theme mode preference
  static Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey);
  }

  /// Save login status
  static Future<bool> setIsLoggedIn(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  /// Retrieve login status
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // ==================== Profile Setup Prompt ====================

  /// Mark profile setup as complete
  static Future<bool> setProfileSetupComplete(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_profileSetupCompleteKey, value);
  }

  /// Check if profile setup is complete
  static Future<bool> isProfileSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_profileSetupCompleteKey) ?? false;
  }

  /// Set never ask for profile setup again
  static Future<bool> setNeverAskProfileSetup(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_neverAskProfileSetupKey, value);
  }

  /// Check if user chose to never be asked for profile setup
  static Future<bool> isNeverAskProfileSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_neverAskProfileSetupKey) ?? false;
  }

  // ==================== Schedule Data ====================

  /// Save cached schedule data
  static Future<bool> setCachedSchedule(
    String branch,
    String section,
    String scheduleJson,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'schedule_${branch}_$section';
    return prefs.setString(key, scheduleJson);
  }

  /// Retrieve cached schedule data
  static Future<String?> getCachedSchedule(
    String branch,
    String section,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'schedule_${branch}_$section';
    return prefs.getString(key);
  }

  /// Remove cached schedule for specific branch and section
  static Future<bool> removeCachedSchedule(
    String branch,
    String section,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'schedule_${branch}_$section';
    return prefs.remove(key);
  }

  // ==================== Generic Methods ====================

  /// Save a string value with custom key
  static Future<bool> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  /// Retrieve a string value with custom key
  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  /// Save an integer value with custom key
  static Future<bool> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt(key, value);
  }

  /// Retrieve an integer value with custom key
  static Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  /// Save a boolean value with custom key
  static Future<bool> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(key, value);
  }

  /// Retrieve a boolean value with custom key
  static Future<bool> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  /// Save a list of strings with custom key
  static Future<bool> setStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(key, value);
  }

  /// Retrieve a list of strings with custom key
  static Future<List<String>> getStringList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? [];
  }

  /// Save a double value with custom key
  static Future<bool> setDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setDouble(key, value);
  }

  /// Retrieve a double value with custom key
  static Future<double?> getDouble(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key);
  }

  /// Remove a specific key
  static Future<bool> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(key);
  }

  /// Check if a key exists
  static Future<bool> containsKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }

  /// Get all keys stored in SharedPreferences
  static Future<Set<String>> getAllKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys();
  }

  // ==================== Clear Data ====================

  /// Clear all stored data (usually called on logout)
  static Future<bool> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }

  /// Clear user-specific data (called on logout)
  static Future<void> clearUserData() async {
    await removeToken();
    await remove(_userIdKey);
    await remove(_userRoleKey);
    await remove(_userNameKey);
    await remove(_userEmailKey);
    await remove(_userFirstNameKey);
    await remove(_userLastNameKey);
    await remove(_branchKey);
    await remove(_sectionKey);
    await remove(_rollNoKey);
    await remove(_yearKey);
    await remove(_semesterKey);
    await remove(_isProfileCompletedKey);
    await remove(_profileSetupCompleteKey);
    await remove(_neverAskProfileSetupKey);
    await remove('selectedClass');
    await remove('selectedBranch');
    await remove('savePreference');
    await remove('cgpa');
    await setIsLoggedIn(false);
  }

  // ==================== Full Profile Save/Load ====================

  /// Save the full user profile from backend response to SharedPreferences.
  /// Call this after login, signup, or fetching profile from backend.
  static Future<void> saveFullUserProfile(Map<String, dynamic> user) async {
    if (user['id'] != null || user['_id'] != null) {
      await setUserId(user['id']?.toString() ?? user['_id']?.toString() ?? '');
    }
    if (user['firstName'] != null) {
      await setString(_userFirstNameKey, user['firstName']);
    }
    if (user['lastName'] != null) {
      await setString(_userLastNameKey, user['lastName']);
    }
    if (user['username'] != null) {
      await setUserName(user['username']);
    }
    if (user['email'] != null) {
      await setUserEmail(user['email']);
    }
    if (user['role'] != null) {
      await setUserRole(user['role']);
    }
    if (user['rollNo'] != null) {
      await setString(_rollNoKey, user['rollNo']);
    }
    if (user['branch'] != null) {
      await setBranch(user['branch']);
    }
    if (user['section'] != null) {
      await setSection(user['section']);
      // Also save as selectedClass for timesheet compatibility
      await setString('selectedClass', user['section']);
    }
    if (user['year'] != null) {
      await setString(_yearKey, user['year']);
    }
    if (user['semester'] != null) {
      await setString(_semesterKey, user['semester']);
    }
    final isCompleted = user['isProfileCompleted'] ?? false;
    await setBool(_isProfileCompletedKey, isCompleted);
    if (isCompleted) {
      await setProfileSetupComplete(true);
    }
  }

  // ==================== First/Last Name ====================

  static Future<String?> getFirstName() async {
    return getString(_userFirstNameKey);
  }

  static Future<String?> getLastName() async {
    return getString(_userLastNameKey);
  }

  // ==================== Roll Number ====================

  static Future<String?> getRollNo() async {
    return getString(_rollNoKey);
  }

  // ==================== Year ====================

  static Future<String?> getYear() async {
    return getString(_yearKey);
  }

  // ==================== Semester ====================

  static Future<String?> getSemester() async {
    return getString(_semesterKey);
  }

  // ==================== Profile Completed ====================

  static Future<bool> getIsProfileCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isProfileCompletedKey) ?? false;
  }
}
