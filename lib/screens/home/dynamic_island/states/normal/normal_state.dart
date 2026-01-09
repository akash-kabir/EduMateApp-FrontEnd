import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class NormalState extends StatelessWidget {
  final Animation<double> normalStateOpacity;
  final String greeting;
  final String userName;
  final bool isDark;

  const NormalState({
    super.key,
    required this.normalStateOpacity,
    required this.greeting,
    required this.userName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: normalStateOpacity,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: userName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: CupertinoColors.systemBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
