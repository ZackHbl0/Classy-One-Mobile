import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _matriculeController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $urlString');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir le lien : $e')),
        );
      }
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final result = await _authService.login(
        _matriculeController.text.trim(),
        _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (result['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final student = result['student'];
        if (student != null) {
          await prefs.setInt('idStudent', student.idStudent);
          await prefs.setString('matricule', student.matricule);
          await prefs.setString('nom', student.nom);
          await prefs.setString('prenom', student.prenom);
          await prefs.setString('telephone', student.telephone);
        }

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur de connexion'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1A1F3D); 
    const lightBg = Color(0xFFF1F5F9); 

    return Scaffold(
      backgroundColor: lightBg,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE2E8F0),
              Color(0xFFF8FAFC),
              Color(0xFFE2E8F0),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 15),

                // Logo OSBT Outside the card
                Center(
                  child: Image.asset(
                    'assets/images/osbt_logo.png',
                    height: 85,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 100), // Increased space to push card down and fill gap

                ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(28, 40, 28, 40), // Balanced internal padding
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${'login.welcome'.tr()}\n${'login.login_now'.tr()}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: primaryBlue,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 40),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'login.matricule'.tr(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildStyledField(
                                  controller: _matriculeController,
                                  hintText: 'Enter your matricule',
                                  icon: Icons.person_outline,
                                  obscureText: false,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'login.password'.tr(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildStyledField(
                                  controller: _passwordController,
                                  hintText: '••••••••',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  isPassword: true,
                                  onToggleVisibility: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 35),

                            // Login Button
                            _isLoading
                                ? const CircularProgressIndicator(color: primaryBlue)
                                : SizedBox(
                                    width: double.infinity,
                                    height: 58,
                                    child: ElevatedButton(
                                      onPressed: _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryBlue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        elevation: 8,
                                        shadowColor: primaryBlue.withOpacity(0.4),
                                      ),
                                      child: Text(
                                        'login.login_button'.tr(),
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),

                            const SizedBox(height: 50),

                            // Social Section Inside Card
                            Text(
                              'login.or_connect'.tr(),
                              style: const TextStyle(
                                color: Colors.black38,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 15),
                            // Compact social row to fix overflow
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _InteractiveSocialIcon(
                                    icon: FontAwesomeIcons.facebookF,
                                    defaultColor: primaryBlue,
                                    hoverColor: const Color(0xFF1877F2),
                                    size: 22,
                                    onTap: () => _launchURL(
                                      'https://www.facebook.com/OmniaSchoolCasablanca/',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _InteractiveSocialIcon(
                                    icon: Icons.mail_outline,
                                    defaultColor: primaryBlue,
                                    hoverColor: const Color(0xFFEA4335),
                                    size: 22,
                                    onTap: () => _launchURL('mailto:contact@osbt.ma'),
                                  ),
                                  const SizedBox(width: 12),
                                  _InteractiveSocialIcon(
                                    icon: FontAwesomeIcons.whatsapp,
                                    defaultColor: primaryBlue,
                                    hoverColor: const Color(0xFF25D366),
                                    size: 22,
                                    onTap: () => _launchURL(
                                      'https://api.whatsapp.com/send/?phone=%2B212661363127',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _InteractiveSocialIcon(
                                    icon: FontAwesomeIcons.instagram,
                                    defaultColor: primaryBlue,
                                    hoverColor: const Color(0xFFE4405F),
                                    size: 22,
                                    onTap: () => _launchURL(
                                      'https://www.instagram.com/omnia_school/',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyledField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool obscureText,
    bool isPassword = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.3),
            fontSize: 15,
          ),
          prefixIcon: Icon(icon, color: Colors.black45, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.black38,
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Requis';
          return null;
        },
      ),
    );
  }


  @override
  void dispose() {
    _matriculeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _InteractiveSocialIcon extends StatefulWidget {
  final IconData icon;
  final Color defaultColor;
  final Color hoverColor;
  final VoidCallback onTap;
  final double size;

  const _InteractiveSocialIcon({
    required this.icon,
    required this.defaultColor,
    required this.hoverColor,
    required this.onTap,
    this.size = 22,
  });

  @override
  State<_InteractiveSocialIcon> createState() => _InteractiveSocialIconState();
}

class _InteractiveSocialIconState extends State<_InteractiveSocialIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          transform: Matrix4.identity()..scale(_isHovered ? 1.15 : 1.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? widget.hoverColor.withOpacity(0.08)
                      : const Color(0xFFF1F5F9).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isHovered
                        ? widget.hoverColor.withOpacity(0.3)
                        : Colors.black.withOpacity(0.03),
                    width: 1,
                  ),
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: widget.hoverColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  widget.icon,
                  color: _isHovered ? widget.hoverColor : widget.defaultColor.withOpacity(0.7),
                  size: widget.size,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
