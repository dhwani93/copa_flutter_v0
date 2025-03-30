import 'dart:async';
import 'dart:ui';
import 'package:copa_v0/widgets/copa_fact_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'ble_unlock_screen.dart';
import '/widgets/app_bar_with_nav.dart';

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
      debugPrint("✅ QR Code Scanned: \$code");
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

          const CopaFactBanner(),

          // Scanner box with camera or QR code
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blueAccent.withOpacity(0.4),
                          width: 3,
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
                              size: 220,
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
                                    Colors.blueAccent.withOpacity(0.2),
                                    Colors.blueAccent.withOpacity(0.6),
                                    Colors.blueAccent.withOpacity(0.2),
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
            ],
          ),

          // Unlock button and rescan
          Positioned(
            bottom: 60,
            child: Column(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.lock_open, color: Colors.white),
                  label: const Text('Unlock Now'),
                  onPressed: scannedCode != null
                      ? () {
                          HapticFeedback.mediumImpact(); // Haptic on unlock
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BLEUnlockScreen(scannedCode!),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scannedCode != null
                        ? Colors.blue[600]
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
