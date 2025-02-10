import 'package:flutter/material.dart';
import 'screens/qr_scanner_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const QRScannerScreen(),
      theme: ThemeData(primarySwatch: Colors.lightBlue),
    );
  }
}
