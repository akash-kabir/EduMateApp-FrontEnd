import 'package:flutter/cupertino.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Profile')),
      child: const Center(child: Text('Profile Screen')),
    );
  }
}
