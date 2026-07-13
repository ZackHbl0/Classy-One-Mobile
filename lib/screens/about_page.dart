import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/screen_header.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  final String zakariaGithubUrl = "https://github.com/ZackHbl0";
  final String ahmedGithubUrl = "https://github.com/Ahmed-mk05";
  final String privacyPolicyUrl = "https://osbt.ma/privacy";
  final String termsOfServiceUrl = "https://osbt.ma/terms";
  final String schoolWebsiteUrl = "https://osbt.ma";
  final String supportEmailUrl = "mailto:support@osbt.ma";
  final String documentationUrl = "https://osbt.ma/docs";

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Impossible d'ouvrir l'URL: $urlString");
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF10B981);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E241E) : const Color(0xFFF6F7F2);
    final cardColor = isDark ? const Color(0xFF2A322A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subtitleColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final dividerColor = isDark ? Colors.white10 : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (Navigator.canPop(context))
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back, color: textColor),
                        tooltip: 'Retour',
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                  Text(
                    "À propos",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.notifications_none_rounded, color: textColor),
                        ),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Column(
                  children: [
                    // ── App Hero Card ─────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Logo
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: primary.withOpacity(0.25), width: 1.5),
                                ),
                                child: Center(
                                  child: Icon(Icons.school_rounded, color: primary, size: 36),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Title + version + desc
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'OSBT Notify',
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: primary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Version 1.0.0',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'La plateforme officielle de l\'école pour\nune communication simple et efficace.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: subtitleColor,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(color: dividerColor, height: 1),
                          const SizedBox(height: 16),
                          // Badges Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildBadge(Icons.check_circle_outline_rounded, 'Stable Release', primary),
                              _buildBadge(Icons.security_rounded, 'Sécurisé', primary),
                              _buildBadge(
                                Icons.update_rounded,
                                'Mis à jour\n14 Mai 2026',
                                primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Développé avec ❤️ par ────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Développé avec ', primary, heart: true),
                          const SizedBox(height: 16),
                          _buildDeveloperRow(
                            name: 'Zakaria',
                            role: 'Développeur Full-Stack',
                            initial: 'Z',
                            avatarColor: const Color(0xFF6366F1),
                            onTap: () => _launchUrl(zakariaGithubUrl),
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            primary: primary,
                            dividerColor: dividerColor,
                            showDivider: true,
                          ),
                          _buildDeveloperRow(
                            name: 'Ahmed',
                            role: 'Développeur Full-Stack',
                            initial: 'A',
                            avatarColor: const Color(0xFFF59E0B),
                            onTap: () => _launchUrl(ahmedGithubUrl),
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            primary: primary,
                            dividerColor: dividerColor,
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Two columns: Liens utiles + Informations ──────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Liens utiles
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Liens utiles', primary),
                                const SizedBox(height: 12),
                                _buildSmallLink(Icons.language_rounded, 'Site Web de l\'école', primary, textColor, subtitleColor, () => _launchUrl(schoolWebsiteUrl)),
                                const SizedBox(height: 10),
                                _buildSmallLink(Icons.mail_outline_rounded, 'Support Technique', primary, textColor, subtitleColor, () => _launchUrl(supportEmailUrl)),
                                const SizedBox(height: 10),
                                _buildSmallLink(Icons.article_outlined, 'Documentation', primary, textColor, subtitleColor, () => _launchUrl(documentationUrl)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Informations techniques
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Informations', primary),
                                const SizedBox(height: 12),
                                _buildInfoRow(Icons.tag_rounded, 'Version', '1.0.0', textColor, subtitleColor, primary),
                                _buildInfoRow(Icons.build_outlined, 'Build', '240701', textColor, subtitleColor, primary),
                                _buildInfoRow(Icons.flutter_dash_rounded, 'Framework', 'Flutter 3.35', textColor, subtitleColor, primary),
                                _buildInfoRow(Icons.dns_outlined, 'Backend', 'Laravel 12', textColor, subtitleColor, primary),
                                _buildInfoRow(Icons.storage_rounded, 'Base de données', 'MySQL', textColor, subtitleColor, primary),
                                _buildInfoRow(Icons.api_rounded, 'API', 'REST', textColor, subtitleColor, primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Fonctionnalités ───────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Fonctionnalités', primary),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildFeatureIcon(Icons.calendar_today_rounded, 'Agenda', primary, textColor),
                              _buildFeatureIcon(Icons.payments_outlined, 'Paiements', primary, textColor),
                              _buildFeatureIcon(Icons.description_outlined, 'Documents', primary, textColor),
                              _buildFeatureIcon(Icons.chat_bubble_outline_rounded, 'Messagerie', primary, textColor),
                              _buildFeatureIcon(Icons.note_alt_outlined, 'Notes', primary, textColor),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Footer ────────────────────────────────────────────
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 4, height: 4, decoration: BoxDecoration(color: primary, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(
                              '© 2026 OSBT Notify',
                              style: GoogleFonts.poppins(fontSize: 12, color: subtitleColor, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 8),
                            Container(width: 4, height: 4, decoration: BoxDecoration(color: primary, shape: BoxShape.circle)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            GestureDetector(
                              onTap: () => _launchUrl(privacyPolicyUrl),
                              child: Text('Politique de confidentialité', style: GoogleFonts.poppins(fontSize: 11, color: subtitleColor)),
                            ),
                            Text(' • ', style: GoogleFonts.poppins(fontSize: 11, color: subtitleColor)),
                            GestureDetector(
                              onTap: () => _launchUrl(termsOfServiceUrl),
                              child: Text('Conditions d\'utilisation', style: GoogleFonts.poppins(fontSize: 11, color: subtitleColor)),
                            ),
                            Text(' • ', style: GoogleFonts.poppins(fontSize: 11, color: subtitleColor)),
                            Text('Licences Open Source', style: GoogleFonts.poppins(fontSize: 11, color: subtitleColor)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color primary, {bool heart = false}) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF374151)),
        ),
        if (heart) ...[
          const SizedBox(width: 4),
          const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 14),
          Text(' par', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF374151))),
        ],
      ],
    );
  }

  Widget _buildBadge(IconData icon, String label, Color primary) {
    return Row(
      children: [
        Icon(icon, color: primary, size: 14),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildDeveloperRow({
    required String name,
    required String role,
    required String initial,
    required Color avatarColor,
    required VoidCallback onTap,
    required Color textColor,
    required Color subtitleColor,
    required Color primary,
    required Color dividerColor,
    required bool showDivider,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: avatarColor.withOpacity(0.15),
                child: Text(
                  initial,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: avatarColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                    Text(role, style: GoogleFonts.poppins(fontSize: 12, color: subtitleColor)),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: primary.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.chevron_right_rounded, color: primary, size: 18),
              ),
            ],
          ),
        ),
        if (showDivider) ...[
          const SizedBox(height: 12),
          Divider(color: dividerColor, height: 1),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildSmallLink(IconData icon, String title, Color primary, Color textColor, Color subtitleColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: primary, size: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: GoogleFonts.poppins(fontSize: 11, color: textColor, fontWeight: FontWeight.w500)),
          ),
          Icon(Icons.chevron_right_rounded, color: subtitleColor, size: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color textColor, Color subtitleColor, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: primary, size: 13),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: 10, color: subtitleColor))),
          Text(value, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label, Color primary, Color textColor) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: primary, size: 22),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: textColor, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
