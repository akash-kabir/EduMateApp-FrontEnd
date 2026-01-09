import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AssignmentsCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onNavigateToSchedule;

  const AssignmentsCard({
    super.key,
    required this.isDark,
    this.onNavigateToSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green[500]!.withOpacity(0.7),
            Colors.yellow[600]!.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(1.5),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.doc_text_fill,
                  color: Colors.green[500],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Assignments',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: onNavigateToSchedule,
              child: Icon(
                CupertinoIcons.arrow_turn_up_right,
                color: Colors.green[500],
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
