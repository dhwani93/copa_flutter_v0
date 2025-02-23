import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // QR Scanner View
          Center(
            child: RepaintBoundary(
              key: _qrKey,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: scannedCode != null
                          ? const Color.fromARGB(255, 234, 238, 234)
                              .withOpacity(0.2)
                          : const Color.fromARGB(255, 195, 205, 222)
                              .withOpacity(0.1),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                  border: Border.all(
                      color: const Color.fromARGB(255, 99, 163, 193), width: 4),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: scannedCode != null
                    ? QrImageView(
                        data: scannedCode!,
                        version: QrVersions.auto,
                        size: 250.0,
                      )
                    : MobileScanner(
                        controller: scannerController,
                        onDetect: _onQRScanned,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Unlock Button
          ElevatedButton(
            onPressed: scannedCode != null
                ? () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => BLEUnlockScreen(scannedCode!)),
                    );
                  }
                : null, // Disabled if QR not scanned
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  scannedCode != null ? Colors.lightBlue : Colors.grey,
              elevation: scannedCode != null ? 8 : 2,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Unlock Now',
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }
}
