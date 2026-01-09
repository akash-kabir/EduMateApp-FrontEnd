import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'cards/announcement_card.dart';
import 'cards/assignments_card.dart';
import 'cards/class_card.dart';

class MaximizedState extends StatelessWidget {
  final Animation<double> maximizedStateOpacity;
  final Animation<double> buttonOpacity;
  final bool isDark;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNavigateToEvent;
  final VoidCallback? onNavigateToSchedule;

  const MaximizedState({
    super.key,
    required this.maximizedStateOpacity,
    required this.buttonOpacity,
    required this.isDark,
    this.onProfileTap,
    this.onNavigateToEvent,
    this.onNavigateToSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: maximizedStateOpacity,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              'Things in This Week',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnnouncementCard(
              isDark: isDark,
              onNavigateToEvent: onNavigateToEvent,
            ),
            const SizedBox(height: 12),
            AssignmentsCard(
              isDark: isDark,
              onNavigateToSchedule: onNavigateToSchedule,
            ),
            const SizedBox(height: 12),
            ClassCard(isDark: isDark),
          ],
        ),
        const SizedBox(height: 16),
        FadeTransition(
          opacity: buttonOpacity,
          child: Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onProfileTap,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Go to Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {},
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.settings,
                      color: CupertinoColors.systemBlue,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
