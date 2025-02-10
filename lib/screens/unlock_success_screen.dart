import 'package:flutter/material.dart';
import 'qr_scanner_screen.dart';

class UnlockSuccessScreen extends StatelessWidget {
  const UnlockSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 144, 189, 146),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 83, 124, 85),
        automaticallyImplyLeading: false, // Remove default back button
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => const QRScannerScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "🚪 Door Unlocked Successfully!",
              style: TextStyle(fontSize: 24, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              "Select the condition of the bathroom:",
              style: TextStyle(fontSize: 18, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // ⭐ Feedback buttons in the center
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildFeedbackButton(context, "😃 Great"),
                _buildFeedbackButton(context, "🙂 Good"),
                _buildFeedbackButton(context, "😐 Okay"),
                _buildFeedbackButton(context, "😕 Bad"),
                _buildFeedbackButton(context, "🤢 Terrible"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper function for feedback buttons
  Widget _buildFeedbackButton(BuildContext context, String label) {
    return ElevatedButton(
      onPressed: () {
        // TODO: Send feedback to backend
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const QRScannerScreen()),
          (route) => false,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, color: Colors.green),
      ),
    );
  }
}
