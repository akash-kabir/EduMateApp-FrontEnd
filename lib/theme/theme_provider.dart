import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  bool _isDarkMode = true; // default dark
  bool _followSystemTheme = false;

  ThemeProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  bool get isDarkMode => _isDarkMode;
  bool get followSystemTheme => _followSystemTheme;

  void setDarkMode(bool value) {
    _isDarkMode = value;
    _followSystemTheme = false;
    notifyListeners();
  }

  void setFollowSystemTheme(bool value) {
    _followSystemTheme = value;
    if (value) {
      final systemBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _isDarkMode = systemBrightness == Brightness.dark;
    }
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
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
