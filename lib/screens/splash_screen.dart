import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// Splash Screen élégant avec thème vert ClassyOne (Redesign Image 2)
/// S'affiche pendant 3 secondes au démarrage de l'application
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Configuration des animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    // Démarrer l'animation
    _animationController.forward();

    // Naviguer après 3 secondes
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Attendre 3 secondes
    await Future.delayed(const Duration(seconds: 3));

    // Vérifier si l'utilisateur est déjà connecté
    final prefs = await SharedPreferences.getInstance();
    final int? idStudent = prefs.getInt('idStudent');

    if (!mounted) return;

    // Navigation avec animation de fondu
    if (idStudent != null) {
      Navigator.of(context).pushReplacementNamed('/main');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          // Background top-right circle
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF155331).withOpacity(0.12),
              ),
            ),
          ),
          
          // Background top-left small circle
          Positioned(
            top: 150,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF155331).withOpacity(0.06),
              ),
            ),
          ),

          // Dot patterns (top and bottom)
          Positioned(
            top: 80,
            left: MediaQuery.of(context).size.width * 0.4,
            child: _buildDotPattern(opacity: 0.05),
          ),
          Positioned(
            bottom: 150,
            right: 20,
            child: _buildDotPattern(opacity: 0.08),
          ),

          // Background Bottom Waves
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _WaveClipper1(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.35,
                color: const Color(0xFF4CAF50).withOpacity(0.25),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _WaveClipper2(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.28,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D4B2A), Color(0xFF238E5E)],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
            ),
          ),

          // Main Content
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo ClassyOne
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF155331).withOpacity(0.12),
                                blurRadius: 40,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Image.asset(
                                'assets/images/classyone_icon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 35),

                        // App Name
                        const Text(
                          'ClassyOne',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0D4B2A),
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Subtitle
                        const Text(
                          'Votre Portail Étudiant',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 60),

                        // Custom animated loader
                        _ThreeDotsLoader(),
                        
                        // Push everything up slightly
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Version number at the bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Version 1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotPattern({double opacity = 0.05}) {
    return Opacity(
      opacity: opacity,
      child: Column(
        children: List.generate(
          4,
          (i) => Row(
            children: List.generate(
              4,
              (j) => Container(
                margin: const EdgeInsets.all(4),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D4B2A),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThreeDotsLoader extends StatefulWidget {
  @override
  State<_ThreeDotsLoader> createState() => _ThreeDotsLoaderState();
}

class _ThreeDotsLoaderState extends State<_ThreeDotsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF155331).withOpacity(0.1), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF155331).withOpacity(0.3))),
                const SizedBox(width: 4),
                Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xFF155331))),
                const SizedBox(width: 4),
                Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF155331).withOpacity(0.3))),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WaveClipper1 extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
        size.width * 0.3, size.height * 0.1, size.width * 0.8, size.height * 0.6);
    path.quadraticBezierTo(
        size.width * 0.9, size.height * 0.7, size.width, size.height * 0.6);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _WaveClipper2 extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(0, size.height * 0.45);
    path.quadraticBezierTo(
        size.width * 0.4, size.height * 0.95, size.width, size.height * 0.3);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

