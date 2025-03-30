import 'package:flutter/material.dart';
import '../screens/qr_scanner_screen.dart';
import 'glass_modal.dart';

class OccupancyErrorDialog {
  static void show(BuildContext context) {
    GlassModal.show(
      context: context,
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.amber,
      title: 'Restroom Occupied',
      message:
          'Someone is currently inside.\nPlease try again in a few minutes.\n\nThere is another COPA just 3 minutes away.',
      buttonText: 'Okay',
      onButtonTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const QRScannerScreen()),
        );
      },
    );
  }
}
