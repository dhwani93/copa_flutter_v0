import 'package:flutter/material.dart';
import 'qr_scanner_screen.dart'; // Ensure this points to your main QR scanner screen

class UnlockErrorScreen extends StatelessWidget {
  final String errorMessage;

  const UnlockErrorScreen(this.errorMessage, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade700,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              Text(
                errorMessage,
                style: const TextStyle(fontSize: 22, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const QRScannerScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text(
                  "Back to Home",
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
