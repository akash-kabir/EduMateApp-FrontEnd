import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class SkeletonLoadingList extends StatefulWidget {
  const SkeletonLoadingList({Key? key}) : super(key: key);

  @override
  State<SkeletonLoadingList> createState() => _SkeletonLoadingListState();
}

class _SkeletonLoadingListState extends State<SkeletonLoadingList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.2, end: 0.6).animate(
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(4, (index) => const _SkeletonCard()),
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final accentColor = isDark ? Colors.grey[700]! : Colors.grey[400]!;
    
    final BoxDecoration cardDecoration = BoxDecoration(
      color: isDark
          ? const Color(0xFF1E1E23).withValues(alpha: 0.40)
          : Colors.grey[200]!.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(16),
      border: Border(left: BorderSide(color: accentColor, width: 4)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 8.0,
          offset: const Offset(0, 4),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: cardDecoration,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Time and Room
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Time pill skeleton
                    Container(
                      width: 100,
                      height: 24,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // Room pill skeleton
                    Container(
                      width: 60,
                      height: 24,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Subject title skeleton
                Container(
                  width: double.infinity,
                  height: 20,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Second line (teacher) skeleton
                Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 16,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
