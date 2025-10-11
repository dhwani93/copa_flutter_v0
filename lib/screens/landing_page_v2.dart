import 'dart:ui' as ui;
import 'package:copa_v0/widgets/scan_to_unlock_banner_v2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/color_extensions.dart';
import '../widgets/app_bar_with_nav.dart';
import '../widgets/map_widgets.dart';
import '../theme/app_colors.dart';

/// LandingPageV2
///
/// This file is a copy of `landing_page.dart` intended for iterative
/// changes while preserving the original. Use `LandingPageV2` in
/// your routes or tests to try new UI/behavior without modifying the
/// original `LandingPage`.
class LandingPageV2 extends StatefulWidget {
  const LandingPageV2({super.key});

  @override
  State<LandingPageV2> createState() => _LandingPageV2State();
}

class _LandingPageV2State extends State<LandingPageV2> {
  late GoogleMapController mapController;
  String _selectedLocation = "Main St";

  final Map<String, Map<String, dynamic>> _locationData = {
    "Main St": {
      "position": const LatLng(37.7749, -122.4194),
      "address": "123 Main St, San Francisco, CA",
      "distance": "0.3 mi",
      "status": "vacant",
      "lastCleaned": "12 min ago"
    },
    "Market St": {
      "position": const LatLng(37.7790, -122.4174),
      "address": "456 Market St, San Francisco, CA",
      "distance": "0.7 mi",
      "status": "occupied",
      "lastCleaned": "1 hr ago"
    },
    "Powell St": {
      "position": const LatLng(37.7765, -122.4216),
      "address": "789 Powell St, San Francisco, CA",
      "distance": "1.2 mi",
      "status": "vacant",
      "lastCleaned": "25 min ago"
    },
  };

  final Map<String, BitmapDescriptor?> _markerIcons = {};
  bool _markersLoaded = false;
  Set<Marker> _markers = {};
  Set<Circle> _markerBackgroundCircles = {};
  bool _showLocationCardV2 = false;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
  }

  Future<void> _loadMarkerIcons() async {
    final entries = _locationData.keys.toList();
    final choices = [127, 131, 135, 170, 171, 172, 173, 174, 175];

    for (var i = 0; i < entries.length; i++) {
      final key = entries[i];
      final pngName = 'assets/figma/pins/resized/pin_174_${choices[i % choices.length]}_48w.png';
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
        
        print('✅ Loaded marker $key with size 120x120');
      } catch (e) {
        print('❌ Failed to load marker $key: $e');
      }
    }

    // Build markers once
    final built = <Marker>{};
    _locationData.forEach((key, value) {
      final icon = _markerIcons[key];
      built.add(Marker(
        markerId: MarkerId(key),
        position: value['position'] as LatLng,
        icon: icon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        anchor: const Offset(0.5, 1.0),
        zIndex: 1,
        onTap: () {
          print('🎯 Marker tapped: $key');
          _onMarkerTapped(key);
        },
      ));
    });

    if (!mounted) return;
    setState(() {
      _markers = built;
      _markersLoaded = true;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // Use light map style for V2
    rootBundle.loadString('assets/map_style_light.json').then((style) {
      // ignore: deprecated_member_use
      mapController.setMapStyle(style);
    });
  }

  void _onMarkerTapped(String key) {
    print('🎯 Processing marker tap for: $key');
    
    // Add blue circle around selected marker
    final selectedCircle = Circle(
      circleId: const CircleId('selected_marker_indicator'),
      center: _locationData[key]!['position'] as LatLng,
      radius: 40,
      fillColor: const Color(0x4442A5F5),
      strokeColor: const Color(0xFF42A5F5),
      strokeWidth: 3,
      zIndex: 0,
      consumeTapEvents: false,
    );
    
    setState(() {
      _selectedLocation = key;
      _showLocationCardV2 = true;
      _markerBackgroundCircles = {selectedCircle};
    });
    
    mapController.animateCamera(
      CameraUpdate.newLatLng(_locationData[key]!['position'] as LatLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _locationData[_selectedLocation]!;

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
            },
            initialCameraPosition: CameraPosition(
              target: selected["position"],
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
          if (!_markersLoaded)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
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
                  mapController.animateCamera(CameraUpdate.zoomIn());
                }),
                const SizedBox(height: 8),
                buildMapControlButton(Icons.remove, () {
                  mapController.animateCamera(CameraUpdate.zoomOut());
                }),
              ],
            ),
          ),
          const ScanToUnlockBannerV2(),
          if (_showLocationCardV2)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildLocationCardV2(selected),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationCardV2(Map<String, dynamic> location) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.2,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withOpacitySafe(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacitySafe(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COPA $_selectedLocation',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location["address"],
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () {
                        setState(() {
                          _showLocationCardV2 = false;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.circle,
                        size: 10,
                        color: location["status"] == "occupied"
                            ? AppColors.errorRed
                            : AppColors.successGreen),
                    const SizedBox(width: 6),
                    Text(
                      location["status"] == "occupied" ? "Occupied" : "Vacant",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      'Last cleaned: ${location["lastCleaned"]}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.navigation, size: 16),
                  label: const Text('Get Directions'),
                  onPressed: () async {
                    final lat = location["position"].latitude;
                    final lng = location["position"].longitude;
                    final url = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking');

                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Could not launch Google Maps")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
