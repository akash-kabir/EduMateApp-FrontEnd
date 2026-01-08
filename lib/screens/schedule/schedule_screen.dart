import 'package:flutter/cupertino.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Schedule')),
      child: const Center(child: Text('Schedule Screen')),
    );
  }
}
