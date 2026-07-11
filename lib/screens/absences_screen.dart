import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/screen_header.dart';
import '../widgets/custom_sidebar.dart';


class AppColors {
  static const Color primary = Color(0xFF2D3A2D);
  static const Color background = Color(0xFFE2E5E0);
  static const Color darkBackground = Color(0xFF1E241E);
  static const Color darkSurface = Color(0xFF2A322A);
  static const Color textPrimary = Color(0xFF1E241E);
  static const Color textSecondary = Color(0xFF64748B);
}

class AbsencesScreen extends StatefulWidget {
  const AbsencesScreen({Key? key}) : super(key: key);

  @override
  State<AbsencesScreen> createState() => _AbsencesScreenState();
}

class _AbsencesScreenState extends State<AbsencesScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _absences = [];

  @override
  void initState() {
    super.initState();
    _fetchAbsences();
  }

  Future<void> _fetchAbsences() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.getAbsences();

    if (!mounted) return;

    if (result['status'] == 'success') {
      setState(() {
        _absences = result['data'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Erreur de chargement des absences';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _showJustifyBottomSheet(BuildContext context, int absenceId, bool isDark) {
    final TextEditingController reasonController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Justifier l\'absence',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.grey[600]),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Motif de l\'absence',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    maxLines: 4,
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ex: Rendez-vous médical, Maladie...',
                      hintStyle: GoogleFonts.inter(
                        color: isDark ? Colors.white38 : Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.darkBackground : AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final reason = reasonController.text.trim();
                              if (reason.isEmpty) return;

                              setModalState(() {
                                isSubmitting = true;
                              });

                              final result = await _authService.submitJustification(absenceId, reason);

                              if (!mounted) return;

                              if (result['status'] == 'success') {
                                Navigator.pop(context); // close bottom sheet
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Justification envoyée avec succès',
                                            style: GoogleFonts.inter(),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.green[600],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                                _fetchAbsences(); // Refresh the list
                              } else {
                                setModalState(() {
                                  isSubmitting = false;
                                });
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ?? 'Erreur lors de l\'envoi'),
                                    backgroundColor: Colors.red[600],
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Envoyer',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1E241E)
          : const Color(0xFFF6F7F2),
      drawer: const CustomSidebar(currentRoute: '/absences'),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 32, 20, 0),
            child: ScreenHeader(title: 'Mes Absences', showBackButton: false),
          ),
          Expanded(child: _buildBody(isDark)),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchAbsences,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Réessayer',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (_absences.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.green[500],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune absence !',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous avez assisté à tous vos cours.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAbsences,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        itemCount: _absences.length + 1,
        itemBuilder: (context, index) {
          if (index == _absences.length) {
            return _buildAssiduiteCard(isDark);
          }
          final absence = _absences[index];
          return _buildFullAbsenceItem(absence, isDark);
        },
      ),
    );
  }

  Widget _buildFullAbsenceItem(Map<String, dynamic> absence, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroAbsenceCard(absence, isDark),
          const SizedBox(height: 16),
          _buildDetailsSection(absence, isDark),
          const SizedBox(height: 16),
          _buildNotesSection(absence, isDark),
        ],
      ),
    );
  }

  Widget _buildHeroAbsenceCard(Map<String, dynamic> absence, bool isDark) {
    final String status = absence['status'] ?? 'pending_justification';
    final String matiere = absence['matiere'] ?? 'Inconnue';
    final String seance = absence['seance'] ?? '--';
    final String date = absence['date'] != null ? _formatDate(absence['date']) : '--';
    final String professeur = absence['professeur'] ?? 'Inconnu';

    final bool isApproved = status == 'approved';
    final bool isSubmitted = status == 'submitted_by_student';

    final String initial = matiere.isNotEmpty ? matiere[0].toUpperCase() : 'M';
    final String title = matiere.split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');

    Color cardBgColor;
    Color cardBorderColor;
    Color badgeBgColor;
    Color badgeTextColor;
    String badgeText;
    IconData badgeIcon;

    if (isApproved) {
      cardBgColor = isDark ? Colors.green.withOpacity(0.08) : const Color(0xFFEDF8EE);
      cardBorderColor = isDark ? Colors.green.withOpacity(0.2) : Colors.green.withOpacity(0.3);
      badgeBgColor = Colors.green.withOpacity(0.2);
      badgeTextColor = isDark ? Colors.green[400]! : Colors.green[700]!;
      badgeText = 'Justifiée';
      badgeIcon = Icons.check_circle;
    } else if (isSubmitted) {
      cardBgColor = isDark ? Colors.orange.withOpacity(0.08) : const Color(0xFFFFF7ED);
      cardBorderColor = isDark ? Colors.orange.withOpacity(0.2) : Colors.orange.withOpacity(0.3);
      badgeBgColor = Colors.orange.withOpacity(0.2);
      badgeTextColor = isDark ? Colors.orange[400]! : Colors.orange[800]!;
      badgeText = 'En attente';
      badgeIcon = Icons.access_time_filled;
    } else {
      cardBgColor = isDark ? Colors.red.withOpacity(0.08) : const Color(0xFFFEF2F2);
      cardBorderColor = isDark ? Colors.red.withOpacity(0.2) : Colors.red.withOpacity(0.3);
      badgeBgColor = Colors.red.withOpacity(0.2);
      badgeTextColor = isDark ? Colors.red[400]! : Colors.red[700]!;
      badgeText = 'Non Justifiée';
      badgeIcon = Icons.error;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorderColor, width: 1.2),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: cardBorderColor.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Decorative Icon
            Positioned(
              right: -30,
              bottom: -20,
              child: Transform.rotate(
                angle: -0.2,
                child: Icon(
                  Icons.description,
                  size: 180,
                  color: isDark ? Colors.white.withOpacity(0.03) : badgeTextColor.withOpacity(0.05),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              badgeText,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: badgeTextColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(badgeIcon, size: 16, color: badgeTextColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 66.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroInfoRow(Icons.calendar_today_rounded, date, isDark),
                        const SizedBox(height: 12),
                        _buildHeroInfoRow(Icons.access_time_rounded, seance, isDark),
                        const SizedBox(height: 12),
                        _buildHeroInfoRow(Icons.person_outline_rounded, professeur, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroInfoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: isDark ? Colors.green[300] : Colors.green[700],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(Map<String, dynamic> absence, bool isDark) {
    final String status = absence['status'] ?? 'pending_justification';
    final String seance = absence['seance'] ?? '--';
    final String date = absence['date'] != null ? _formatDate(absence['date']) : '--';

    final bool isApproved = status == 'approved';
    final bool isSubmitted = status == 'submitted_by_student';

    String statusText;
    Color statusColor;

    if (isApproved) {
      statusText = 'Justifiée';
      statusColor = isDark ? Colors.green[400]! : Colors.green[700]!;
    } else if (isSubmitted) {
      statusText = 'En attente';
      statusColor = isDark ? Colors.orange[400]! : Colors.orange[800]!;
    } else {
      statusText = 'Non Justifiée';
      statusColor = isDark ? Colors.red[400]! : Colors.red[700]!;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('DÉTAILS DE L\'ABSENCE', isDark),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem(Icons.verified_user_outlined, 'Type', 'Cours', isDark, null),
              _buildDetailItem(Icons.local_offer_outlined, 'Statut', statusText, isDark, statusColor),
              _buildDetailItem(Icons.calendar_month_outlined, 'Date', date, isDark, null),
              _buildDetailItem(Icons.schedule, 'Heure', seance, isDark, null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, bool isDark, Color? valueColor) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF0FDF4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isDark ? Colors.white : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 30,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.green[600],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(Map<String, dynamic> absence, bool isDark) {
    final int id = absence['id'];
    final String status = absence['status'] ?? 'pending_justification';
    final String reason = absence['justification_reason'] ?? '';
    final bool isPendingStudent = status == 'pending_justification';

    if (reason.isEmpty && !isPendingStudent) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('NOTES', isDark),
          const SizedBox(height: 20),
          if (reason.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222822) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 24,
                    color: Colors.green[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        reason,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (isPendingStudent) ...[
            if (reason.isNotEmpty) const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _showJustifyBottomSheet(context, id, isDark),
                icon: const Icon(Icons.edit_document, size: 20, color: Colors.white),
                label: Text(
                  'Justifier cette absence',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.red[400] : Colors.red[600],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssiduiteCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.text_snippet,
                  size: 28,
                  color: isDark ? Colors.green[300] : Colors.green[600],
                ),
                Positioned(
                  top: 10,
                  right: 12,
                  child: Icon(
                    Icons.star,
                    size: 10,
                    color: Colors.yellow[700],
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 10,
                  child: Icon(
                    Icons.star,
                    size: 8,
                    color: Colors.yellow[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assiduité',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Continue ainsi ! Ta présence régulière est importante pour ta réussite.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 0.92,
                  strokeWidth: 6,
                  backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                ),
                Center(
                  child: Text(
                    '92%',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
