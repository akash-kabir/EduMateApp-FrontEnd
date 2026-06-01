import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

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
