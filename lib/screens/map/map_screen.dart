import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import '../../models/poi_model.dart';
import '../../widgets/custom_glass_dialog.dart';
import '../../services/shared_preferences_service.dart';
import 'map_route_service.dart';
import 'navigation_manager.dart';
import 'widgets/navigation_status_card.dart';
import '../../services/poi_service.dart';
import '../../services/map_service.dart';
import '../../constants/app_constants.dart';
import 'map_action_buttons.dart';
import 'map_search_bar.dart';

class PoiAnnotationClickListener extends mapbox.OnPointAnnotationClickListener {
  final Function(mapbox.PointAnnotation) onAnnotationClickCallback;
  PoiAnnotationClickListener(this.onAnnotationClickCallback);
  
  @override
  void onPointAnnotationClick(mapbox.PointAnnotation annotation) {
    onAnnotationClickCallback(annotation);
  }
}

class MapScreen extends StatefulWidget {
  final ValueChanged<bool>? onNavBarVisibilityChange;
  
  const MapScreen({super.key, this.onNavBarVisibilityChange});

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
  bool isFullScreenSearch = false;
  bool isMapMenuExpanded = false;

  bool _isMapLoading = true;
  bool _mapReady = false;

  List<PoiModel> _filteredPois = [];
  PoiModel? _selectedPoi;
  bool _isPoiCardExpanded = false;
  final TextEditingController _searchController = TextEditingController();

  final NavigationManager _navigationManager = NavigationManager();

  Map<String, PoiModel> _annotationIdToPoi = {};
  PoiAnnotationClickListener? _poiClickListener;

  @override
  void initState() {
    super.initState();
    _navigationManager.addListener(_onNavigationStateChanged);
    _initializeMapbox();
    _requestLocationPermission();
    _loadPOIs();
  }
  
  void _onNavigationStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadPOIs() async {
    try {
      final pois = await PoiService.getPOIs();
      if (mounted) {
        setState(() {
          _pois = pois;
          _filteredPois = pois;
        });
        _renderPOIs();
      }
    } catch (e) {
      debugPrint('Error loading POIs: $e');
    }
  }

