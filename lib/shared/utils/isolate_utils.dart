import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Runs jsonDecode in a background isolate to prevent blocking the main thread.
Future<dynamic> parseJsonInBackground(String source) async {
  return compute(jsonDecode, source);
}
