import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MapSearchBar extends StatelessWidget {
  final bool isFullScreenSearch;
  final bool isDark;
  final VoidCallback onToggleSearch;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const MapSearchBar({
    super.key,
    required this.isFullScreenSearch,
    required this.isDark,
    required this.onToggleSearch,
    this.controller,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : (isFullScreenSearch ? Colors.white : Colors.grey[200]),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            CupertinoButton(
              padding: const EdgeInsets.only(left: 16, right: 12),
              onPressed: onToggleSearch,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => RotationTransition(
                  turns: child.key == const ValueKey('back')
                      ? Tween<double>(begin: -0.25, end: 0).animate(animation)
                      : Tween<double>(begin: 0.25, end: 0).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: isFullScreenSearch
                    ? Icon(CupertinoIcons.back, key: const ValueKey('back'), color: isDark ? Colors.white : Colors.black)
                    : Icon(CupertinoIcons.search, key: const ValueKey('search'), color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
            Expanded(
              child: isFullScreenSearch
                  ? CupertinoTextField(
                      controller: controller,
                      autofocus: true,
                      placeholder: 'Search location...',
                      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16),
                      decoration: null,
                      onChanged: onChanged,
                    )
                  : GestureDetector(
                      onTap: onToggleSearch,
                      child: Container(
                        color: Colors.transparent,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Search...',
                          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 16),
                        ),
                      ),
                    ),
            ),
            if (isFullScreenSearch)
              CupertinoButton(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(CupertinoIcons.clear_thick_circled, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 20),
                onPressed: onClear,
              )
          ],
        ),
      ),
    );
  }
}
