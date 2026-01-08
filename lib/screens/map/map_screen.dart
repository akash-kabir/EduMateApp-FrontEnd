import 'package:flutter/cupertino.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Map')),
      child: const Center(child: Text('Map Screen')),
    );
  }
}
