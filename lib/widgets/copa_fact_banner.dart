
import 'dart:async';
import 'package:flutter/material.dart';

class CopaFactBanner extends StatefulWidget {
  const CopaFactBanner({super.key});

  @override
  State<CopaFactBanner> createState() => _CopaFactBannerState();
}

class _CopaFactBannerState extends State<CopaFactBanner> {
  final List<String> _copaFacts = [
    "🚽 Most used today: Main Street Pod #4",
    "🧼 Cleaned every 1.8 hours on average",
    "🌱 Water saved this week: 14,000L",
    "💨 Fastest unlock today: 1.4 sec",
    "📈 98.7% of users say it's smell-free",
  ];

  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _copaFacts.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: kToolbarHeight + 20,
      left: 24,
      right: 24,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: Text(
          _copaFacts[_currentIndex],
          key: ValueKey(_copaFacts[_currentIndex]),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
