import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../widgets/app_bar_with_nav.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/landing_page.dart';

class UnlockErrorScreen extends StatelessWidget {
  final String errorMessage;

  const UnlockErrorScreen({
    super.key,
    this.errorMessage = 'Unable to connect to the lock',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top warning banner with softer design
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.shade50,
                    Colors.amber.shade100.withOpacity(0.5),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Colors.amber,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Connection Issue',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Lottie animation with modern circular background
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.red.shade50,
                            Colors.red.shade100.withOpacity(0.3),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.15),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Lottie.asset(
                          'assets/animations/ble_error.json',
                          width: 160,
                          height: 160,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Title with better typography
                    const Text(
                      'Connection Failed',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    
                    // Error message with better styling
                    /**Text(
                      errorMessage,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),**/
                    
                    // Helpful tips in a subtle card
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                color: const Color(0xFF0FB498),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Quick Tips',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildTip('Make sure you\'re close to the door'),
                          const SizedBox(height: 8),
                          _buildTip('Check if Bluetooth is enabled'),
                          const SizedBox(height: 8),
                          _buildTip('Try scanning the QR code again'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Primary action button with modern styling
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QRScannerScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 24),
                        label: const Text(
                          'Try Again',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0FB498),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          shadowColor: const Color(0xFF0FB498).withOpacity(0.3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    
                    // Secondary button with modern outline style
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LandingPage(),
                            ),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.map_outlined, size: 22),
                        label: const Text(
                          'Back to Map',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0FB498),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          side: BorderSide(
                            color: const Color(0xFF0FB498).withOpacity(0.5),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFF0FB498),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
