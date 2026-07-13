import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';

class PasswordChangePage extends StatefulWidget {
  const PasswordChangePage({super.key});

  @override
  State<PasswordChangePage> createState() => _PasswordChangePageState();
}

class _PasswordChangePageState extends State<PasswordChangePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Password strength
  double _strength = 0.0;
  String _strengthLabel = '';
  String _strengthSublabel = '';

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  final AuthService _authService = AuthService();

  static const Color _primary = Color(0xFF10B981);
  static const Color _primaryDark = Color(0xFF065F46);
  static const Color _blue = Color(0xFF0284C7);

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation =
        Tween<double>(begin: 0.3, end: 0.7).animate(_glowController);

    _newController.addListener(_evaluateStrength);
  }

  void _evaluateStrength() {
    final val = _newController.text;
    double s = 0;
    if (val.length >= 8) s += 0.25;
    if (val.contains(RegExp(r'[A-Z]'))) s += 0.25;
    if (val.contains(RegExp(r'[0-9]'))) s += 0.25;
    if (val.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) s += 0.25;

    String label = '';
    String sub = '';
    if (s <= 0.25) {
      label = 'Faible';
      sub = 'Sécurité faible';
    } else if (s <= 0.5) {
      label = 'Moyen';
      sub = 'Sécurité moyenne';
    } else if (s <= 0.75) {
      label = 'Fort';
      sub = 'Sécurité élevée';
    } else {
      label = 'Très fort';
      sub = 'Sécurité élevée';
    }

    setState(() {
      _strength = s;
      _strengthLabel = label;
      _strengthSublabel = sub;
    });
  }

  Color get _strengthColor {
    if (_strength <= 0.25) return Colors.redAccent;
    if (_strength <= 0.5) return Colors.orange;
    if (_strength <= 0.75) return _primary;
    return _primary;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final idStudent = prefs.getInt('idStudent') ?? 0;

    final result = await _authService.updatePassword(
      idStudent,
      _currentController.text,
      _newController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe mis à jour avec succès'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor =
        isDark ? const Color(0xFF1E241E) : const Color(0xFFE2E5E0);
    final cardColor = isDark ? const Color(0xFF2A322A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subtitleColor =
        isDark ? Colors.white60 : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ─── Header ──────────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.chevron_left_rounded,
                          color: textColor, size: 24),
                    ),
                  ),
                  // Title
                  Text(
                    'Changer le mot de passe',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  // Notification Bell
                  Stack(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cardColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.notifications_none_rounded,
                            color: textColor, size: 20),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── Scrollable body ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ── Glowing Shield Graphic ────────────────────────────
                    _buildShieldGraphic(isDark),
                    const SizedBox(height: 20),

                    // ── Title + Subtitle ──────────────────────────────────
                    Text(
                      'Votre compte est sécurisé',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choisissez un nouveau mot de passe fort\npour protéger votre compte.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Password Fields Card ──────────────────────────────
                    _buildPasswordCard(isDark, cardColor, textColor),
                    const SizedBox(height: 20),

                    // ── Security Requirements ─────────────────────────────
                    _buildSecurityChecklist(isDark, cardColor, textColor),
                    const SizedBox(height: 28),

                    // ── Gradient Action Button ────────────────────────────
                    _buildGradientButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Glowing Shield Graphic ─────────────────────────────────────────────
  Widget _buildShieldGraphic(bool isDark) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (_, __) {
        return SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primary.withOpacity(
                      0.06 + _glowAnimation.value * 0.06),
                ),
              ),
              // Middle ring
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primary.withOpacity(
                      0.10 + _glowAnimation.value * 0.05),
                ),
              ),
              // Inner circle
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF1A2E1A)
                      : const Color(0xFFF0FAF4),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(_glowAnimation.value * 0.35),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Decorative dots (top-right arc)
              ...List.generate(6, (i) {
                final angle = -0.8 + i * 0.3;
                return Positioned(
                  right: 10 + (i % 2 == 0 ? 6.0 : 0),
                  top: 12 + i * 9.0,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _primary
                          .withOpacity(0.3 + _glowAnimation.value * 0.2),
                    ),
                  ),
                );
              }),
              // Decorative dots (bottom-left arc)
              ...List.generate(5, (i) {
                return Positioned(
                  left: 8 + (i % 2 == 0 ? 4.0 : 0),
                  bottom: 16 + i * 9.0,
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _primary
                          .withOpacity(0.2 + _glowAnimation.value * 0.15),
                    ),
                  ),
                );
              }),
              // Shield icon
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [_primary, _primaryDark],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: const Icon(
                  Icons.verified_user_rounded,
                  size: 52,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Password Fields Card ────────────────────────────────────────────────
  Widget _buildPasswordCard(bool isDark, Color cardColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Current password
          _buildFieldRow(
            controller: _currentController,
            label: 'Mot de passe actuel',
            icon: Icons.lock_outlined,
            obscure: _obscureCurrent,
            isDark: isDark,
            textColor: textColor,
            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
            isFirst: true,
            isLast: false,
          ),
          _buildDivider(isDark),

          // New password
          _buildFieldRow(
            controller: _newController,
            label: 'Nouveau mot de passe',
            icon: Icons.person_outline_rounded,
            obscure: _obscureNew,
            isDark: isDark,
            textColor: textColor,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
            isFirst: false,
            isLast: false,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un mot de passe';
              }
              if (value.length < 8) return 'Minimum 8 caractères';
              return null;
            },
          ),

          // Strength bar (between new & confirm)
          if (_newController.text.isNotEmpty) _buildStrengthBar(isDark),

          _buildDivider(isDark),

          // Confirm password
          _buildFieldRow(
            controller: _confirmController,
            label: 'Confirmer le nouveau mot de passe',
            icon: Icons.shield_outlined,
            obscure: _obscureConfirm,
            isDark: isDark,
            textColor: textColor,
            onToggle: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            isFirst: false,
            isLast: true,
            validator: (value) {
              if (value != _newController.text) {
                return 'Les mots de passe ne correspondent pas';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color:
          isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildFieldRow({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    required bool isDark,
    required Color textColor,
    required VoidCallback onToggle,
    required bool isFirst,
    required bool isLast,
    String? Function(String?)? validator,
  }) {
    final iconBg = isDark
        ? const Color(0xFF1E3A2A)
        : const Color(0xFFECFDF5);

    final radius = BorderRadius.only(
      topLeft: isFirst ? const Radius.circular(24) : Radius.zero,
      topRight: isFirst ? const Radius.circular(24) : Radius.zero,
      bottomLeft: isLast ? const Radius.circular(24) : Radius.zero,
      bottomRight: isLast ? const Radius.circular(24) : Radius.zero,
    );

    return ClipRRect(
      borderRadius: radius,
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator ??
            (v) =>
                v == null || v.isEmpty ? 'Champ requis' : null,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          filled: true,
          fillColor: isDark
              ? const Color(0xFF2A322A)
              : Colors.white,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _primary, size: 16),
            ),
          ),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
            ),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide:
                const BorderSide(color: _primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide:
                const BorderSide(color: Colors.redAccent, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide:
                const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  // ─── Password Strength Bar ───────────────────────────────────────────────
  Widget _buildStrengthBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          // 4 segment bar
          Row(
            children: List.generate(4, (i) {
              final filled = _strength > i * 0.25;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  height: 5,
                  decoration: BoxDecoration(
                    color: filled
                        ? _strengthColor
                        : (isDark
                            ? Colors.white.withOpacity(0.12)
                            : const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined,
                      size: 12, color: _strengthColor),
                  const SizedBox(width: 4),
                  Text(
                    _strengthLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _strengthColor,
                    ),
                  ),
                ],
              ),
              Text(
                _strengthSublabel,
                style: TextStyle(
                  fontSize: 11,
                  color: _strengthColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Security Checklist ──────────────────────────────────────────────────
  Widget _buildSecurityChecklist(
      bool isDark, Color cardColor, Color textColor) {
    final pass = _newController.text;
    final checks = [
      {
        'label': 'Minimum 8 caractères',
        'ok': pass.length >= 8,
      },
      {
        'label': 'Une lettre majuscule',
        'ok': pass.contains(RegExp(r'[A-Z]')),
      },
      {
        'label': 'Un chiffre (0-9)',
        'ok': pass.contains(RegExp(r'[0-9]')),
      },
      {
        'label': 'Un symbole spécial (!@#\$)',
        'ok': pass.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]')),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  size: 18, color: _primary),
              const SizedBox(width: 8),
              Text(
                'Exigences de sécurité',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 10,
            children: checks.map((c) {
              final ok = c['ok'] as bool;
              return Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: ok
                          ? _primary
                          : (isDark
                              ? Colors.white12
                              : const Color(0xFFE5E7EB)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      ok ? Icons.check_rounded : Icons.close_rounded,
                      size: 12,
                      color: ok
                          ? Colors.white
                          : (isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      c['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: ok
                            ? _primary
                            : (isDark
                                ? Colors.white54
                                : const Color(0xFF6B7280)),
                        fontWeight:
                            ok ? FontWeight.w600 : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Gradient Action Button ──────────────────────────────────────────────
  Widget _buildGradientButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [_primary, _blue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: _isLoading ? null : _submit,
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.lock_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'MODIFIER LE MOT DE PASSE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
