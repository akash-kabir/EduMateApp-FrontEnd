import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../services/navigation_service.dart';
import '../../services/map_service.dart';
import '../../poi.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String searchQuery = '';
  mapbox.MapboxMap? mapboxMap;
  mapbox.PointAnnotationManager? pointAnnotationManager;
  mapbox.PolylineAnnotationManager? polylineAnnotationManager;
  mapbox.PointAnnotation? campusMarkerAnnotation;
  mapbox.PolylineAnnotation? routeLineAnnotation;
  double? currentLatitude;
  double? currentLongitude;
  List<CampusLocation> filteredCampuses = [];
  bool showSuggestions = false;
  bool showNavigateCard = false;
  bool isFullScreenSearch = false;
  bool is3DMode = false;
  List<String> recentSearches = [];
  CampusLocation? selectedCampus;
  late TextEditingController _searchController;

  bool isNavigating = false;
  bool destinationReached = false;
  RouteData? currentRoute;
  double remainingDistance = 0;
  int remainingMinutes = 0;
  List<Map<String, dynamic>> remainingRoutePositions = [];
  DateTime? _lastRerouteTime;

  bool _isMapLoading = true;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initializeMapbox();
    _requestLocationPermission();
  }

  Future<void> _initializeMapbox() async {
    try {
      final token = await MapService.getMapboxPublicKey();
      // Set access token for Mapbox
      mapbox.MapboxOptions.setAccessToken(token);

      if (mounted) {
        setState(() {
          _mapReady = true;
          _isMapLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMapLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final permission = await geolocator.Geolocator.requestPermission();
    if (permission == geolocator.LocationPermission.denied ||
        permission == geolocator.LocationPermission.deniedForever) {
      return;
    }
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high,
      );

      setState(() {
        currentLatitude = position.latitude;
        currentLongitude = position.longitude;
      });

      if (mapboxMap != null) {
        _startLocationTracking();
      }
    } catch (e) {}
  }

  void _startLocationTracking() {
    geolocator.Geolocator.getPositionStream(
      locationSettings: const geolocator.LocationSettings(
        accuracy: geolocator.LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((geolocator.Position position) {
      setState(() {
        currentLatitude = position.latitude;
        currentLongitude = position.longitude;
      });

      if (isNavigating && currentRoute != null) {
        _updateNavigationProgress(position.latitude, position.longitude);
      }
    });
  }

  void _updateNavigationProgress(double lat, double lon) {
    if (currentRoute == null) return;

    try {
      final navService = NavigationService();

      final distanceFromRoute = navService.getDistanceFromRoute(
        lat,
        lon,
        currentRoute!.routeCoordinates,
      );

      const double offPathThreshold = 0.05;

      if (distanceFromRoute > offPathThreshold) {
        final now = DateTime.now();
        if (_lastRerouteTime == null ||
            now.difference(_lastRerouteTime!).inSeconds >= 5) {
          _lastRerouteTime = now;
          _rerouteNavigation(lat, lon);
          return;
        }
      }

      final remaining = navService.getRemainingRoute(
        lat,
        lon,
        currentRoute!.routeCoordinates,
      );

      final remainingDist = navService.calculateRemainingDistance(
        lat,
        lon,
        remaining,
      );

      final progressRatio = 1.0 - (remainingDist / currentRoute!.distance);
      final timeElapsed = (currentRoute!.estimatedMinutes * progressRatio)
          .toInt();
      final newRemainingMinutes = currentRoute!.estimatedMinutes - timeElapsed;

      setState(() {
        remainingDistance = remainingDist;
        remainingMinutes = newRemainingMinutes > 0 ? newRemainingMinutes : 1;
        remainingRoutePositions = [
          {'latitude': lat, 'longitude': lon},
          ...remaining,
        ];
      });

      _updateRouteLine(remainingRoutePositions);

      if (remainingDist < 0.005) {
        _arrivedAtDestination();
      }
    } catch (e) {}
  }

  Future<void> _rerouteNavigation(double currentLat, double currentLng) async {
    try {
      final newRoute = await NavigationService().getRoute(
        originLatitude: currentLat,
        originLongitude: currentLng,
        destinationLatitude: currentRoute!.destinationLat,
        destinationLongitude: currentRoute!.destinationLon,
        destinationName: currentRoute!.destinationName,
      );

      setState(() {
        currentRoute = newRoute;
        remainingDistance = newRoute.distance;
        remainingMinutes = newRoute.estimatedMinutes;
        remainingRoutePositions = newRoute.routeCoordinates;
      });

      _updateRouteLine(remainingRoutePositions);
    } catch (e) {}
  }

  Future<void> _drawRouteLine(List<Map<String, dynamic>> positions) async {
    if (mapboxMap == null || positions.isEmpty) return;

    try {
      polylineAnnotationManager = await mapboxMap!.annotations
          .createPolylineAnnotationManager();

      final polylinePositions = positions
          .map<mapbox.Position>(
            (p) => mapbox.Position(
              p['longitude'] as double,
              p['latitude'] as double,
            ),
          )
          .toList();

      final polylineOptions = mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(coordinates: polylinePositions),
        lineColor: Colors.blue.value,
        lineWidth: 5.0,
        lineEmissiveStrength: 0.8,
      );

      routeLineAnnotation = await polylineAnnotationManager?.create(
        polylineOptions,
      );
    } catch (e) {}
  }

  Future<void> _updateRouteLine(List<Map<String, dynamic>> positions) async {
    if (positions.isEmpty) return;

    try {
      if (polylineAnnotationManager == null) {
        await _drawRouteLine(positions);
        return;
      }

      if (routeLineAnnotation != null) {
        final polylinePositions = positions
            .map<mapbox.Position>(
              (p) => mapbox.Position(
                p['longitude'] as double,
                p['latitude'] as double,
              ),
            )
            .toList();
        routeLineAnnotation!.geometry = mapbox.LineString(
          coordinates: polylinePositions,
        );
        routeLineAnnotation!.lineColor = Colors.blue.value;
        routeLineAnnotation!.lineEmissiveStrength = 0.8;

        await polylineAnnotationManager?.update(routeLineAnnotation!);
      } else {
        await _drawRouteLine(positions);
      }
    } catch (e) {
      try {
        await _drawRouteLine(positions);
      } catch (e2) {}
    }
  }

  void _arrivedAtDestination() {
    setState(() {
      isNavigating = false;
      destinationReached = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          destinationReached = false;
          currentRoute = null;
          remainingRoutePositions = [];
          searchQuery = '';
          filteredCampuses = [];
          showSuggestions = false;
          _searchController.clear();
        });
        if (routeLineAnnotation != null) {
          polylineAnnotationManager?.delete(routeLineAnnotation!);
        }
      }
    });
  }

  void _recenterToCurrentLocation() async {
    if (mapboxMap == null ||
        currentLatitude == null ||
        currentLongitude == null) {
      return;
    }

    try {
      await mapboxMap!.easeTo(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(currentLongitude!, currentLatitude!),
          ),
          zoom: 15.0,
        ),
        mapbox.MapAnimationOptions(duration: 500),
      );
    } catch (e) {}
  }

  void _filterCampuses(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredCampuses = [];
        showSuggestions = false;
      } else {
        filteredCampuses = campusLocations
            .where(
              (campus) =>
                  campus.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
        showSuggestions = filteredCampuses.isNotEmpty;
      }
    });
  }

  void _enterFullScreenSearch() {
    setState(() {
      isFullScreenSearch = true;
      searchQuery = '';
      filteredCampuses = [];
      _searchController.clear();
      showSuggestions = false;
    });
  }

  void _addToRecentSearches(String campusName) {
    recentSearches.removeWhere((item) => item == campusName);
    recentSearches.insert(0, campusName);
    if (recentSearches.length > 10) {
      recentSearches = recentSearches.sublist(0, 10);
    }
  }

  void _navigateToCampus(CampusLocation campus) async {
    if (mapboxMap == null) return;

    FocusScope.of(context).unfocus();

    _addToRecentSearches(campus.name);

    if (isNavigating) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: const Text('Stop Navigation?'),
          content: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'You are navigating to ${currentRoute?.destinationName}.\n\nDo you want to stop and navigate to ${campus.name} instead?',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  isFullScreenSearch = false;
                });
                _proceedWithNavigation(campus);
              },
              child: const Text('Switch Navigation'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      isFullScreenSearch = false;
    });
    _proceedWithNavigation(campus);
  }

  void _proceedWithNavigation(CampusLocation campus) async {
    if (mapboxMap == null) return;

    try {
      setState(() {
        searchQuery = '';
        filteredCampuses = [];
        showSuggestions = false;
        _searchController.clear();
        isFullScreenSearch = false;
        selectedCampus = campus;
        showNavigateCard = true;
        isNavigating = false;
        destinationReached = false;
        currentRoute = null;
        remainingRoutePositions.clear();
      });

      if (campusMarkerAnnotation != null) {
        await pointAnnotationManager?.delete(campusMarkerAnnotation!);
      }

      if (routeLineAnnotation != null && polylineAnnotationManager != null) {
        try {
          await polylineAnnotationManager?.delete(routeLineAnnotation!);
        } catch (e) {}
        routeLineAnnotation = null;
      }

      await _addCampusMarker(campus.latitude, campus.longitude, campus.name);

      await Future.delayed(const Duration(milliseconds: 300));

      await mapboxMap!.easeTo(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(campus.longitude, campus.latitude),
          ),
          zoom: 17.0,
        ),
        mapbox.MapAnimationOptions(duration: 1200),
      );
    } catch (e) {}
  }

  Future<void> _startNavigation() async {
    if (selectedCampus == null ||
        currentLatitude == null ||
        currentLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location not available')),
      );
      return;
    }

    try {
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();

      // Check if no connectivity
      bool hasConnection = (result != ConnectivityResult.none);

      if (!hasConnection) {
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (BuildContext context) => CupertinoAlertDialog(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.wifi_slash,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text('No Internet Connection'),
                ],
              ),
              content: const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'You\'re offline! Connect to WiFi or mobile data to use navigation.',
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Got it'),
                ),
              ],
            ),
          );
        }
        return;
      }
    } catch (e) {}

    try {
      NavigationService().resetProgress();

      if (routeLineAnnotation != null && polylineAnnotationManager != null) {
        try {
          await polylineAnnotationManager?.delete(routeLineAnnotation!);
        } catch (e) {}
        routeLineAnnotation = null;
      }

      final route = await NavigationService().getRoute(
        originLatitude: currentLatitude!,
        originLongitude: currentLongitude!,
        destinationLatitude: selectedCampus!.latitude,
        destinationLongitude: selectedCampus!.longitude,
        destinationName: selectedCampus!.name,
      );

      setState(() {
        isNavigating = true;
        currentRoute = route;
        remainingDistance = route.distance;
        remainingMinutes = route.estimatedMinutes;
        remainingRoutePositions = route.routeCoordinates;
      });

      await _drawRouteLine(remainingRoutePositions);
      await _fitMapToPolyline(remainingRoutePositions);

      setState(() {
        showNavigateCard = false;
      });
    } catch (e) {}
  }

  Future<void> _fitMapToPolyline(List<Map<String, dynamic>> positions) async {
    if (mapboxMap == null || positions.isEmpty) return;

    try {
      double minLat = positions[0]['latitude'];
      double maxLat = positions[0]['latitude'];
      double minLon = positions[0]['longitude'];
      double maxLon = positions[0]['longitude'];

      for (var pos in positions) {
        final lat = pos['latitude'] as double;
        final lon = pos['longitude'] as double;
        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
        if (lon < minLon) minLon = lon;
        if (lon > maxLon) maxLon = lon;
      }

      final centerLat = (minLat + maxLat) / 2;
      final centerLon = (minLon + maxLon) / 2;

      final latDiff = maxLat - minLat;
      final lonDiff = maxLon - minLon;
      final maxDiff = latDiff > lonDiff ? latDiff : lonDiff;

      double zoomLevel = 15.0;
      if (maxDiff > 0.05) zoomLevel = 14.0;
      if (maxDiff > 0.1) zoomLevel = 13.0;
      if (maxDiff > 0.2) zoomLevel = 12.0;
      if (maxDiff > 0.5) zoomLevel = 11.0;

      await mapboxMap!.easeTo(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(centerLon, centerLat),
          ),
          zoom: zoomLevel,
        ),
        mapbox.MapAnimationOptions(duration: 1200),
      );
    } catch (e) {}
  }

  Future<void> _addCampusMarker(
    double latitude,
    double longitude,
    String name,
  ) async {
    if (pointAnnotationManager == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(pictureRecorder);
      const double radius = 16;

      final ui.Paint paint = ui.Paint()
        ..color = Colors.red
        ..style = ui.PaintingStyle.fill;
      canvas.drawCircle(const ui.Offset(radius, radius), radius, paint);

      final ui.Image image = await pictureRecorder.endRecording().toImage(
        (radius * 2).toInt(),
        (radius * 2).toInt(),
      );
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List imageBytes = byteData!.buffer.asUint8List();

      final mapbox.PointAnnotationOptions pointAnnotationOptions =
          mapbox.PointAnnotationOptions(
            geometry: mapbox.Point(
              coordinates: mapbox.Position(longitude, latitude),
            ),
            image: imageBytes,
            textField: name,
            textAnchor: mapbox.TextAnchor.TOP,
            textSize: 14,
            textColor: isDark ? Colors.white.value : Colors.black.value,
            textHaloColor: isDark ? Colors.black.value : Colors.white.value,
            textHaloWidth: 1.5,
            textOffset: [0, 0.8],
          );

      campusMarkerAnnotation = await pointAnnotationManager?.create(
        pointAnnotationOptions,
      );
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Colors.black : CupertinoColors.white,
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            if (_mapReady)
              Positioned.fill(
                child: mapbox.MapWidget(
                  key: const ValueKey("mapWidget"),
                  cameraOptions: mapbox.CameraOptions(
                    center: mapbox.Point(
                      coordinates: mapbox.Position(85.8245, 20.2961),
                    ),
                    zoom: 12.0,
                  ),
                  styleUri:
                      'mapbox://styles/akash-kabir/cmizvo5eq003a01sb5ka4hksz',
                  onMapCreated: (mapbox.MapboxMap map) async {
                    mapboxMap = map;
                    // Hide default UI elements
                    await map.compass.updateSettings(
                      mapbox.CompassSettings(enabled: false),
                    );
                    await map.scaleBar.updateSettings(
                      mapbox.ScaleBarSettings(enabled: false),
                    );
                    await map.attribution.updateSettings(
                      mapbox.AttributionSettings(enabled: false),
                    );
                    // Enable location puck
                    await map.location.updateSettings(
                      mapbox.LocationComponentSettings(enabled: true),
                    );
                    pointAnnotationManager = await map.annotations
                        .createPointAnnotationManager();
                    _getCurrentLocation();

                    if (mounted) {
                      setState(() {
                        _isMapLoading = false;
                      });
                    }
                  },
                ),
              )
            else if (_isMapLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CupertinoActivityIndicator(
                      radius: 15,
                      animating: true,
                    ),
                  ),
                ),
              ),
            if (!isFullScreenSearch)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoSearchTextField(
                        placeholder: 'Search locations',
                        onChanged: _filterCampuses,
                        controller: _searchController,
                        backgroundColor: isDark
                            ? Colors.grey[900]
                            : Colors.grey[200],
                        onTap: _enterFullScreenSearch,
                      ),
                    ],
                  ),
                ),
              ),
            if (isFullScreenSearch)
              Positioned.fill(
                child: Container(
                  color: (isDark ? Colors.black : Colors.white).withOpacity(
                    0.95,
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: CupertinoSearchTextField(
                            placeholder: 'Search locations',
                            onChanged: _filterCampuses,
                            controller: _searchController,
                            backgroundColor: isDark
                                ? Colors.grey[900]
                                : Colors.grey[200],
                            autofocus: true,
                            suffixMode: OverlayVisibilityMode.always,
                            onSuffixTap: () {
                              _searchController.clear();
                              setState(() {
                                isFullScreenSearch = false;
                                searchQuery = '';
                                showSuggestions = false;
                                filteredCampuses = [];
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: filteredCampuses.isEmpty
                              ? (searchQuery.isEmpty
                                    ? (recentSearches.isEmpty
                                          ? Center(
                                              child: Text(
                                                'No recent searches',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.grey[400]
                                                      : Colors.grey[600],
                                                  fontSize: 16,
                                                ),
                                              ),
                                            )
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  child: Text(
                                                    'Recent Searches',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isDark
                                                          ? Colors.white
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: ListView.builder(
                                                    itemCount:
                                                        recentSearches.length,
                                                    itemBuilder: (context, index) {
                                                      final searchTerm =
                                                          recentSearches[index];
                                                      return CupertinoButton(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                              vertical: 16,
                                                            ),
                                                        onPressed: () {
                                                          _searchController
                                                                  .text =
                                                              searchTerm;
                                                          _filterCampuses(
                                                            searchTerm,
                                                          );
                                                        },
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              CupertinoIcons
                                                                  .clock_solid,
                                                              color:
                                                                  Colors.grey,
                                                              size: 20,
                                                            ),
                                                            const SizedBox(
                                                              width: 16,
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                searchTerm,
                                                                style: TextStyle(
                                                                  color: isDark
                                                                      ? Colors
                                                                            .white
                                                                      : Colors
                                                                            .black,
                                                                  fontSize: 16,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ))
                                    : Center(
                                        child: Text(
                                          'No results found',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                      ))
                              : ListView.builder(
                                  itemCount: filteredCampuses.length,
                                  itemBuilder: (context, index) {
                                    final campus = filteredCampuses[index];
                                    return CupertinoButton(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      onPressed: () =>
                                          _navigateToCampus(campus),
                                      child: Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.location_solid,
                                            color: Colors.red,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              campus.name,
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!showSuggestions && !isFullScreenSearch)
              Positioned(
                top: 62,
                right: 12,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.black : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CupertinoButton(
                          padding: const EdgeInsets.all(8),
                          onPressed: _recenterToCurrentLocation,
                          child: Icon(
                            CupertinoIcons.location_fill,
                            color: isDark ? Colors.white : Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.black : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CupertinoButton(
                          padding: const EdgeInsets.all(8),
                          onPressed: () async {
                            if (mapboxMap != null) {
                              await mapboxMap!.easeTo(
                                mapbox.CameraOptions(bearing: 0),
                                mapbox.MapAnimationOptions(duration: 600),
                              );
                            }
                          },
                          child: Icon(
                            CupertinoIcons.compass,
                            color: isDark ? Colors.white : Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.black : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CupertinoButton(
                          padding: const EdgeInsets.all(8),
                          onPressed: () async {
                            if (mapboxMap != null) {
                              if (is3DMode) {
                                await mapboxMap!.easeTo(
                                  mapbox.CameraOptions(pitch: 0),
                                  mapbox.MapAnimationOptions(duration: 600),
                                );
                              } else {
                                await mapboxMap!.easeTo(
                                  mapbox.CameraOptions(pitch: 45),
                                  mapbox.MapAnimationOptions(duration: 600),
                                );
                              }
                              setState(() {
                                is3DMode = !is3DMode;
                              });
                            }
                          },
                          child: Text(
                            '3D',
                            style: TextStyle(
                              color: is3DMode
                                  ? Colors.blue
                                  : (isDark ? Colors.white : Colors.black),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (showNavigateCard &&
                selectedCampus != null &&
                !isFullScreenSearch)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.grey[850] : Colors.white)
                              ?.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.location_solid,
                                  color: Colors.red,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    selectedCampus!.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() {
                                      showNavigateCard = false;
                                      selectedCampus = null;
                                      searchQuery = '';
                                      filteredCampuses = [];
                                      showSuggestions = false;
                                      _searchController.clear();
                                    });
                                  },
                                  child: Icon(
                                    CupertinoIcons.xmark_circle_fill,
                                    color: Colors.grey,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: CupertinoButton(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(12),
                                    onPressed: _startNavigation,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          CupertinoIcons.arrow_turn_up_right,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Navigate',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (isNavigating && currentRoute != null && !isFullScreenSearch)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.grey[850] : Colors.white)
                              ?.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentRoute!.destinationName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value:
                                    1 -
                                    (remainingDistance / currentRoute!.distance)
                                        .clamp(0, 1),
                                minHeight: 6,
                                backgroundColor: Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Distance',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      '${remainingDistance.toStringAsFixed(2)} km',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'ETA',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.directions_walk,
                                          size: 16,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$remainingMinutes min',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                color: Colors.red,
                                onPressed: () {
                                  setState(() {
                                    isNavigating = false;
                                    currentRoute = null;
                                    remainingRoutePositions = [];
                                  });
                                  if (routeLineAnnotation != null) {
                                    polylineAnnotationManager?.delete(
                                      routeLineAnnotation!,
                                    );
                                  }
                                },
                                child: const Text(
                                  'End Navigation',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (destinationReached &&
                currentRoute != null &&
                !isFullScreenSearch)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.grey[850] : Colors.white)
                              ?.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.checkmark_alt_circle_fill,
                                  color: Colors.green,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Destination Reached',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        currentRoute!.destinationName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
