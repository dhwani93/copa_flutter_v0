import 'package:flutter/material.dart';
import '../screens/qr_scanner_screen.dart';

class OccupancyErrorDialog extends StatelessWidget {
  const OccupancyErrorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.66,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning,
                color: Color.fromARGB(255, 214, 186, 61), size: 25),
            const SizedBox(height: 20),
            const Text("Attention",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            Text("Someone is inside, please try in sometime.",
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Text("There is another COPA 3 minutes from here.",
                textAlign: TextAlign.center),
            const SizedBox(height: 100),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const QRScannerScreen()),
                );
              },
              child: const Text("OK",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
