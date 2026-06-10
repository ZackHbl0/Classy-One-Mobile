import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMatricule = prefs.getString('remembered_matricule') ?? '';
    final savedPassword = prefs.getString('remembered_password') ?? '';
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (rememberMe) {
      setState(() {
        _rememberMe = true;
        _matriculeController.text = savedMatricule;
        _passwordController.text = savedPassword;
      });
    }
  }

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

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Mot de passe oublié ?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1F3D),
            ),
          ),
          content: const Text(
            'Veuillez contacter l\'administration ou le support technique de l\'OSBT pour réinitialiser votre mot de passe.',
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Fermer',
                style: TextStyle(
                  color: Color(0xFF1A1F3D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _launchURL(
                  'https://api.whatsapp.com/send/?phone=%2B212661363127',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1F3D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Contacter Support'),
            ),
          ],
        );
      },
    );
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

        // Save or clear remembered credentials based on state
        if (_rememberMe) {
          await prefs.setString(
            'remembered_matricule',
            _matriculeController.text.trim(),
          );
          await prefs.setString(
            'remembered_password',
            _passwordController.text,
          );
          await prefs.setBool('remember_me', true);
        } else {
          await prefs.remove('remembered_matricule');
          await prefs.remove('remembered_password');
          await prefs.setBool('remember_me', false);
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
            colors: [Color(0xFFE2E8F0), Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
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

                // Logo ClassyOne Outside the card
                Center(
                  child: Image.asset(
                    'assets/images/Classy_One.png',
                    height: 85,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(
                  height: 100,
                ), // Increased space to push card down and fill gap

                ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(
                        28,
                        40,
                        28,
                        40,
                      ), // Balanced internal padding
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
                            const Text(
                              'Bienvenue\nConnectez-vous',
                              textAlign: TextAlign.center,
                              style: TextStyle(
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
                                const Text(
                                  'Matricule',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildStyledField(
                                  controller: _matriculeController,
                                  hintText: 'Entrez votre matricule',
                                  icon: Icons.person_outline,
                                  obscureText: false,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  keyboardType: TextInputType.text,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Veuillez entrer votre matricule';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Mot de passe',
                                  style: TextStyle(
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
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer votre mot de passe';
                                    }
                                    if (value.length < 4) {
                                      return 'Le mot de passe doit contenir au moins 4 caractères';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: _showForgotPasswordDialog,
                                    child: const Text(
                                      'Mot de passe oublié ?',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: primaryBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Remember Me Checkbox Row
                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: primaryBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Se souvenir de moi',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 25),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: primaryBlue
                                      .withOpacity(0.7),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 8,
                                  shadowColor: primaryBlue.withOpacity(0.4),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'Se connecter',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 50),

                            // Social Section Inside Card
                            const Text(
                              'Ou connectez-vous avec',
                              style: TextStyle(
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
                                    onTap: () =>
                                        _launchURL('mailto:contact@osbt.ma'),
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
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A1F3D), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        errorStyle: const TextStyle(
          color: Colors.redAccent,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      validator: validator,
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
                  color: _isHovered
                      ? widget.hoverColor
                      : widget.defaultColor.withOpacity(0.7),
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
