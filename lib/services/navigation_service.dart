import 'dart:math' as math;
import 'map_service.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();

  factory NavigationService() {
    return _instance;
  }

  NavigationService._internal();

  // Reset progress when starting new navigation
  void resetProgress() {
    // No longer needed - we update dynamically now
  }

  Future<RouteData> getRoute({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    required String destinationName,
  }) async {
    try {
      final routeData = await MapService.getDirections(
        originLat: originLatitude,
        originLng: originLongitude,
        destinationLat: destinationLatitude,
        destinationLng: destinationLongitude,
      );

      // Debug: Print the entire response
      print('Backend response keys: ${routeData.keys.toList()}');
      print('Backend response: $routeData');

      final distance = double.parse(routeData['distance'].toString());

      // Backend returns duration in MINUTES (already divided by 60)
      // Check for different duration field names
      int estimatedMinutes;
      if (routeData.containsKey('duration')) {
        // Backend returns: Math.round(route.duration / 60) - already in minutes!
        estimatedMinutes = int.parse(routeData['duration'].toString());
      } else if (routeData.containsKey('estimatedMinutes')) {
        estimatedMinutes = int.parse(routeData['estimatedMinutes'].toString());
      } else if (routeData.containsKey('durationSeconds')) {
        estimatedMinutes =
            (int.parse(routeData['durationSeconds'].toString()) / 60).toInt();
      } else {
        // Fallback: calculate from distance assuming 5 km/h walking speed
        estimatedMinutes = ((distance / 5) * 60).toInt();
      }

      // Ensure estimated minutes is at least 1
      estimatedMinutes = estimatedMinutes > 0 ? estimatedMinutes : 1;

      final coordinates = (routeData['coordinates'] as List)
          .map(
            (coord) => {
              'latitude': coord['latitude'],
              'longitude': coord['longitude'],
            },
          )
          .toList();

      print('Route calculated:');
      print('Destination: $destinationName');
      print('Distance: ${distance.toStringAsFixed(2)} km');
      print('Duration: ${estimatedMinutes} minutes');
      print('Coordinates count: ${coordinates.length}');

      return RouteData(
        destinationName: destinationName,
        distance: distance,
        estimatedMinutes: estimatedMinutes,
        destinationLat: destinationLatitude,
        destinationLon: destinationLongitude,
        routeCoordinates: coordinates,
      );
    } catch (e) {
      print('Route error: $e');
      rethrow;
    }
  }

  List<Map<String, double>> getRemainingRoute(
    double currentLat,
    double currentLng,
    List<Map<String, dynamic>> fullRoute,
  ) {
    // Find the closest point on the route
    int closestIndex = 0;
    double closestDistance = double.infinity;

    for (int i = 0; i < fullRoute.length; i++) {
      final distance = _calculateDistance(
        currentLat,
        currentLng,
        fullRoute[i]['latitude'] as double,
        fullRoute[i]['longitude'] as double,
      );
      if (distance < closestDistance) {
        closestDistance = distance;
        closestIndex = i;
      }
    }

    return fullRoute.sublist(closestIndex).cast<Map<String, double>>();
  }

  // Check if user is off-path (too far from route)
  double getDistanceFromRoute(
    double currentLat,
    double currentLng,
    List<Map<String, dynamic>> fullRoute,
  ) {
    double minDistance = double.infinity;

    for (var point in fullRoute) {
      final distance = _calculateDistance(
        currentLat,
        currentLng,
        point['latitude'] as double,
        point['longitude'] as double,
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance;
  }

  double calculateRemainingDistance(
    double currentLat,
    double currentLng,
    List<Map<String, double>> remainingRoute,
  ) {
    if (remainingRoute.isEmpty) return 0;

    double totalDistance = 0;

    totalDistance += _calculateDistance(
      currentLat,
      currentLng,
      remainingRoute[0]['latitude']!,
      remainingRoute[0]['longitude']!,
    );

    for (int i = 0; i < remainingRoute.length - 1; i++) {
      totalDistance += _calculateDistance(
        remainingRoute[i]['latitude']!,
        remainingRoute[i]['longitude']!,
        remainingRoute[i + 1]['latitude']!,
        remainingRoute[i + 1]['longitude']!,
      );
    }

    return totalDistance;
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}

class RouteData {
  final String destinationName;
  final double distance;
  final int estimatedMinutes;
  final double destinationLat;
  final double destinationLon;
  final List<Map<String, dynamic>> routeCoordinates;

  RouteData({
    required this.destinationName,
    required this.distance,
    required this.estimatedMinutes,
    required this.destinationLat,
    required this.destinationLon,
    required this.routeCoordinates,
  });
}
