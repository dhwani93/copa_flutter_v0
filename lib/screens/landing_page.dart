import 'dart:ui';
import 'package:copa_v0/widgets/scan_to_unlock_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/app_bar_with_nav.dart';
import '../widgets/map_widgets.dart';
import 'qr_scanner_screen.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late GoogleMapController mapController;
  String _selectedLocation = "Main St";

  final Map<String, Map<String, dynamic>> _locationData = {
    "Main St": {
      "position": const LatLng(37.7749, -122.4194),
      "address": "123 Main St, San Francisco, CA",
      "distance": "0.3 mi",
    },
    "Market St": {
      "position": const LatLng(37.7790, -122.4174),
      "address": "456 Market St, San Francisco, CA",
      "distance": "0.7 mi",
    },
    "Powell St": {
      "position": const LatLng(37.7765, -122.4216),
      "address": "789 Powell St, San Francisco, CA",
      "distance": "1.2 mi",
    },
  };

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    rootBundle.loadString('assets/map_style_dark.json').then((style) {
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
              return Marker(
                markerId: MarkerId(entry.key),
                position: entry.value["position"],
                infoWindow: InfoWindow(title: "Copa - ${entry.key}"),
                onTap: () => _selectLocation(entry.key),
              );
            }).toSet(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            padding: const EdgeInsets.only(bottom: 120),
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.0, 0.2, 0.7, 1.0],
              ),
            ),
          ),

          // Zoom controls
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

          // Search Bar
          Positioned(
            bottom: 230,
            left: 16,
            right: 16,
            child: buildSearchBar(),
          ),

          // Location Card
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: _buildLocationCard(selected),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Nearest Location',
                        style: TextStyle(
                          color: Colors.blue.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      location["distance"],
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'COPA ${_selectedLocation}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location["address"],
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.navigation,
                            size: 16, color: Colors.white),
                        label: const Text('Directions'),
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
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
                        icon: const Icon(Icons.info_outline,
                            size: 16, color: Colors.white70),
                        label: const Text('Details'),
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.grey[700]!),
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
