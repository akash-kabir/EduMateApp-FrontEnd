import 'package:flutter/material.dart';
import 'compact_toast_widget.dart';
import 'success_card_widget.dart';

class EduMateToast {
  static OverlayEntry? _currentOverlayEntry;

  /// Helper to dismiss any currently active toast/snackbar overlay cleanly
  static void dismiss() {
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;
  }

  /// Displays the slide-and-expand top notification bar
  static void showCompact(
    BuildContext context, {
    required String message,
    required bool isSuccess,
  }) {
    // Dismiss any existing overlay first
    dismiss();

    final overlayState = Overlay.of(context);
    
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => CompactToastWidget(
        message: message,
        isSuccess: isSuccess,
        onDismiss: () {
          if (_currentOverlayEntry == entry) {
            dismiss();
          }
        },
      ),
    );

    _currentOverlayEntry = entry;
    overlayState.insert(entry);
  }

  /// Displays the centered success modal card
  static void showSuccessCard(
    BuildContext context, {
    required String title,
    String? description,
  }) {
    // Dismiss any existing overlay first
    dismiss();

    final overlayState = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => SuccessCardWidget(
        title: title,
        description: description,
        onDismiss: () {
          if (_currentOverlayEntry == entry) {
            dismiss();
          }
        },
      ),
    );

    _currentOverlayEntry = entry;
    overlayState.insert(entry);
  }
}
