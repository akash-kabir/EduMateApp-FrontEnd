import 'package:flutter/material.dart';

class SkeletonEventList extends StatefulWidget {
  const SkeletonEventList({super.key});

  @override
  State<SkeletonEventList> createState() => _SkeletonEventListState();
}

class _SkeletonEventListState extends State<SkeletonEventList>
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
              children: List.generate(4, (index) => const _SkeletonEventCard()),
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonEventCard extends StatelessWidget {
  const _SkeletonEventCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Name
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                // Avatar skeleton
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: baseColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author name skeleton
                      Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Time/Badge skeleton
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Heading skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 18,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Image skeleton (sometimes present)
          Container(
            width: double.infinity,
            height: 200,
            color: baseColor.withOpacity(0.5),
          ),
          
          const SizedBox(height: 12),
          
          // Body lines skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 14,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
