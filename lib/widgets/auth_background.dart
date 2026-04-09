import 'package:flutter/material.dart';
import 'dart:math' as math;

class AuthBackground extends StatelessWidget {
  final Widget child;
  final String? title;

  const AuthBackground({super.key, required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF203B68);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Blue Top Section with Topographic Pattern
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.55,
            child: Container(
              color: primaryBlue,
              child: ClipRect(
                child: Stack(
                  children: [
                    // Topographic Pattern
                    CustomPaint(
                      size: Size(size.width, size.height * 0.55),
                      painter: TopoPainter(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    if (title != null)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(30, 60, 30, 0),
                          child: Text(
                            title!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // White Content Section with Wave
          Positioned(
            top: size.height * 0.45,
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomPaint(
              painter: WavePainter(color: Colors.white),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final Color color;
  WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(0, 80); // Start higher
    path.cubicTo(
      size.width * 0.4,
      140, // Deeper dip
      size.width * 0.7,
      -20, // Higher peak
      size.width,
      80, // End higher
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class TopoPainter extends CustomPainter {
  final Color color;
  TopoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(42); // Seed for consistency

    final centerX = size.width * 0.5;
    final centerY = size.height * 0.4;

    // Draw more concentric organic-looking rings with varying opacity and width
    for (int i = 1; i <= 25; i++) {
      final paint = Paint()
        ..color = color.withOpacity(0.04 + rand.nextDouble() * 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5 + rand.nextDouble() * 1.5;

      final radius = i * 25.0;
      final path = Path();

      final pointsCount = 72; // More points for smoother curves
      for (int j = 0; j <= pointsCount; j++) {
        final angle = (j * 360 / pointsCount) * (math.pi / 180.0);

        // Multi-layered noise for more complex organic shapes
        final noise1 = 20 * math.sin(j * 0.3 + i);
        final noise2 = 10 * math.cos(j * 0.8 - i * 0.5);
        final noise3 = 5 * math.sin(j * 1.5 + i * 2);

        final combinedNoise =
            (noise1 + noise2 + noise3) * (0.5 + 0.5 * math.sin(i * 0.2));

        final r = radius + combinedNoise;
        final x = centerX + r * math.cos(angle);
        final y = centerY + r * math.sin(angle) * 0.7; // Elliptical distortion

        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
