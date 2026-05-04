import 'dart:ui';
import 'package:flutter/material.dart';
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
    const primaryBlue = Color(0xFF203B68);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header with matching top padding (32px)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      padding: EdgeInsets.zero,
                      alignment: AlignmentDirectional.centerStart,
                    ),
                  const ScreenHeader(title: 'À propos'),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                child: Column(
                  children: [
                    // Glassmorphism App Logo
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.white.withOpacity(0.6),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.school_rounded,
                                size: 70,
                                color: isDark ? Colors.white : primaryBlue,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Branding
                    Text(
                      'OSBT Notify',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Developers Cards
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Développé par',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          textBaseline: TextBaseline.alphabetic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDeveloperCard(
                      name: 'Zakaria',
                      role: 'Développeur Full-Stack',
                      githubUrl: zakariaGithubUrl,
                      icon: Icons.code_rounded,
                      cardColor: cardColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      primaryBlue: primaryBlue,
                    ),
                    const SizedBox(height: 12),
                    _buildDeveloperCard(
                      name: 'Ahmed',
                      role: 'Développeur Full-Stack',
                      githubUrl: ahmedGithubUrl,
                      icon: Icons.developer_mode_rounded,
                      cardColor: cardColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      primaryBlue: primaryBlue,
                    ),

                    const SizedBox(height: 40),

                    // Useful Links Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Liens utiles',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          _buildLinkItem(
                            title: 'Site Web de l\'école',
                            icon: Icons.language_rounded,
                            onTap: () => _launchUrl(schoolWebsiteUrl),
                            textColor: textColor,
                            primaryBlue: primaryBlue,
                          ),
                          Divider(height: 1, color: Colors.grey.withOpacity(0.1), indent: 20, endIndent: 20),
                          _buildLinkItem(
                            title: 'Support Technique',
                            icon: Icons.mail_outline_rounded,
                            onTap: () => _launchUrl(supportEmailUrl),
                            textColor: textColor,
                            primaryBlue: primaryBlue,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Legal Buttons
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => _launchUrl(privacyPolicyUrl),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.withOpacity(0.1)),
                          ),
                        ),
                        child: Text(
                          'Politique de confidentialité',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => _launchUrl(termsOfServiceUrl),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.withOpacity(0.1)),
                          ),
                        ),
                        child: Text(
                          'Conditions d\'utilisation',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    Text(
                      '© 2026 OSBT. Tous droits réservés.',
                      style: TextStyle(
                        color: subtitleColor.withOpacity(0.6),
                        fontSize: 12,
                      ),
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

  Widget _buildDeveloperCard({
    required String name,
    required String role,
    required String githubUrl,
    required IconData icon,
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
    required Color primaryBlue,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryBlue, size: 24),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          role,
          style: TextStyle(
            color: subtitleColor,
            fontSize: 13,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new_rounded, size: 20),
          color: primaryBlue,
          onPressed: () => _launchUrl(githubUrl),
          tooltip: 'Voir le profil GitHub',
        ),
      ),
    );
  }

  Widget _buildLinkItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Color textColor,
    required Color primaryBlue,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: primaryBlue, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