  @override
  void dispose() {
    _navigationManager.removeListener(_onNavigationStateChanged);
    _navigationManager.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPois = List.from(_pois);
      } else {
        _filteredPois = _pois
            .where((poi) =>
                poi.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
    _renderPOIs();
  }

  void _navigateToPoi(PoiModel poi) {
    if (mapboxMap == null) return;
    
    // Close search and set selected POI
    setState(() {
      isFullScreenSearch = false;
      _searchController.clear();
      _filteredPois = List.from(_pois);
      _selectedPoi = poi;
      _isPoiCardExpanded = false;
    });
    _renderPOIs();
    
    // Move camera
    mapboxMap?.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(poi.lng, poi.lat),
        ),
        zoom: 15.0,
      ),
      mapbox.MapAnimationOptions(duration: 1000),
    );
  }

  void _onMarkerTapped(mapbox.PointAnnotation annotation) {
    final poi = _annotationIdToPoi[annotation.id];
    if (poi != null) {
      setState(() {
        _selectedPoi = poi;
        _isPoiCardExpanded = false;
      });
      mapboxMap?.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(poi.lng, poi.lat),
          ),
          zoom: 15.0,
        ),
        mapbox.MapAnimationOptions(duration: 1000),
      );
    }
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
      if (mounted) {
        setState(() {
          currentLatitude = position.latitude;
          currentLongitude = position.longitude;
        });
        
        if (mapboxMap != null) {
          _navigationManager.onLocationUpdated(mapboxMap!, position.latitude, position.longitude);
        }
      }
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

  List<PoiModel> _pois = [];


  Future<void> _renderPOIs() async {
    if (mapboxMap == null || pointAnnotationManager == null) return;

    debugPrint('>>> _renderPOIs called, selectedPoi: ${_selectedPoi?.name}');

    // Step 1: Remove all existing markers from this manager
    try {
      await pointAnnotationManager?.deleteAll();
    } catch (e) {
      debugPrint('>>> ERROR deleting annotations: $e');
    }
    _annotationIdToPoi.clear();

    // Step 2: If no POI selected, we're done
    if (_selectedPoi == null) {
      debugPrint('>>> No selected POI, map cleared.');
      return;
    }

    // Step 3: Build annotation options for the selected POI
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<mapbox.PointAnnotationOptions> options = [];

    try {
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(pictureRecorder);
      const double radius = 16;

      final ui.Paint paint = ui.Paint()
        ..color = _getColorForType(_selectedPoi!.type)
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

      options.add(mapbox.PointAnnotationOptions(
        geometry: mapbox.Point(
          coordinates: mapbox.Position(_selectedPoi!.lng, _selectedPoi!.lat),
        ),
        image: imageBytes,
        textField: _selectedPoi!.name,
        textAnchor: mapbox.TextAnchor.TOP,
        textSize: 14,
        textColor: isDark ? Colors.white.value : Colors.black.value,
        textHaloColor: isDark ? Colors.black.value : Colors.white.value,
        textHaloWidth: 1.5,
        textOffset: [0, 0.8],
      ));
    } catch (e) {
      debugPrint('Error creating annotation for ${_selectedPoi!.name}: $e');
    }

    // Step 4: Add annotations
    if (options.isNotEmpty) {
      try {
        final annotations = await pointAnnotationManager?.createMulti(options);
        debugPrint('>>> Created ${annotations?.length} annotations');
        if (annotations != null && annotations.isNotEmpty) {
          final annotation = annotations.first;
          if (annotation != null) {
            _annotationIdToPoi[annotation.id] = _selectedPoi!;
          }
        }
      } catch (e) {
        debugPrint('>>> ERROR creating annotations: $e');
      }
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'Hotel':
        return Colors.blue;
      case 'Gardens':
        return Colors.green;
      case 'Stadium':
        return Colors.orange;
      case 'Cafeteria':
        return Colors.brown;
      case 'Campus':
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? Colors.black : CupertinoColors.white,
      child: SafeArea(
        top: false,
        bottom: false,
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
                    onTapListener: (ctx) {
                      if (_selectedPoi != null) {
                        setState(() {
                          _selectedPoi = null;
                        });
                        _renderPOIs();
                      }
                    },
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

                    // Hide built-in POI layers from Mapbox style
                    try {
                      final style = map.style;
                      final layers = await style.getStyleLayers();
                      debugPrint('=== ALL MAPBOX STYLE LAYERS ===');
                      for (var layer in layers) {
                        final id = layer?.id ?? '';
                        debugPrint('Layer: $id');
                        if (id.contains('poi') || id.contains('label') || id.contains('place') || id.contains('marker')) {
                          debugPrint('  -> HIDING: $id');
                          await style.setStyleLayerProperty(id, 'visibility', 'none');
                        }
                      }
                      debugPrint('=== END LAYERS ===');
                    } catch (e) {
                      debugPrint('Could not hide POI layers: $e');
                    }

                    pointAnnotationManager =
                        await map.annotations.createPointAnnotationManager();
                    _poiClickListener = PoiAnnotationClickListener(_onMarkerTapped);
                    pointAnnotationManager?.addOnPointAnnotationClickListener(_poiClickListener!);
                    _renderPOIs();
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
            if (isFullScreenSearch)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isFullScreenSearch = false;
                    });
                  },
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.4),
                      child: SafeArea(
                        child: Column(
                          children: [
                            const SizedBox(height: 66),
                            Expanded(
                              child: _filteredPois.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No results found',
                                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: _filteredPois.length,
                                      itemBuilder: (context, index) {
                                        final poi = _filteredPois[index];
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.grey[850] : Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                                          ),
                                          child: Material(
                                            type: MaterialType.transparency,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(12),
                                              onTap: () => _navigateToPoi(poi),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                child: Row(
                                                  children: [
                                                    Icon(CupertinoIcons.map_pin_ellipse, color: _getColorForType(poi.type)),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(poi.name, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                                                          const SizedBox(height: 4),
                                                          Text(poi.type, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
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
                ),
              ),
            // Unified Search Pill & Toolbar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MapSearchBar(
                      isFullScreenSearch: isFullScreenSearch,
                      isDark: isDark,
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onClear: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      onToggleSearch: () {
                        if (isFullScreenSearch) {
                          setState(() {
                            isFullScreenSearch = false;
                            _searchController.clear();
                            _filteredPois = List.from(_pois);
                          }); 
                          _renderPOIs();
                          FocusScope.of(context).unfocus();
                        } else {
                          setState(() {
                            isFullScreenSearch = true;
                            if (_selectedPoi != null) {
                              _selectedPoi = null;
                              _isPoiCardExpanded = false;
                              _renderPOIs();
                            }
                          });
                        }
                      },
                    ),
                    MapActionButtons(
                      isFullScreenSearch: isFullScreenSearch,
                      isMapMenuExpanded: isMapMenuExpanded,
                      is3DMode: is3DMode,
                      isDark: isDark,
                      onToggleMenu: () {
                        setState(() {
                          isMapMenuExpanded = true;
                        });
                      },
                      onRecenter: () {
                        _recenterToCurrentLocation();
                        setState(() => isMapMenuExpanded = false);
                      },
                      onCompass: () async {
                        if (mapboxMap != null) {
                          await mapboxMap!.easeTo(
                            mapbox.CameraOptions(bearing: 0),
                            mapbox.MapAnimationOptions(duration: 600),
                          );
                        }
                        setState(() => isMapMenuExpanded = false);
                      },
                      onToggle3D: () async {
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
                            isMapMenuExpanded = false;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // POI Detail Card overlay
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _selectedPoi != null ? 85 : -300,
              left: 10,
              right: 10,
              child: _selectedPoi == null ? const SizedBox() : _buildPoiDetailCard(_selectedPoi!, isDark),
            ),
            
            // Navigation Status Card overlay
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _navigationManager.isNavigating ? 40 : -150, // Pushed to 40 so it sits nicely when nav bar is hidden
              left: 16,
              right: 16,
              child: _navigationManager.isNavigating && _navigationManager.target != null 
                  ? NavigationStatusCard(
                      isDark: isDark,
                      poiName: _navigationManager.target!.name,
                      distanceInMeters: _navigationManager.distanceRemaining,
                      onStopNavigation: () {
                        if (mapboxMap != null) {
                          _navigationManager.stopNavigation(mapboxMap!);
                        }
                        if (widget.onNavBarVisibilityChange != null) {
                          widget.onNavBarVisibilityChange!(true); // show nav bar again
                        }
                        _recenterToCurrentLocation();
                      },
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoiDetailCard(PoiModel poi, bool isDark) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isPoiCardExpanded = !_isPoiCardExpanded;
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.5),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image section
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: _isPoiCardExpanded ? 180 : 140,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          poi.imageUrl.isNotEmpty
                              ? Image.network(poi.imageUrl, fit: BoxFit.cover)
                              : Container(
                                  color: isDark ? Colors.black26 : Colors.black12,
                                  child: const Icon(CupertinoIcons.photo, size: 40, color: CupertinoColors.systemGrey),
                                ),
                          // Gradient
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 60,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: _isPoiCardExpanded ? 0.0 : 1.0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black87],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content section
                    AnimatedPadding(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        top: _isPoiCardExpanded ? 44.0 : 16.0,
                        bottom: 16.0
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Venue Type
                          Text(
                            'University • ${poi.type}',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          
                          // Expanded details
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 300),
                            crossFadeState: _isPoiCardExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            firstChild: const SizedBox(width: double.infinity, height: 0),
                            secondChild: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                // Description
                                SizedBox(
                                  height: 95,
                                  child: Text(
                                    poi.description.isNotEmpty ? poi.description : 'No description available.',
                                    style: TextStyle(
                                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                                      fontSize: 14,
                                      height: 1.3,
                                    ),
                                    maxLines: 5,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Navigate Button
                          SizedBox(
                            width: double.infinity,
                            child: CupertinoButton(
                              color: AuthPalette.teal,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              borderRadius: BorderRadius.circular(12),
                              onPressed: () async {
                                if (currentLatitude == null || currentLongitude == null || mapboxMap == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Current location not available')),
                                  );
                                  return;
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Generating route...')),
                                );

                                await _navigationManager.startNavigation(
                                  mapboxMap!,
                                  poi,
                                  currentLatitude!,
                                  currentLongitude!,
                                );
                                
                                // Adjust camera to fit route (roughly)
                                final bounds = mapbox.CoordinateBounds(
                                  southwest: mapbox.Point(
                                    coordinates: mapbox.Position(
                                      currentLongitude! < poi.lng ? currentLongitude! : poi.lng,
                                      currentLatitude! < poi.lat ? currentLatitude! : poi.lat,
                                    )
                                  ),
                                  northeast: mapbox.Point(
                                    coordinates: mapbox.Position(
                                      currentLongitude! > poi.lng ? currentLongitude! : poi.lng,
                                      currentLatitude! > poi.lat ? currentLatitude! : poi.lat,
                                    )
                                  ),
                                  infiniteBounds: false,
                                );
                                
                                mapboxMap?.cameraForCoordinateBounds(
                                  bounds,
                                  mapbox.MbxEdgeInsets(top: 100, left: 50, bottom: 200, right: 50),
                                  null, null, null, null,
                                ).then((cameraOptions) {
                                  mapboxMap?.easeTo(
                                    cameraOptions,
                                    mapbox.MapAnimationOptions(duration: 1000),
                                  );
                                });
                                
                                setState(() {
                                  _isPoiCardExpanded = false;
                                  _selectedPoi = null; // hide the POI card
                                });
                                
                                if (widget.onNavBarVisibilityChange != null) {
                                  widget.onNavBarVisibilityChange!(false); // hide nav bar while navigating
                                }
                              },
                              child: const Text(
                                'Navigate (In-App)',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // The Animated Text (Title)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: _isPoiCardExpanded ? 196 : 108,
                  left: 16,
                  right: 48,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: _isPoiCardExpanded 
                          ? (isDark ? Colors.white : Colors.black)
                          : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    child: Text(
                      poi.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                
                // Close button
                Positioned(
                  top: 8,
                  right: 8,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _selectedPoi = null;
                        _isPoiCardExpanded = false;
                      });
                      _renderPOIs();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.clear_thick_circled, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
