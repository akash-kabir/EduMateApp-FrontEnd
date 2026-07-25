import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BottomSheetSelector<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final void Function(T) onChanged;
  final String hint;
  final bool isAdmin;

  const BottomSheetSelector({
    super.key,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    required this.hint,
    this.isAdmin = false,
  });

  void _showBottomSheet(BuildContext context) {
    int selectedIndex = items.indexOf(value as T);
    if (selectedIndex == -1) selectedIndex = 0;
    int tempIndex = selectedIndex;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doneColor = isAdmin ? const Color(0xFFFF1744) : const Color(0xFFFF7F50);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return SafeArea(
            child: SizedBox(
              height: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0, left: 16.0, right: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                        ),
                        Text(hint, style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.pop(context);
                            onChanged(items[tempIndex]);
                          },
                          child: Text('Done', style: TextStyle(color: doneColor, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: CupertinoPicker(
                      magnification: 1.15,
                      squeeze: 1.1,
                      useMagnifier: true,
                      itemExtent: 36.0,
                      scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                      onSelectedItemChanged: (int index) {
                        setModalState(() {
                          tempIndex = index;
                        });
                      },
                      children: items.map((item) => Center(
                        child: Text(
                          labelBuilder(item),
                          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          hint,
          style: const TextStyle(
            color: CupertinoColors.systemGrey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showBottomSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              value != null ? labelBuilder(value as T) : hint,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
