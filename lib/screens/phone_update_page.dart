import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';

class PhoneUpdatePage extends StatefulWidget {
  const PhoneUpdatePage({super.key});

  @override
  State<PhoneUpdatePage> createState() => _PhoneUpdatePageState();
}

class _PhoneUpdatePageState extends State<PhoneUpdatePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  static const Color _primary = Color(0xFF10B981);
  static const Color _primaryDark = Color(0xFF065F46);
  static const Color _blue = Color(0xFF0284C7);

  @override
  void initState() {
    super.initState();
    _loadCurrentPhone();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation =
        Tween<double>(begin: 0.3, end: 0.7).animate(_glowController);
  }

  Future<void> _loadCurrentPhone() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _phoneController.text = prefs.getString('telephone') ?? '';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final idStudent = prefs.getInt('idStudent') ?? 0;

    // Remove spaces before sending to API
    final rawPhone = _phoneController.text.replaceAll(' ', '');

    final result = await _authService.updatePhone(
      idStudent,
      rawPhone,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        await prefs.setString('telephone', rawPhone);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Téléphone mis à jour avec succès'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
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
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDark ? const Color(0xFF1E241E) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF2A322A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subtitleColor = isDark ? Colors.white60 : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ─── Header ──────────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                  Text(
                    'Mettre à jour le téléphone',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ── Glowing Graphic ───────────────────────────────────
                    _buildPhoneGraphic(isDark),
                    const SizedBox(height: 24),

                    // ── Title + Subtitle ──────────────────────────────────
                    Text(
                      'Gardez votre compte',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'toujours accessible',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Veuillez entrer votre nouveau numéro de\ntéléphone pour rester en contact.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Phone Input Card ──────────────────────────────────
                    _buildPhoneCard(isDark, cardColor, textColor, subtitleColor),
                    const SizedBox(height: 24),

                    // ── Info Card (Pourquoi mettre à jour) ────────────────
                    _buildInfoCard(isDark, cardColor, textColor, subtitleColor),
                    const SizedBox(height: 32),

                    // ── Gradient Action Button ────────────────────────────
                    _buildGradientButton(),
                    
                    const SizedBox(height: 20),
                    
                    // ── Bottom secure text ────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 14, color: subtitleColor),
                        const SizedBox(width: 6),
                        Text(
                          'Vos données sont chiffrées et sécurisées.',
                          style: TextStyle(fontSize: 11, color: subtitleColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Glowing Graphic ─────────────────────────────────────────────────────
  Widget _buildPhoneGraphic(bool isDark) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (_, __) {
        return SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primary.withOpacity(0.04 + _glowAnimation.value * 0.04),
                ),
              ),
              // Middle ring
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primary.withOpacity(0.08 + _glowAnimation.value * 0.04),
                ),
              ),
              // Inner circle
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1A2E1A) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(_glowAnimation.value * 0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Decorative stars
              ...List.generate(4, (i) {
                final positions = [
                  const Offset(20, 20),
                  const Offset(150, 30),
                  const Offset(30, 140),
                  const Offset(150, 140),
                ];
                return Positioned(
                  left: positions[i].dx,
                  top: positions[i].dy,
                  child: Icon(
                    Icons.star_rounded,
                    size: i % 2 == 0 ? 10 : 6,
                    color: _primary.withOpacity(0.4 + _glowAnimation.value * 0.3),
                  ),
                );
              }),
              // Phone icon and check badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [_primary, _primaryDark],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.smartphone_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A2E1A) : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: _primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Phone Input Card ────────────────────────────────────────────────────
  Widget _buildPhoneCard(bool isDark, Color cardColor, Color textColor, Color subtitleColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : const Color(0xFFF0FDF4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_iphone_rounded, size: 14, color: _primary),
              ),
              const SizedBox(width: 8),
              Text(
                'Nouveau numéro de téléphone',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Input field container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                // Removed Flag and +212 section
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 1.2,
                      color: textColor,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                      _PhoneNumberFormatter(),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre numéro';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: '06 00 00 00 00',
                      hintStyle: TextStyle(
                        color: subtitleColor.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, size: 14, color: _primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_outlined, size: 12, color: _primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Nous ne partagerons jamais votre numéro avec des tiers.',
                  style: TextStyle(fontSize: 10, color: subtitleColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Info Card ───────────────────────────────────────────────────────────
  Widget _buildInfoCard(bool isDark, Color cardColor, Color textColor, Color subtitleColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF0FDF4).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFDCFCE7),
        ),
      ),
      child: Row(
        children: [
          // Left Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.lock_outline_rounded, color: _primary, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          // Right Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pourquoi mettre à jour ?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInfoItem(Icons.chat_bubble_outline_rounded, 'Recevez vos\nnotifications', subtitleColor),
                    ),
                    Expanded(
                      child: _buildInfoItem(Icons.shield_outlined, 'Sécurisez\nvotre compte', subtitleColor),
                    ),
                    Expanded(
                      child: _buildInfoItem(Icons.headset_mic_outlined, 'Contactez le support\nfacilement', subtitleColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _primary),
        const SizedBox(height: 6),
        Text(
          text,
          style: TextStyle(fontSize: 9, color: color, height: 1.3),
        ),
      ],
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
          colors: [_primary, _primaryDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.3),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.verified_user_outlined, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'VALIDER LE NUMÉRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    // Removed space logic, just keeping digits and formatting spaces
    // to match 069 874 56 29 format
    final clean = text.replaceAll(RegExp(r'\D'), '');
    
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i == 3 || i == 6 || i == 8) {
        buffer.write(' ');
      }
      buffer.write(clean[i]);
    }

    final newString = buffer.toString();
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
