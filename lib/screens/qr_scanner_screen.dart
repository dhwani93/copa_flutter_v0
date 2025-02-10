import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'ble_unlock_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool showScanner = false;
  MobileScannerController scannerController = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SmartPotty"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the home screen
          },
        ),
      ),
      body: Center(
        child: showScanner
            ? MobileScanner(
                controller: scannerController,
                onDetect: (barcodeCapture) {
                  final String? code = barcodeCapture.barcodes.first.rawValue;
                  if (code != null) {
                    debugPrint("✅ QR Code Scanned: $code");
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => BLEUnlockScreen(code)),
                    );
                  }
                },
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
