import 'dart:ui' as ui;
import 'package:copa_v0/widgets/scan_to_unlock_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/color_extensions.dart';
import '../widgets/app_bar_with_nav.dart';
import '../widgets/map_widgets.dart';

/// LandingPage
///
/// Main landing page with map functionality and modern V2 design.
/// This replaces the original landing page with improved UI and better performance.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  GoogleMapController? mapController;

  final Map<String, Map<String, dynamic>> _locationData = {
    "Main St": {
      "position": const LatLng(37.7749, -122.4194),
      "address": "123 Main St, San Francisco, CA",
      "distance": "0.3 mi",
      "type": "women", // women or unisex
      "status": "vacant", // vacant, occupied, or disabled
      "lastCleaned": "12 min ago"
    },
    "Market St": {
      "position": const LatLng(37.7790, -122.4174),
      "address": "456 Market St, San Francisco, CA",
      "distance": "0.7 mi",
      "type": "women",
      "status": "occupied",
      "lastCleaned": "1 hr ago"
    },
    "Powell St": {
      "position": const LatLng(37.7765, -122.4216),
      "address": "789 Powell St, San Francisco, CA",
      "distance": "1.2 mi",
      "type": "unisex",
      "status": "vacant",
      "lastCleaned": "25 min ago"
    },
    "Mission St": {
      "position": const LatLng(37.7730, -122.4190),
      "address": "321 Mission St, San Francisco, CA",
      "distance": "0.5 mi",
      "type": "women",
      "status": "disabled",
      "lastCleaned": "3 hr ago"
    },
    "Geary St": {
      "position": const LatLng(37.7808, -122.4205),
      "address": "555 Geary St, San Francisco, CA",
      "distance": "0.8 mi",
      "type": "unisex",
      "status": "occupied",
      "lastCleaned": "45 min ago"
    },
  };

  final Map<String, BitmapDescriptor?> _markerIcons = {};
  Set<Marker> _markers = {};
  Set<Circle> _markerBackgroundCircles = {};
  bool _showLocationCardV2 = false;
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
  }

  // Helper function to get marker color based on type and status
  // 174_127: women occupied (red)
  // 174_131: women vacant (teal)
  // 174_135: women disabled (grey)
  // 174_170: unisex vacant (teal)
  // 174_171: unisex occupied (red)
  // 174_172: unisex disabled (grey)
  int _getMarkerPinNumber(String type, String status) {
    if (type == "women") {
      if (status == "occupied") {
        return 127; // Women occupied (red)
      } else if (status == "disabled") {
        return 135; // Women disabled (grey)
      } else { // vacant
        return 131; // Women vacant (teal)
      }
    } else { // unisex
      if (status == "occupied") {
        return 171; // Unisex occupied (red)
      } else if (status == "disabled") {
        return 172; // Unisex disabled (grey)
      } else { // vacant
        return 170; // Unisex vacant (teal, two people icon)
      }
    }
  }

  // Helper function to get status badge color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'vacant':
        return const Color(0xFF0FB498); // Teal
      case 'occupied':
        return Colors.red;
      case 'disabled':
        return Colors.grey;
      default:
        return const Color(0xFF0FB498);
    }
  }  Future<void> _loadMarkerIcons() async {
    // Load markers progressively - add each one as it's ready
    for (var entry in _locationData.entries) {
      final key = entry.key;
      final type = entry.value['type'] as String;
      final status = entry.value['status'] as String;
      final pinNumber = _getMarkerPinNumber(type, status);
      
      final pngName = 'assets/figma/pins/resized/pin_174_${pinNumber}_48w.png';
      try {
        // Load PNG and scale it up to 120px for better visibility
        final data = await rootBundle.load(pngName);
        final bytes = data.buffer.asUint8List();
        
        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: 120,
          targetHeight: 120,
        );
        final frame = await codec.getNextFrame();
        final scaledImage = frame.image;
        
        final byteData = await scaledImage.toByteData(format: ui.ImageByteFormat.png);
        final scaledBytes = byteData!.buffer.asUint8List();
        
        final descriptor = BitmapDescriptor.fromBytes(scaledBytes);
        
        if (!mounted) return;
        _markerIcons[key] = descriptor;
        
        // Add marker immediately as it's ready
        _addMarkerToMap(key, entry.value, descriptor);
        
        print('✅ Loaded marker $key ($type-$status) with pin $pinNumber at size 120x120');
      } catch (e) {
        print('❌ Failed to load marker $key: $e');
      }
    }
  }

  void _addMarkerToMap(String key, Map<String, dynamic> value, BitmapDescriptor icon) {
    final marker = Marker(
      markerId: MarkerId(key),
      position: value['position'] as LatLng,
      icon: icon,
      anchor: const Offset(0.5, 1.0),
      zIndex: 1,
      onTap: () {
        print('🎯 Marker tapped: $key');
        _onMarkerTapped(key);
      },
    );

    if (!mounted) return;
    setState(() {
      _markers.add(marker);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // Use light map style for V2
    rootBundle.loadString('assets/map_style_light.json').then((style) {
      // ignore: deprecated_member_use
      mapController?.setMapStyle(style);
    });
  }

  void _onMarkerTapped(String key) {
    print('🎯 Processing marker tap for: $key');
    
    setState(() {
      _selectedLocation = key;
      _showLocationCardV2 = true;
    });
    
    // Rebuild circles - add blue border circle for selected marker
    final circles = <Circle>{};
    _locationData.forEach((locKey, value) {
      if (locKey == key) {
        // Add blue border circle for selected marker
        circles.add(Circle(
          circleId: CircleId('${locKey}_border'),
          center: value['position'] as LatLng,
          radius: 25, // Slightly larger than marker for border effect
          strokeColor: Colors.blue,
          strokeWidth: 3,
          fillColor: Colors.transparent,
          zIndex: 2,
        ));
      }
    });
    
    setState(() {
      _markerBackgroundCircles = circles;
    });
    
    mapController?.animateCamera(
      CameraUpdate.newLatLng(_locationData[key]!['position'] as LatLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: buildAppBar(context),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            onTap: (LatLng position) {
              print('🗺️ Map tapped at: ${position.latitude}, ${position.longitude}');
              // Close location card when tapping anywhere on the map
              if (_showLocationCardV2) {
                setState(() {
                  _showLocationCardV2 = false;
                  _selectedLocation = null;
                  _markerBackgroundCircles = {};
                });
              }
            },
            initialCameraPosition: CameraPosition(
              target: _locationData["Main St"]!["position"] as LatLng,
              zoom: 14.0,
            ),
            markers: _markers,
            circles: _markerBackgroundCircles,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            padding: const EdgeInsets.only(bottom: 120),
          ),
          // Gradient overlay - must ignore touches so map is interactive!
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.surface.withOpacitySafe(0.5),
                    Colors.transparent,
                    Colors.transparent,
                    Theme.of(context).colorScheme.surface.withOpacitySafe(0.7),
                  ],
                  stops: const [0.0, 0.2, 0.7, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            right: 16,
            child: Column(
              children: [
                buildMapControlButton(Icons.add, () {
                  mapController?.animateCamera(CameraUpdate.zoomIn());
                }),
                const SizedBox(height: 8),
                buildMapControlButton(Icons.remove, () {
                  mapController?.animateCamera(CameraUpdate.zoomOut());
                }),
              ],
            ),
          ),
          const ScanToUnlockBanner(),
          if (_showLocationCardV2 && _selectedLocation != null)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.45, // Position in middle area of screen
              left: 16,
              right: 16,
              child: _buildLocationCardV2(_selectedLocation!),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationCardV2(String locationKey) {
    final location = _locationData[locationKey];
    if (location == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left side - Location details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    locationKey,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location['address'] as String? ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      // Type badge (Women/Unisex)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0FB498).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (location['type'] as String) == 'women' 
                                ? Icons.woman 
                                : Icons.people,
                              size: 14,
                              color: const Color(0xFF0FB498),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ((location['type'] as String?) ?? 'women').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0FB498),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(location['status'] as String? ?? 'vacant').withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (location['status'] as String? ?? 'vacant').toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(location['status'] as String? ?? 'vacant'),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location['lastCleaned'] as String? ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right side - Directions button
            GestureDetector(
              onTap: () async {
                print('📍 Opening directions to: $locationKey');
                final lat = (location['position'] as LatLng).latitude;
                final lng = (location['position'] as LatLng).longitude;
                final url = Uri.parse(
                    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
