import 'package:flutter/material.dart';
import 'qr_scanner_screen.dart';

class UnlockSuccessScreen extends StatelessWidget {
  const UnlockSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 134, 168, 135),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 228, 234, 228),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "🚪 Door Unlocked Successfully!",
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              const Text(
                "🧼 How is the bathroom condition?",
                style: TextStyle(fontSize: 20, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // ⭐ User Feedback Options
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _feedbackButton(context, "😃 Great", Colors.blue),
                  _feedbackButton(context, "🙂 Good", Colors.green),
                  _feedbackButton(context, "😐 Okay", Colors.amber),
                  _feedbackButton(context, "🙁 Bad", Colors.orange),
                  _feedbackButton(context, "🤢 Worst", Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🛠️ Helper Function for Feedback Buttons
  Widget _feedbackButton(BuildContext context, String text, Color color) {
    return ElevatedButton(
      onPressed: () {
        // TODO: Send feedback to the backend here
        debugPrint("User selected feedback: $text"); // Log feedback for now

        // Navigate back to the QR Scanner screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const QRScannerScreen()),
          (route) => false,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      ),
      child: Text(
        text,
        style:
            TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
