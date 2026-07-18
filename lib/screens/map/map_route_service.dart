import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter/material.dart';
import '../../services/map_service.dart';

class MapRouteService {
  static const String _routeSourceId = 'route-source';
  static const String _routeLayerId = 'route-layer';

  /// Fetches the route from Mapbox Directions API and draws it on the map.
  /// Returns a map with 'distance' (meters) and 'duration' (seconds), or null if failed.
  static Future<Map<String, dynamic>?> drawRoute({
    required MapboxMap mapboxMap,
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    Color routeColor = const Color(0xFF00BFA5), // Default to teal
    double lineWidth = 5.0,
  }) async {
    try {
      final token = await MapService.getMapboxPublicKey();
      
      // Mapbox Directions API URL (driving profile)
      // Note: Mapbox uses longitude,latitude format
      final url = Uri.parse(
          'https://api.mapbox.com/directions/v5/mapbox/driving/$originLng,$originLat;$destLng,$destLat?geometries=geojson&overview=full&access_token=$token');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final routeGeometry = route['geometry'];
          final distance = route['distance']; // in meters
          final duration = route['duration']; // in seconds
          
          // Clear existing route if any
          await clearRoute(mapboxMap);

          // Add GeoJSON source
          final geoJsonStr = json.encode(routeGeometry);
          await mapboxMap.style.addSource(
            GeoJsonSource(
              id: _routeSourceId,
              data: geoJsonStr,
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

          return {
            'distance': distance,
            'duration': duration,
          };
        } else {
          throw Exception('No routes found');
        }
      } else {
        throw Exception('Failed to fetch directions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error drawing route: $e');
      return null;
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
