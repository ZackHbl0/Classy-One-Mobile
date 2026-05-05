import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class NewDocumentRequestPage extends StatefulWidget {
  const NewDocumentRequestPage({super.key});

  @override
  State<NewDocumentRequestPage> createState() => _NewDocumentRequestPageState();
}

class _NewDocumentRequestPageState extends State<NewDocumentRequestPage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _reasonController = TextEditingController();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  String _selectedDocType = 'Certificat de scolarité';
  String _selectedUrgency = 'normal';
  bool _isSubmitting = false;

  static const _primaryNavy  = Color(0xFF1A365D);
  static const _primaryBlue  = Color(0xFF3B82F6);
  static const _urgentAmber  = Color(0xFFF59E0B);
  static const _surfaceGrey  = Color(0xFFF1F5F9);
  static const _textMuted    = Color(0xFF64748B);
  static const _textDark     = Color(0xFF0F172A);

  final List<Map<String, dynamic>> _docTypes = [
    {'label': 'Certificat de scolarité',    'icon': Icons.school_outlined},
    {'label': 'Attestation d\'inscription', 'icon': Icons.assignment_outlined},
    {'label': 'Relevé de notes',            'icon': Icons.bar_chart_outlined},
    {'label': 'Convention de stage',        'icon': Icons.work_outline_rounded},
    {'label': 'Autre',                      'icon': Icons.description_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Submission ──────────────────────────────────────────────────────────────
  Future<void> _submitRequest() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    final prefs     = await SharedPreferences.getInstance();
    final idStudent = prefs.getInt('idStudent') ?? 0;

    final result = await _authService.createDocumentRequest(
      idStudent,
      _selectedDocType,
      _reasonController.text,
      _selectedUrgency,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      _showSuccessDialog();
    } else {
      _showErrorSnack(result['message'] ?? 'Une erreur est survenue');
    }
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon with glow
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF10B981),
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Demande envoyée !',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Votre demande a été transmise à l\'administration. Vous serez notifié(e) dès qu\'elle est traitée.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Compris',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Page descriptor ─────────────────────────────────────────
              _PageHint(
                icon: Icons.file_copy_outlined,
                text: 'Remplissez ce formulaire pour soumettre une demande de document administratif.',
              ),
              const SizedBox(height: 24),

              // ── Main form card ───────────────────────────────────────────
              _FormCard(
                children: [
                  // ── Document type ──────────────────────────────────────
                  _SectionLabel(label: 'Type de document'),
                  const SizedBox(height: 10),
                  _PremiumDropdown(
                    value: _selectedDocType,
                    items: _docTypes,
                    onChanged: (val) => setState(() => _selectedDocType = val),
                  ),

                  const SizedBox(height: 28),

                  // ── Urgency chips ──────────────────────────────────────
                  _SectionLabel(label: 'Niveau d\'urgence'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _UrgencyChip(
                          label: 'Normal',
                          icon: Icons.check_circle_outline_rounded,
                          value: 'normal',
                          selectedValue: _selectedUrgency,
                          activeColor: _primaryBlue,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedUrgency = 'normal');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _UrgencyChip(
                          label: 'Urgent',
                          icon: Icons.bolt_rounded,
                          value: 'urgent',
                          selectedValue: _selectedUrgency,
                          activeColor: _urgentAmber,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedUrgency = 'urgent');
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Reason textarea ────────────────────────────────────
                  _SectionLabel(label: 'Motif (Optionnel)'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _reasonController,
                    maxLines: 4,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white : _textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ex: Besoin pour mon dossier de stage…',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFFCBD5E1),
                        fontSize: 14,
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 56),
                        child: Icon(
                          Icons.edit_note_rounded,
                          color: Color(0xFF94A3B8),
                          size: 22,
                        ),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.05) : _surfaceGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: _primaryBlue,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Submit button ──────────────────────────────────────
                  _SubmitButton(
                    isSubmitting: _isSubmitting,
                    onPressed: _submitRequest,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _textDark,
            size: 20,
          ),
        ),
      ),
      title: Text(
        'Nouvelle demande',
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : _textDark,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PageHint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PageHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF3B82F6), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF3B82F6),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;

  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _PremiumDropdown extends StatelessWidget {
  final String value;
  final List<Map<String, dynamic>> items;
  final ValueChanged<String> onChanged;

  const _PremiumDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  IconData _iconFor(String val) {
    final match = items.firstWhere(
      (e) => e['label'] == val,
      orElse: () => {'icon': Icons.description_outlined},
    );
    return match['icon'] as IconData;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(_iconFor(value), color: const Color(0xFF3B82F6), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF94A3B8),
                ),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['label'] as String,
                    child: Row(
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 18,
                          color: const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 10),
                        Text(item['label'] as String),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => onChanged(val!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgencyChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String selectedValue;
  final Color activeColor;
  final VoidCallback onTap;

  const _UrgencyChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.selectedValue,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSelected = selectedValue == value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isSelected
            ? activeColor.withValues(alpha: 0.1)
            : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? activeColor : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  key: ValueKey(isSelected),
                  size: 18,
                  color: isSelected ? activeColor : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onPressed;

  const _SubmitButton({required this.isSubmitting, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A365D), Color(0xFF2563EB)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A365D).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isSubmitting ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                      Text(
                        'ENVOYER LA DEMANDE',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
