import 'package:flutter/foundation.dart';
import '../models/poi_model.dart';

class MapNavigationStore {
  static final MapNavigationStore instance = MapNavigationStore._();
  MapNavigationStore._();

  final ValueNotifier<int?> tabChangeNotifier = ValueNotifier<int?>(null);
  final ValueNotifier<PoiModel?> pendingNavigationPoi = ValueNotifier<PoiModel?>(null);

  void navigateToPoi(PoiModel poi) {
    pendingNavigationPoi.value = poi;
    tabChangeNotifier.value = null;
    tabChangeNotifier.value = 3; // Index 3 is MapScreen
  }

  void clearPendingPoi() {
    pendingNavigationPoi.value = null;
  }
}
