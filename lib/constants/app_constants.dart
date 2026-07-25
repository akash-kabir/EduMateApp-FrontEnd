import 'package:flutter/material.dart';

/// Animation Durations
class AnimationDurations {
  static const Duration pageEntrance = Duration(milliseconds: 1200);
  static const Duration textReveal = Duration(milliseconds: 800);
  static const Duration backgroundCircle = Duration(seconds: 5);
  static const Duration pageTransition = Duration(milliseconds: 300);
}

/// Font Sizes
class FontSizes {
  static const double heading1 = 48.0;
  static const double heading2 = 36.0;
  static const double heading3 = 28.0;
  static const double heading4 = 26.0;
  static const double subheading = 24.0;
  static const double body = 16.0;
  static const double small = 14.0;
  static const double caption = 12.0;
}

/// Spacing
class Spacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 48.0;
  static const double topPaddingLarge = 80.0;
  static const double topPaddingExtraLarge = 120.0;
  static const double topPaddingSignup = 200.0;
}

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

/// Profile Setup Constants
class ProfileSetupConstants {
  static const String kiitEmailDomain = '@kiit.ac.in';
  static const int yearBaseValue = 2000;
  static const int academicYearStartMonth = 6; // June

  static const List<String> academicYears = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];

  static const List<String> branches = ['CSCE', 'CSE', 'IT', 'CSSE'];

  static const Map<String, List<String>> sectionsPerBranch = {
    'CSCE': ['CSCE-1'],
    'CSE': [
      'CSE-1',
      'CSE-2',
      'CSE-3',
      'CSE-4',
      'CSE-5',
      'CSE-6',
      'CSE-7',
      'CSE-8',
      'CSE-9',
      'CSE-10',
      'CSE-11',
      'CSE-12',
      'CSE-13',
      'CSE-14',
      'CSE-15',
      'CSE-16',
      'CSE-17',
      'CSE-18',
      'CSE-19',
      'CSE-20',
      'CSE-21',
      'CSE-22',
      'CSE-23',
      'CSE-24',
      'CSE-25',
      'CSE-26',
      'CSE-27',
      'CSE-28',
      'CSE-29',
      'CSE-30',
      'CSE-31',
      'CSE-32',
      'CSE-33',
      'CSE-34',
      'CSE-35',
      'CSE-36',
      'CSE-37',
      'CSE-38',
      'CSE-39',
      'CSE-40',
      'CSE-41',
      'CSE-42',
      'CSE-43',
      'CSE-44',
      'CSE-45',
      'CSE-46',
      'CSE-47',
      'CSE-48',
      'CSE-49',
      'CSE-50',
      'CSE-51',
      'CSE-52',
      'CSE-53',
      'CSE-54',
    ],
    'IT': ['IT-1', 'IT-2'],
    'CSSE': ['CSSE-1'],
  };

  static const Map<String, List<String>> semestersByYear = {
    '1st Year': ['Semester 1', 'Semester 2'],
    '2nd Year': ['Semester 3', 'Semester 4'],
    '3rd Year': ['Semester 5', 'Semester 6'],
    '4th Year': ['Semester 7', 'Semester 8'],
  };

  static const int minAcademicYear = 1;
  static const int maxAcademicYear = 4;
}
