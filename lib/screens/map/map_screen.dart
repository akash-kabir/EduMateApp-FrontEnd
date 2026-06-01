// ignore_for_file: unused_element

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import '../../services/map_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  mapbox.MapboxMap? mapboxMap;
  mapbox.PointAnnotationManager? pointAnnotationManager;
  mapbox.PointAnnotation? campusMarkerAnnotation;
  double? currentLatitude;
  double? currentLongitude;
  bool is3DMode = false;

  bool _isMapLoading = true;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _initializeMapbox();
    _requestLocationPermission();
  }

  Future<void> _initializeMapbox() async {
    try {
      final token = await MapService.getMapboxPublicKey();
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
    });
  }

  Future<void> _recenterToCurrentLocation() async {
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
                  key: const ValueKey('mapWidget'),
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
                    await map.compass.updateSettings(
                      mapbox.CompassSettings(enabled: false),
                    );
                    await map.scaleBar.updateSettings(
                      mapbox.ScaleBarSettings(enabled: false),
                    );
                    await map.attribution.updateSettings(
                      mapbox.AttributionSettings(enabled: false),
                    );
                    await map.location.updateSettings(
                      mapbox.LocationComponentSettings(enabled: true),
                    );
                    pointAnnotationManager =
                        await map.annotations.createPointAnnotationManager();
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
          ],
        ),
      ),
    );
  }
}
