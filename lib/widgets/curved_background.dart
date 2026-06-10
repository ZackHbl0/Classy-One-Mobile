import 'package:flutter/material.dart';

class CurvedBackground extends StatelessWidget {
  final Widget child;
  final String title;

  const CurvedBackground({super.key, required this.child, required this.title});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF203B68);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Blue Top Section
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45,
            child: Container(
              color: primaryBlue,
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Header Logo
                    Image.asset(
                      'assets/images/Classy_One.png',
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.school,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // White Curved Section
          Positioned(
            top: size.height * 0.35,
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomPaint(
              painter: CurvePainter(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Colors.white;
    paint.style = PaintingStyle.fill;

    var path = Path();

    // Start slightly lower on the left
    path.moveTo(0, 60);

    // Create a smooth wave curve
    path.cubicTo(size.width * 0.35, 60, size.width * 0.5, 0, size.width, 0);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
