import 'package:flutter/material.dart';
import 'package:app/shared/widgets/dialogs/compact_toast_widget.dart';
import 'package:app/widgets/success_card_widget.dart';

class EduMateToast {
  static OverlayEntry? _currentOverlayEntry;

  /// Helper to dismiss any currently active toast/snackbar overlay cleanly
  static void dismiss() {
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;
  }

  static String _formatMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('socketexception') || lower.contains('failed host lookup') || lower.contains('connection refused') || lower.contains('handshakeexception')) {
      return 'No internet connection';
    }
    return message;
  }

  /// Displays the slide-and-expand top notification bar
  static void showCompact(
    BuildContext context, {
    required String message,
    required bool isSuccess,
    String? actionLabel,
    VoidCallback? onActionTap,
    Duration? duration,
  }) {
    // Dismiss any existing overlay first
    dismiss();

    final overlayState = Overlay.of(context);
    
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => CompactToastWidget(
        message: _formatMessage(message),
        isSuccess: isSuccess,
        actionLabel: actionLabel,
        onActionTap: () {
          if (onActionTap != null) onActionTap();
          dismiss();
        },
        duration: duration ?? const Duration(milliseconds: 3800),
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
