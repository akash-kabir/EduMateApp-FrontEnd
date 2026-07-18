import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as math;

import '../../models/poi_model.dart';
import 'map_route_service.dart';

class NavigationManager extends ChangeNotifier {
  bool _isNavigating = false;
  PoiModel? _target;
  double _distanceRemaining = 0.0;
  
  // Tracking
  double? _lastRoutedLat;
  double? _lastRoutedLng;
  final double _rerouteThresholdMeters = 30.0;

  bool get isNavigating => _isNavigating;
  PoiModel? get target => _target;
  double get distanceRemaining => _distanceRemaining;

  Future<void> startNavigation(MapboxMap mapboxMap, PoiModel destination, double startLat, double startLng) async {
    _isNavigating = true;
    _target = destination;
    await _routeToTarget(mapboxMap, startLat, startLng);
    notifyListeners();
  }

  void stopNavigation(MapboxMap mapboxMap) {
    _isNavigating = false;
    _target = null;
    _lastRoutedLat = null;
    _lastRoutedLng = null;
    MapRouteService.clearRoute(mapboxMap);
    notifyListeners();
  }

  Future<void> onLocationUpdated(MapboxMap mapboxMap, double currentLat, double currentLng) async {
    if (!_isNavigating || _target == null) return;

    // 1. Instantly update the straight-line distance remaining for the UI
    _distanceRemaining = Geolocator.distanceBetween(
      currentLat,
      currentLng,
      _target!.lat,
      _target!.lng,
    );
    notifyListeners();

    // 2. Check if we need to redraw the polyline (if user moved significantly)
    if (_lastRoutedLat == null || _lastRoutedLng == null) {
      await _routeToTarget(mapboxMap, currentLat, currentLng);
    } else {
      final distanceSinceLastRoute = Geolocator.distanceBetween(
        currentLat,
        currentLng,
        _lastRoutedLat!,
        _lastRoutedLng!,
      );

      if (distanceSinceLastRoute > _rerouteThresholdMeters) {
        // Redraw polyline quietly
        await _routeToTarget(mapboxMap, currentLat, currentLng);
      }
    }
  }

  Future<void> _routeToTarget(MapboxMap mapboxMap, double lat, double lng) async {
    _lastRoutedLat = lat;
    _lastRoutedLng = lng;
    
    final routeData = await MapRouteService.drawRoute(
      mapboxMap: mapboxMap,
      originLat: lat,
      originLng: lng,
      destLat: _target!.lat,
      destLng: _target!.lng,
    );

    if (routeData != null && routeData['distance'] != null) {
      // Use the exact road-distance from Mapbox rather than straight-line if we just fetched it
      _distanceRemaining = (routeData['distance'] as num).toDouble();
      notifyListeners();
    }
  }
}
