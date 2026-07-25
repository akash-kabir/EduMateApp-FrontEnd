import 'package:flutter/material.dart';

class Validators {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain a lowercase letter';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }

    if (!RegExp(r'[!@#$%^&*()_+=\[\]{};:,.<>?/\\|`~-]').hasMatch(password)) {
      return 'Password must contain a special character';
    }

    return null;
  }

  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'Username is required';
    }

    if (username.length < 3) {
      return 'Username must be at least 3 characters long';
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }

    return null;
  }

  static String getPasswordStrength(String password) {
    if (password.isEmpty) return 'Weak';

    int strengthScore = 0;

    if (password.length >= 8) strengthScore++;
    if (password.length >= 12) strengthScore++;

    if (password.contains(RegExp(r'[a-z]'))) strengthScore++;
    if (password.contains(RegExp(r'[A-Z]'))) strengthScore++;
    if (password.contains(RegExp(r'[0-9]'))) strengthScore++;
    if (RegExp(r'[!@#$%^&*()_+=\[\]{};:,.<>?/\\|`~-]').hasMatch(password)) {
      strengthScore++;
    }

    if (strengthScore < 3) return 'Weak';
    if (strengthScore < 5) return 'Medium';
    return 'Strong';
  }

  static Map<String, dynamic> getPasswordStrengthColor(String password) {
    final strength = getPasswordStrength(password);

    switch (strength) {
      case 'Weak':
        return {
          'color': const Color.fromARGB(255, 244, 67, 54),
          'text': 'Weak',
        };
      case 'Medium':
        return {
          'color': const Color.fromARGB(255, 255, 152, 0),
          'text': 'Medium',
        };
      case 'Strong':
        return {
          'color': const Color.fromARGB(255, 76, 175, 80),
          'text': 'Strong',
        };
      default:
        return {
          'color': const Color.fromARGB(255, 189, 189, 189),
          'text': 'Enter password',
        };
    }
  }
}
