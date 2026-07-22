import 'dart:convert';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter/material.dart';
import '../../services/map_service.dart';

class MapRouteService {
  static const String _routeSourceId = 'route-source';
  static const String _routeLayerId = 'route-layer';

  /// Fetches the route via EduMate Secure Backend Proxy (MongoDB Cached + 85k Shielded) and draws it on the map.
  /// Returns a map with 'distance' (meters) and 'duration' (seconds), or null if failed.
  static Future<Map<String, dynamic>?> drawRoute({
    required MapboxMap mapboxMap,
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    Color routeColor = const Color(0xFF00BFA5),
    double lineWidth = 5.0,
  }) async {
    try {
      final routeData = await MapService.getDirections(
        originLat: originLat,
        originLng: originLng,
        destinationLat: destLat,
        destinationLng: destLng,
      );

      final coordinatesList = routeData['coordinates'] as List;
      final coordinates = coordinatesList
          .map((c) => [c['longitude'], c['latitude']])
          .toList();

      // Clear existing route if any
      await clearRoute(mapboxMap);

      final geoJsonObj = {
        'type': 'Feature',
        'properties': {},
        'geometry': {
          'type': 'LineString',
          'coordinates': coordinates,
        }
      };

      // Add GeoJSON source
      await mapboxMap.style.addSource(
        GeoJsonSource(
          id: _routeSourceId,
          data: json.encode(geoJsonObj),
        ),
      );

      // Add Line layer
      await mapboxMap.style.addLayer(
        LineLayer(
          id: _routeLayerId,
          sourceId: _routeSourceId,
          lineColor: routeColor.value,
          lineWidth: lineWidth,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );

      final distanceKm = double.tryParse(routeData['distance'].toString()) ?? 0.0;
      final durationMin = int.tryParse(routeData['duration'].toString()) ?? 0;

      return {
        'distance': distanceKm * 1000, // convert km to meters
        'duration': durationMin * 60, // convert minutes to seconds
      };
    } catch (e) {
      debugPrint('Error drawing route: $e');
      rethrow;
    }
  }

  /// Removes the currently drawn route from the map
  static Future<void> clearRoute(MapboxMap mapboxMap) async {
    try {
      final style = mapboxMap.style;

      final layerExists = await style.styleLayerExists(_routeLayerId);
      if (layerExists) {
        await style.removeStyleLayer(_routeLayerId);
      }

      final sourceExists = await style.styleSourceExists(_routeSourceId);
      if (sourceExists) {
        await style.removeStyleSource(_routeSourceId);
      }
    } catch (e) {
      debugPrint('Error clearing route: $e');
    }
  }
}
