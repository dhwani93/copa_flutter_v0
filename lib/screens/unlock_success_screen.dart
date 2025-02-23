import 'package:copa_v0/main.dart';
import 'package:flutter/material.dart';
import '/widgets/app_bar_with_nav.dart';

class UnlockSuccessScreen extends StatelessWidget {
  const UnlockSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Door Unlocked!",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              "How is the restroom?",
              style: TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFeedbackButton(context, "😃 Clean",
                    const Color.fromARGB(255, 87, 166, 90)),
                const SizedBox(height: 10),
                _buildFeedbackButton(context, "🙂 Okay",
                    const Color.fromARGB(255, 164, 131, 80)),
                const SizedBox(height: 10),
                _buildFeedbackButton(context, "😕 Needs Cleaning",
                    const Color.fromARGB(255, 190, 103, 97)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackButton(BuildContext context, String label, Color color) {
    return ElevatedButton(
      onPressed: () {
        // TODO: Send feedback to backend
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LandingPage()),
          (route) => false,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 18, color: color),
      ),
    );
  }
}
