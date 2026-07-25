import 'package:flutter/material.dart';

/// Colors - Admin Theme
class AdminColors {
  static const Color primary = Color(0xFFFF1744);
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color text = Colors.white;
  static const Color background = Colors.black;
}

/// Colors - Auth / Brand Palette
class AuthPalette {
  static const Color blush = Color(0xFFF7B39A);
  static const Color coral = Color(0xFFFF9B7A);
  static const Color rose = Color(0xFFF28F8F);
  static const Color teal = Color(0xFF2D8C87);
  static const Color deepTeal = Color(0xFF0F5F73);

  static const List<Color> gradient = [blush, coral, rose, teal, deepTeal];
  static const List<Color> glowExtremes = [blush, deepTeal];

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: gradient,
  );

  static const LinearGradient actionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blush, deepTeal],
  );
}

/// Colors - User Theme
class UserColors {
  static const Color primary = AuthPalette.blush;
  static const Color secondary = AuthPalette.deepTeal;
  static const Color background = Colors.black;
  static const Color text = Colors.white;
  static const Color textLight = Colors.white70;
}

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: UserColors.background,
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
      bodyLarge: TextStyle(color: Colors.white),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: UserColors.background,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    colorScheme: const ColorScheme.dark(
      primary: AuthPalette.coral,
      secondary: Colors.grey,
    ),
    iconTheme: const IconThemeData(color: Colors.white),
  );
}
