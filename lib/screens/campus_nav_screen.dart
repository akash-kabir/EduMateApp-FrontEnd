import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CampusNavScreen extends StatefulWidget {
  const CampusNavScreen({super.key});

  @override
  State<CampusNavScreen> createState() => _CampusNavScreenState();
}

class _CampusNavScreenState extends State<CampusNavScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Colors.black : CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDark
            ? CupertinoColors.black.withOpacity(0.6)
            : CupertinoColors.white.withOpacity(0.6),
        middle: const Text('Campus Navigation'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: CupertinoSearchTextField(
                placeholder: 'Search locations',
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.map,
                        size: 64,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Campus Map',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Coming Soon',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
