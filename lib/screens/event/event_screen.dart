import 'package:flutter/cupertino.dart';

class EventScreen extends StatelessWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Events')),
      child: const Center(child: Text('Events Screen')),
    );
  }
}
