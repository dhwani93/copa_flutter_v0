import 'package:flutter/material.dart';
import 'qr_scanner_screen.dart';

class UnlockSuccessScreen extends StatelessWidget {
  const UnlockSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "🚪 Door Unlocked Successfully!",
              style: TextStyle(fontSize: 24, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const QRScannerScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              child: const Text(
                "OK",
                style: TextStyle(fontSize: 18, color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
