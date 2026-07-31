import 'package:flutter/material.dart';
import 'package:app/theme/theme.dart';
import 'package:app/shared/widgets/dialogs/custom_glass_dialog.dart';

void showGlobalRoleChangeDialog(BuildContext context, String oldRole, String newRole) {
  showGlassmorphicDialog(
    context: context,
    barrierDismissible: false,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Role Changed',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your role has been changed from ${oldRole.toUpperCase()} to ${newRole.toUpperCase()}.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AuthPalette.coral,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Got it',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
