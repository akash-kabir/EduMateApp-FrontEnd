import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

class NavigationStatusCard extends StatelessWidget {
  final bool isDark;
  final String poiName;
  final double distanceInMeters;
  final VoidCallback onStopNavigation;

  const NavigationStatusCard({
    super.key,
    required this.isDark,
    required this.poiName,
    required this.distanceInMeters,
    required this.onStopNavigation,
  });

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AuthPalette.teal.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.location_solid,
                  color: AuthPalette.teal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              
              // Text Content
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Navigating to',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      poiName,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDistance(distanceInMeters),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AuthPalette.coral,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Stop Button
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onStopNavigation,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
