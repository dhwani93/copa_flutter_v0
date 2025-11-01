import 'package:flutter/material.dart';
import '../utils/color_extensions.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'ble_unlock_screen.dart';
import '/widgets/app_bar_with_nav.dart';
import '/widgets/copa_fact_banner.dart';

/// QRScannerScreen
/// Modern QR scanner screen using teal color scheme
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  bool isScanning = false;
  String? scannedCode;
  final MobileScannerController scannerController = MobileScannerController();

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.linear),
    );
    _scanLineController.repeat(reverse: true);
  }

  void _onQRScanned(BarcodeCapture barcodeCapture) async {
    if (isScanning) return;
    setState(() => isScanning = true);

    final String? code = barcodeCapture.barcodes.first.rawValue;
    if (code != null) {
      HapticFeedback.mediumImpact();
      debugPrint("✅ QR Code Scanned: $code");
      await scannerController.stop();
      _scanLineController.stop();
      setState(() {
        scannedCode = code;
      });
    } else {
      setState(() => isScanning = false);
    }
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      backgroundColor: const Color(0xFF101014),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFF101014),
                  Color(0xFF0C0C0F),
                ],
              ),
            ),
          ),

          // Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              
              // Price badge at top
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '₹10',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              
              const SizedBox(height: 30),

              // Scanner box with camera or QR code
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.withOpacitySafe(0.3),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: scannedCode == null
                          ? MobileScanner(
                              controller: scannerController,
                              onDetect: _onQRScanned,
                            )
                          : QrImageView(
                              data: scannedCode!,
                              version: QrVersions.auto,
                              size: 260,
                              backgroundColor: Colors.white,
                            ),
                    ),
                  ),

                  // Animated scanning line
                  if (scannedCode == null)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _scanLineAnimation,
                        builder: (context, child) {
                          return Align(
                            alignment: Alignment(
                                0, (_scanLineAnimation.value * 2) - 1),
                            child: Container(
                              height: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacitySafe(0.2),
                                    Colors.white.withOpacitySafe(0.8),
                                    Colors.white.withOpacitySafe(0.2),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Scan to unlock button just under camera
              ElevatedButton.icon(
                icon: const Icon(Icons.lock_open, color: Colors.white),
                label: const Text('Unlock Now'),
                onPressed: scannedCode != null
                    ? () {
                        HapticFeedback.mediumImpact();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BLEUnlockScreen(scannedCode!),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: scannedCode != null
                      ? const Color(0xFF0FB498)
                      : Colors.grey[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 40,
                  ),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              if (scannedCode != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      scannedCode = null;
                      isScanning = false;
                      scannerController.start();
                      _scanLineController.repeat(reverse: true);
                    });
                  },
                  child: const Text(
                    'Scan Again',
                    style: TextStyle(
                      color: Colors.white70,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              
              const Spacer(flex: 2),
            ],
          ),

          // Copa fact banner at bottom with ghostie smiley
          const Positioned(
            bottom: 60, // Higher from the bottom
            left: 0,
            right: 0,
            child: CopaFactBanner(),
          ),
        ],
      ),
    );
  }
}
