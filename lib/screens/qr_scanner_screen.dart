import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'ble_unlock_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool showScanner = false; // Controls whether to show scanner
  bool isScanning = false; // Prevents multiple scans
  final MobileScannerController scannerController = MobileScannerController();

  void _onQRScanned(BarcodeCapture barcodeCapture) {
    if (isScanning) return; // Prevent multiple detections
    setState(() => isScanning = true);

    final String? code = barcodeCapture.barcodes.first.rawValue;
    if (code != null) {
      debugPrint("✅ QR Code Scanned: $code");
      scannerController.stop(); // ✅ Stop scanning immediately

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BLEUnlockScreen(code)),
      );
    } else {
      debugPrint("❌ No valid QR code detected.");
      setState(() {
        isScanning = false; // Allow scanning again
        showScanner = false; // Return to "Scan QR Code" button
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SmartPotty"),
      ),
      body: Center(
        child: showScanner
            ? MobileScanner(
                controller: scannerController,
                onDetect: _onQRScanned,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Press the button below to scan a QR code.",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showScanner = true;
                        isScanning = false; // Reset scanning state
                      });
                    },
                    child: const Text("Scan QR Code"),
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
