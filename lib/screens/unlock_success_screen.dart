import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/widgets/app_bar_with_nav.dart';
import '../theme/app_colors.dart';
import 'landing_page.dart';

class UnlockSuccessScreen extends StatelessWidget {
  const UnlockSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      backgroundColor: const Color(0xFF101014),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_open,
                color: AppColors.successGreen, size: 60),
            const SizedBox(height: 20),
            Text(
              "Door Unlocked!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              "How is the restroom?",
              style: TextStyle(
                  fontSize: 16,
                  color:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Column(
              children: [
                FeedbackButton(
                    label: "Clean", emoji: "😃", color: AppColors.successGreen),
                SizedBox(height: 12),
                FeedbackButton(
                    label: "Okay",
                    emoji: "🙂",
                    color: Theme.of(context).colorScheme.secondary),
                SizedBox(height: 12),
                FeedbackButton(
                    label: "Needs Cleaning",
                    emoji: "😕",
                    color: AppColors.errorRed),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FeedbackButton extends StatefulWidget {
  final String label;
  final String emoji;
  final Color color;

  const FeedbackButton({
    required this.label,
    required this.emoji,
    required this.color,
    super.key,
  });

  @override
  State<FeedbackButton> createState() => _FeedbackButtonState();
}

class _FeedbackButtonState extends State<FeedbackButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTap() {
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Thanks for your feedback!"),
        duration: const Duration(milliseconds: 1200),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LandingPage()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _scale = 1.05);
        Future.delayed(const Duration(milliseconds: 100), () {
          setState(() => _scale = 1.0);
          _onTap();
        });
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 220,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(40),
            border:
                Border.all(color: widget.color.withOpacity(0.6), width: 1.2),
          ),
          child: Column(
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 16,
                  color: widget.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
