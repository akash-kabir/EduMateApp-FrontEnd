import 'package:flutter/material.dart';

class TodaysScheduleSkeleton extends StatefulWidget {
  final bool isDark;
  const TodaysScheduleSkeleton({super.key, required this.isDark});

  @override
  State<TodaysScheduleSkeleton> createState() => _TodaysScheduleSkeletonState();
}

class _TodaysScheduleSkeletonState extends State<TodaysScheduleSkeleton> with SingleTickerProviderStateMixin {
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
    final baseColor = widget.isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1);
    final highlightColor = widget.isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.2);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 16, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(width: 60, height: 50, decoration: BoxDecoration(color: highlightColor, borderRadius: BorderRadius.circular(8))),
                        const SizedBox(width: 12),
                        Container(width: 100, height: 20, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4))),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SizedBox(
                  height: 120,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, __) => Container(
                      width: 220,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(16),
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
