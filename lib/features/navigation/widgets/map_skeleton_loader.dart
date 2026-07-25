import 'package:flutter/material.dart';

class MapSkeletonLoader extends StatefulWidget {
  final bool isDark;
  const MapSkeletonLoader({super.key, required this.isDark});

  @override
  State<MapSkeletonLoader> createState() => _MapSkeletonLoaderState();
}

class _MapSkeletonLoaderState extends State<MapSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final baseColor = isDark ? const Color(0xFF2C2C2E) : Colors.grey[300]!;

    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Container(
          color: isDark ? const Color(0xFF0F0F11) : const Color(0xFFF2F2F7),
          child: Stack(
            children: [
              // ── Clean Map Grid Canvas (Enhanced Intensity, No Circles / Shadows) ──
              Positioned.fill(
                child: Opacity(
                  opacity: _opacityAnimation.value * 0.85,
                  child: CustomPaint(
                    painter: _MapGridSkeletonPainter(isDark: isDark),
                  ),
                ),
              ),

              // ── Top Search Bar Skeleton (SafeArea aligned) ──
              Positioned(
                top: 0,
                left: 16,
                right: 16,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 150,
                            height: 14,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : Colors.black12,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Simple Grid Lines Painter (Flat & Clean, No Building Block Circles)
class _MapGridSkeletonPainter extends CustomPainter {
  final bool isDark;
  _MapGridSkeletonPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.18)
          : Colors.black.withValues(alpha: 0.10)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Grid Lines Only
    const double step = 60.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridSkeletonPainter oldDelegate) => false;
}
