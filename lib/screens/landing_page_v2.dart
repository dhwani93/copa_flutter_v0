import 'dart:ui';
import 'package:copa_v0/widgets/scan_to_unlock_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/color_extensions.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // Overlay state for the Figma landing frame
  bool _showFigmaOverlay = false;
  Offset _overlayOffset = Offset.zero;
  final Map<String, BitmapDescriptor?> _markerIcons = {};

  @override
  void initState() {
    super.initState();
    // pre-load PNG pin assets (copied earlier into assets/figma/pins/png)
    _loadMarkerIcons();
  }

  Future<void> _loadMarkerIcons() async {
    final entries = _locationData.keys.toList();
    final choices = [127, 131, 135, 170, 171, 172, 173, 174, 175];
    for (var i = 0; i < entries.length; i++) {
      final key = entries[i];
      // prefer the resized 48px variants we generated
  final pngName = 'assets/figma/pins/resized/pin_174_${choices[i % choices.length]}_32w.png';
      try {
        final descriptor = await BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(size: Size(48, 48)), pngName);
        if (!mounted) return;
        setState(() {
          _markerIcons[key] = descriptor;
        });
      } catch (e) {
        // ignore and keep null to use default marker
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    rootBundle.loadString('assets/map_style_dark.json').then((style) {
      // setMapStyle is deprecated; the current plugin suggests using
      // the GoogleMap.style API. Keep the runtime behavior the same and
      // silence the deprecation lint until a larger migration is done.
      // ignore: deprecated_member_use
      mapController.setMapStyle(style);
    });
  }

  void _selectLocation(String location) {
    setState(() {
      _selectedLocation = location;
    });

    mapController.animateCamera(
      CameraUpdate.newLatLng(_locationData[location]!["position"]),
    );
  }

  Future<void> _onMarkerTapped(String key) async {
    // compute screen coordinate for the tapped marker
    final pos = _locationData[key]!['position'] as LatLng;
    try {
      final screenCoord = await mapController.getScreenCoordinate(pos);
      // GoogleMapController.getScreenCoordinate returns ScreenCoordinate
      // with x/y in device pixels. Convert to logical pixels for layout.
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final dx = screenCoord.x / devicePixelRatio;
      final dy = screenCoord.y / devicePixelRatio;

      setState(() {
        _showFigmaOverlay = true;
        _overlayOffset = Offset(dx, dy);
        _selectedLocation = key;
      });
    } catch (e) {
      // Fallback: just center overlay on screen
      setState(() {
        _showFigmaOverlay = true;
        _overlayOffset = Offset(MediaQuery.of(context).size.width / 2,
            MediaQuery.of(context).size.height / 2);
        _selectedLocation = key;
      });
    }
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
            initialCameraPosition: CameraPosition(
              target: selected["position"],
              zoom: 14.0,
            ),
            markers: _locationData.entries.map((entry) {
              final icon = _markerIcons[entry.key] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
              return Marker(
                markerId: MarkerId(entry.key),
                position: entry.value["position"],
                icon: icon,
                anchor: Offset(0.5, 1.0), // centers it at the bottom of glow
                onTap: () => _onMarkerTapped(entry.key),
              );
            }).toSet(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            padding: const EdgeInsets.only(bottom: 120),
          ),
          Container(
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
          const ScanToUnlockBanner(),
          Positioned(
            bottom: 270, // moved search bar slightly up
            left: 16,
            right: 16,
            child: buildSearchBar(),
          ),
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: _buildLocationCard(selected),
          ),
          // Figma landing overlay anchored to tapped marker
          if (_showFigmaOverlay)
            Positioned(
              left: _overlayOffset.dx - 196, // center by half svg width (393/2)
              top: _overlayOffset.dy - 852, // position it above the marker
              width: 393,
              height: 852,
              child: IgnorePointer(
                ignoring: false,
                child: SvgPicture.asset(
                  'assets/figma/landing_frame_174_176.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location) {
    return Container(
      decoration: BoxDecoration(
  color: const Color(0xFF121212).withOpacitySafe(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.surface.withOpacitySafe(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacitySafe(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Nearest Location',
                        style: TextStyle(
                          color: Colors.blue.withOpacitySafe(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      location["distance"],
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'COPA $_selectedLocation',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location["address"],
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
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
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      'Last cleaned: ${location["lastCleaned"]}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.navigation,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimary),
                        label: const Text('Directions'),
                        onPressed: () async {
                          final lat = location["position"].latitude;
                          final lng = location["position"].longitude;
                          final url = Uri.parse(
                              'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking');

                          // Capture messenger and mounted state before async gaps
                          final messenger = ScaffoldMessenger.of(context);
                          messenger.showSnackBar(const SnackBar(
                              content: Text(
                                  'Opening directions in Google Maps...')));

                          await Future.delayed(const Duration(milliseconds: 500));
                          if (!mounted) return;

                          if (await canLaunchUrl(url)) {
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          } else {
                            messenger.showSnackBar(const SnackBar(
                                content:
                                    Text("Could not launch Google Maps")));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.info_outline,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withOpacitySafe(0.7)),
                        label: const Text('Details'),
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withOpacitySafe(0.7),
                          side: BorderSide(color: AppColors.divider),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
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
    );
  }
}
