import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  bool _isDarkMode = true;
  bool _followSystemTheme = false;

  static const String _darkModeKey = 'isDarkMode';
  static const String _followSystemKey = 'followSystemTheme';

  ThemeProvider() {
    WidgetsBinding.instance.addObserver(this);
    _loadThemePreferences();
  }

  bool get isDarkMode => _isDarkMode;
  bool get followSystemTheme => _followSystemTheme;

  Future<void> _loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? true;
    _followSystemTheme = prefs.getBool(_followSystemKey) ?? false;

    if (_followSystemTheme) {
      final systemBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _isDarkMode = systemBrightness == Brightness.dark;
    }

    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    _followSystemTheme = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
    await prefs.setBool(_followSystemKey, false);

    notifyListeners();
  }

  Future<void> setFollowSystemTheme(bool value) async {
    _followSystemTheme = value;

    if (value) {
      final systemBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _isDarkMode = systemBrightness == Brightness.dark;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_followSystemKey, value);
    await prefs.setBool(_darkModeKey, _isDarkMode);

    notifyListeners();
  }

  @override
  void didChangePlatformBrightness() {
    if (_followSystemTheme) {
      final systemBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      final newIsDark = systemBrightness == Brightness.dark;
      if (_isDarkMode != newIsDark) {
        _isDarkMode = newIsDark;
        _saveThemePreference();
        notifyListeners();
      }
    }
  }

  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, _isDarkMode);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
