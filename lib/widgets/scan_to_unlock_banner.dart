import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/qr_scanner_screen.dart';

class ScanToUnlockBanner extends StatelessWidget {
  const ScanToUnlockBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: kToolbarHeight + 80,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const QRScannerScreen(),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.8),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.qr_code_scanner, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Scan to Unlock',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
