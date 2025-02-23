import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'screens/qr_scanner_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        scaffoldBackgroundColor:
            Color.fromARGB(255, 203, 213, 212), // Super light grey background
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Poppins'),
      ),
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('assets/profile-placeholder.png'),
            ),
          ),
          SizedBox(height: 20),
          // Rectangular Google Maps Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(37.7749, -122.4194), // San Francisco Example
                    zoom: 14,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId('copa_1'),
                      position: LatLng(37.7749, -122.4194),
                      infoWindow: InfoWindow(title: 'Copa - 123 Main St'),
                    ),
                    Marker(
                      markerId: MarkerId('copa_2'),
                      position: LatLng(37.7790, -122.4194),
                      infoWindow: InfoWindow(title: 'Copa - 456 Elm St'),
                    ),
                    Marker(
                      markerId: MarkerId('copa_3'),
                      position: LatLng(37.7800, -122.4200),
                      infoWindow: InfoWindow(title: 'Copa - 789 Oak St'),
                    ),
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          // Show only the nearest Copa location
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Nearest Location: Copa',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '123 Main St, San Francisco, CA',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const QRScannerScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Scan QR Code',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
