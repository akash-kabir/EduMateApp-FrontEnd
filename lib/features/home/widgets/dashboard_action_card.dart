import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DashboardActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const DashboardActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 110,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                  ? const [Color(0xFF303030), Color(0xFF1a1a1a)]
                  : const [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: -8,
                right: -8,
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds);
                  },
                  child: Icon(
                    icon,
                    size: 64,
                    color: Colors.white, // Color is replaced by ShaderMask
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
