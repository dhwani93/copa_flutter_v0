import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'ble_unlock_screen.dart';
import '/widgets/app_bar_with_nav.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool isScanning = false; // Prevents multiple scans
  String? scannedCode; // Stores the scanned QR code
  final GlobalKey _qrKey = GlobalKey();
  final MobileScannerController scannerController = MobileScannerController();

  void _onQRScanned(BarcodeCapture barcodeCapture) {
    if (isScanning) return; // Prevent multiple detections
    setState(() => isScanning = true);

    final String? code = barcodeCapture.barcodes.first.rawValue;
    if (code != null) {
      debugPrint("✅ QR Code Scanned: $code");
      scannerController.stop(); // ✅ Stop scanning immediately
      setState(() {
        scannedCode = code;
      });
    } else {
      debugPrint("❌ No valid QR code detected.");
      setState(() => isScanning = false); // Allow scanning again
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR Scanner View inside a Column to prevent button pushing down
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: scannedCode != null
                        ? Colors.green.withOpacity(0.2)
                        : Colors.blueAccent.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
                border: Border.all(color: Colors.lightBlue, width: 4),
                borderRadius: BorderRadius.circular(25),
              ),
              child: MobileScanner(
                controller: scannerController,
                onDetect: _onQRScanned,
              ),
            ),
            const SizedBox(height: 20), // Add space between scanner and button
            // Unlock Button
            ElevatedButton(
              onPressed: scannedCode != null
                  ? () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                BLEUnlockScreen(scannedCode!)),
                      );
                    }
                  : null, // Disabled if QR not scanned
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    scannedCode != null ? Colors.lightBlue : Colors.grey,
                elevation: scannedCode != null ? 8 : 2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Unlock Now',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }
}
