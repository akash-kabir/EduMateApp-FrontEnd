import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class MinimizedState extends StatelessWidget {
  final bool isDark;

  const MinimizedState({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.bell_fill, color: Colors.blue[500], size: 24),
              const SizedBox(width: 4),
              Text(
                ':  3',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Text(
          '|',
          style: TextStyle(
            color: isDark ? Colors.grey[600] : Colors.grey[400],
            fontWeight: FontWeight.w300,
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.doc_text_fill,
                color: Colors.green[500],
                size: 24,
              ),
              const SizedBox(width: 4),
              Text(
                ':  5',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
