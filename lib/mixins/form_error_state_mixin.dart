import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Mixin for form error state management
/// Provides reusable animation and error handling logic for forms
mixin FormErrorStateMixin<T extends StatefulWidget> on State<T> {
  late AnimationController errorAnimationController;

  bool _isUsernameError = false;
  bool _isPasswordError = false;
  bool _isEmailError = false;

  bool get isUsernameError => _isUsernameError;
  bool get isPasswordError => _isPasswordError;
  bool get isEmailError => _isEmailError;

  @override
  void initState() {
    super.initState();
    _initializeErrorAnimation();
  }

  void _initializeErrorAnimation() {
    errorAnimationController =
        AnimationController(
          duration: AnimationDurations.formErrorShake,
          vsync: this as TickerProvider,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            errorAnimationController.reverse();
          } else if (status == AnimationStatus.dismissed) {
            setState(() {
              _isUsernameError = false;
              _isPasswordError = false;
              _isEmailError = false;
            });
          }
        });
  }

  /// Set username error state and trigger animation
  void setUsernameError(bool hasError) {
    setState(() {
      _isUsernameError = hasError;
    });
    if (hasError) {
      errorAnimationController.forward(from: 0.0);
    }
  }

  /// Set password error state and trigger animation
  void setPasswordError(bool hasError) {
    setState(() {
      _isPasswordError = hasError;
    });
    if (hasError) {
      errorAnimationController.forward(from: 0.0);
    }
  }

  /// Set email error state and trigger animation
  void setEmailError(bool hasError) {
    setState(() {
      _isEmailError = hasError;
    });
    if (hasError) {
      errorAnimationController.forward(from: 0.0);
    }
  }

  /// Reset all error states
  void resetAllErrors() {
    setState(() {
      _isUsernameError = false;
      _isPasswordError = false;
      _isEmailError = false;
    });
  }

  @override
  void dispose() {
    errorAnimationController.dispose();
    super.dispose();
  }
}
