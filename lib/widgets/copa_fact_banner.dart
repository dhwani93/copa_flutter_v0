import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

/// CopaFactBannerV2
/// 
/// V2 version that rotates through different Copa facts
/// Features ghostie smiley mascot with thinking cloud and animated fact changes
class CopaFactBanner extends StatefulWidget {
  const CopaFactBanner({super.key});

  @override
  State<CopaFactBanner> createState() => _CopaFactBannerState();
}

class _CopaFactBannerState extends State<CopaFactBanner> {
  int _currentFactIndex = 0;
  Timer? _factTimer;

  // List of Copa facts to rotate through
  final List<String> _facts = [
    "Did you know that the average person spends about 2 years of their life in the bathroom?",
    "The first modern public toilet was opened in London in 1851.",
    "Japanese toilets are famous for their high-tech features like heated seats and bidets.",
    "The average person uses the toilet 6-8 times per day.",
    "Ancient Romans had public latrines that could accommodate up to 20 people at once!",
    "World Toilet Day is celebrated on November 19th every year.",
    "The flush toilet was invented by Sir John Harington in 1596 for Queen Elizabeth I.",
    "In space, astronauts use special toilets that work with air suction instead of water!",
    "The largest public restroom in the world is in Chongqing, China with over 1,000 stalls.",
    "Thomas Crapper popularized the flush toilet, but he didn't actually invent it!",
    "The word 'loo' for toilet may come from the French 'gardez l'eau' meaning 'watch out for the water!'",
    "In South Korea, there's a toilet-themed park called Mr. Toilet House dedicated to bathroom innovation.",
  ];

  @override
  void initState() {
    super.initState();
    // Start timer to rotate facts every 8 seconds
    _factTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      setState(() {
        _currentFactIndex = (_currentFactIndex + 1) % _facts.length;
      });
    });
  }

  @override
  void dispose() {
    _factTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 100, // Fixed height to prevent jumping
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end, // Align to bottom
          children: [
            // Ghostie smiley mascot
            SvgPicture.asset(
              'assets/figma/ghostie_smiley_wavy.svg',
              width: 80,
              height: 80,
            ),
            const SizedBox(width: 12),
            // Thinking cloud with facts
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: CustomPaint(
                  key: ValueKey<int>(_currentFactIndex),
                  painter: ThinkingCloudPainter(),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 80, // Minimum height to match ghostie
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        _facts[_currentFactIndex],
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF333333),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for thinking cloud shape
class ThinkingCloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final path = Path();
    
    // Main cloud shape
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );
    
    path.addRRect(rect);
    
    // Draw shadow
    canvas.drawPath(path, shadowPaint);
    
    // Draw cloud
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
