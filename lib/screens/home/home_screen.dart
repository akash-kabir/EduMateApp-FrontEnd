import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../splash/splash_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (context) => const SplashScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Home'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _logout(context),
          child: const Icon(CupertinoIcons.square_arrow_right),
        ),
      ),
      child: const Center(child: Text('Home Screen')),
    );
  }
}
