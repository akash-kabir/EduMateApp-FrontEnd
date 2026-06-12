import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String description,
  required String confirmButtonText,
  required IconData iconData,
  Color primaryColor = const Color(0xFFFF1744),
}) {
  return showGlassmorphicDialog<bool>(
    context: context,
    barrierDismissible: false,
    widthFactor: 0.85,
    darkBackgroundAlpha: 0.65,
    lightBackgroundAlpha: 0.70,
    child: Builder(
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.0,
              height: 64.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.15),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                iconData,
                color: primaryColor,
                size: 32.0,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14.0,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      confirmButtonText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }
    ),
  );
}

Future<bool?> showDeleteConfirmationDialog({
  required BuildContext context,
  required String title,
  required String description,
}) {
  return showConfirmationDialog(
    context: context,
    title: title,
    description: description,
    confirmButtonText: 'Delete',
    iconData: CupertinoIcons.trash_fill,
  );
}


Future<T?> showGlassmorphicDialog<T>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
  String barrierLabel = 'Dialog',
  double widthFactor = 0.85,
  double? darkBackgroundAlpha,
  double? lightBackgroundAlpha,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, anim1, anim2) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return Center(
        child: Material(
          type: MaterialType.transparency,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(
                width: MediaQuery.of(ctx).size.width * widthFactor,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F0F11).withValues(alpha: darkBackgroundAlpha ?? 0.75)
                      : Colors.white.withValues(alpha: lightBackgroundAlpha ?? 0.85),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30.0,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, anim1, anim2, child) {
      return Transform.scale(
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(
          CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
        ).value,
        child: FadeTransition(
          opacity: anim1,
          child: child,
        ),
      );
    },
  );
}
