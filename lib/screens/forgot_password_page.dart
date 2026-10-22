import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_background.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String? initialIdentifier;

  const ForgotPasswordPage({super.key, this.initialIdentifier});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final AuthService _authService = AuthService();

  // Current Step: 1 = Identifier, 2 = OTP Code, 3 = New Password
  int _currentStep = 1;

  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _maskedContact;
  String? _resetToken;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialIdentifier != null && widget.initialIdentifier!.isNotEmpty) {
      _identifierController.text = widget.initialIdentifier!;
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Step 1: Request Code
  Future<void> _handleRequestCode() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      setState(() => _errorMessage = 'Veuillez saisir votre matricule, email ou téléphone.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _authService.forgotPassword(identifier);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _maskedContact = res['masked_contact'] ?? identifier;
        _currentStep = 2;
        // If debug_code is provided in dev mode, fill it automatically for convenience
        if (res['debug_code'] != null) {
          _otpController.text = res['debug_code'].toString();
        }
      });
      _showSnack(res['message'] ?? 'Code envoyé avec succès !');
    } else {
      setState(() => _errorMessage = res['message'] ?? 'Identifiant introuvable.');
    }
  }

  // Step 2: Verify Code
  Future<void> _handleVerifyCode() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Veuillez saisir le code complet à 6 chiffres.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _authService.verifyResetCode(_identifierController.text.trim(), code);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true && res['reset_token'] != null) {
      setState(() {
        _resetToken = res['reset_token'];
        _currentStep = 3;
      });
      _showSnack('Code validé. Définissez votre nouveau mot de passe.');
    } else {
      setState(() => _errorMessage = res['message'] ?? 'Code incorrect ou expiré.');
    }
  }

  // Step 3: Reset Password
  Future<void> _handleResetPassword() async {
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (pass.length < 6) {
      setState(() => _errorMessage = 'Le mot de passe doit comporter au moins 6 caractères.');
      return;
    }
    if (pass != confirm) {
      setState(() => _errorMessage = 'Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _authService.resetPassword(
      identifier: _identifierController.text.trim(),
      resetToken: _resetToken!,
      password: pass,
      confirmPassword: confirm,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      // Success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
              SizedBox(width: 10),
              Text('Succès', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            res['message'] ?? 'Votre mot de passe a été réinitialisé avec succès.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(); // Back to login screen
              },
              child: const Text('Se connecter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      setState(() => _errorMessage = res['message'] ?? 'Erreur lors de la réinitialisation.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: AuthBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Nav
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.08),
                    padding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 24),

                // Step Indicator
                _buildStepIndicator(),
                const SizedBox(height: 28),

                // Header
                Text(
                  _getStepTitle(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getStepSubtitle(),
                  style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 28),

                // Error Banner if present
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Step Body
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: _buildCurrentStepBody(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [1, 2, 3].map((step) {
        final isActive = _currentStep == step;
        final isPassed = _currentStep > step;
        return Expanded(
          child: Container(
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: isPassed
                  ? const Color(0xFF10B981)
                  : (isActive ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.12)),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Mot de passe oublié ?';
      case 2:
        return 'Code de vérification';
      case 3:
        return 'Nouveau mot de passe';
      default:
        return 'Récupération';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 1:
        return 'Entrez votre identifiant étudiant (matricule) ou votre email / téléphone parent pour recevoir un code.';
      case 2:
        return 'Entrez le code à 6 chiffres envoyé à ${_maskedContact ?? "votre contact"}.';
      case 3:
        return 'Définissez votre nouveau mot de passe sécurisé pour accéder à votre espace.';
      default:
        return '';
    }
  }

  Widget _buildCurrentStepBody() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1 UI
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _identifierController,
          label: 'Identifiant (Matricule, Email ou Téléphone)',
          icon: Icons.person_outline_rounded,
          hint: 'ex: 2026-ST-001 ou parent@domain.com',
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          label: 'Envoyer le code de vérification',
          icon: Icons.send_rounded,
          onPressed: _handleRequestCode,
        ),
      ],
    );
  }

  // STEP 2 UI
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _otpController,
          label: 'Code à 6 chiffres',
          icon: Icons.pin_rounded,
          hint: '000000',
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          label: 'Vérifier le code',
          icon: Icons.verified_user_rounded,
          onPressed: _handleVerifyCode,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading ? null : _handleRequestCode,
          child: const Text('Renvoyer un nouveau code', style: TextStyle(color: Color(0xFF60A5FA))),
        ),
      ],
    );
  }

  // STEP 3 UI
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _passwordController,
          label: 'Nouveau mot de passe',
          icon: Icons.lock_outline_rounded,
          hint: 'Au moins 6 caractères',
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _confirmPasswordController,
          label: 'Confirmer le mot de passe',
          icon: Icons.lock_reset_rounded,
          hint: 'Répétez le mot de passe',
          obscureText: _obscureConfirm,
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          label: 'Enregistrer le mot de passe',
          icon: Icons.check_circle_outline_rounded,
          onPressed: _handleResetPassword,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLength: maxLength,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              prefixIcon: Icon(icon, color: const Color(0xFF60A5FA), size: 22),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _isLoading ? null : onPressed,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}