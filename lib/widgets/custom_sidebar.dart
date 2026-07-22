import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../screens/profile_page.dart';
import '../screens/grades_screen.dart';
import '../screens/absences_screen.dart';
import '../screens/evenements_page.dart';
import '../screens/paiement_page.dart';
import '../screens/settings_page.dart';
import '../screens/main_screen.dart';
import '../screens/documents_page.dart';


class CustomSidebar extends StatefulWidget {
  final String? currentRoute;
  const CustomSidebar({super.key, this.currentRoute});

  @override
  State<CustomSidebar> createState() => _CustomSidebarState();
}

class _CustomSidebarState extends State<CustomSidebar> {
  String _userName = 'Utilisateur';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final nom = prefs.getString('nom') ?? '';
    final prenom = prefs.getString('prenom') ?? '';
    if (nom.isNotEmpty || prenom.isNotEmpty) {
      setState(() {
        _userName = '$prenom $nom'.trim();
      });
    }
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pop(context); // Close drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E241E) : const Color(0xFFF9FAFB);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    final primaryColor = const Color(0xFF10B981); // Emerald green

    return Drawer(
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header (Logo + Close button) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/classyone_icon.png',
                        width: 32,
                        height: 32,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.school, color: primaryColor, size: 32),
                      ),
                      const SizedBox(width: 12),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Classy',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            TextSpan(
                              text: 'One',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                      ),
                      child: Icon(Icons.close, color: iconColor, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── User Info Card ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withOpacity(0.15),
                          ),
                          // Placeholder user image using an icon since we don't have the user image asset
                          child: Icon(Icons.person, color: primaryColor, size: 32),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello,',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userName,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Étudiant',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Theme Switcher ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thème',
                    style: GoogleFonts.poppins(fontSize: 13, color: iconColor, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: !isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (themeProvider.isDarkMode) themeProvider.toggleTheme();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !themeProvider.isDarkMode ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: !themeProvider.isDarkMode
                                        ? [
                                            BoxShadow(
                                              color: primaryColor.withOpacity(0.15),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : [],
                                    border: !themeProvider.isDarkMode
                                        ? Border.all(color: primaryColor.withOpacity(0.3))
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.wb_sunny_outlined, size: 18, color: !themeProvider.isDarkMode ? primaryColor : iconColor),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Light',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: !themeProvider.isDarkMode ? FontWeight.w600 : FontWeight.w500,
                                          color: !themeProvider.isDarkMode ? primaryColor : iconColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (!themeProvider.isDarkMode) themeProvider.toggleTheme();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: themeProvider.isDarkMode ? const Color(0xFF404040) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: themeProvider.isDarkMode
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.nightlight_round, size: 18, color: themeProvider.isDarkMode ? Colors.white : iconColor),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Dark',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: themeProvider.isDarkMode ? FontWeight.w600 : FontWeight.w500,
                                          color: themeProvider.isDarkMode ? Colors.white : iconColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Menu Items ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: !isDark
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        _MenuItem(
                          icon: Icons.home_outlined,
                          label: 'Home',
                          textColor: textColor,
                          iconColor: iconColor,
                          isActive: widget.currentRoute == '/home' || widget.currentRoute == null,
                          onTap: () {
                            Navigator.pop(context); // Close drawer
                            if (widget.currentRoute != '/home' && widget.currentRoute != null) {
                               Navigator.popUntil(context, (route) => route.isFirst);
                            }
                          },
                        ),
                        _MenuItem(
                          icon: Icons.bar_chart_rounded,
                          label: 'Mes Notes',
                          textColor: textColor,
                          iconColor: iconColor,
                          isActive: widget.currentRoute == '/grades',
                          onTap: () => _navigateTo(context, const GradesScreen()),
                        ),
                        _MenuItem(
                          icon: Icons.event_busy_outlined,
                          label: 'Mes Absences',
                          textColor: textColor,
                          iconColor: iconColor,
                          isActive: widget.currentRoute == '/absences',
                          onTap: () => _navigateTo(context, const AbsencesScreen()),
                        ),

                        _MenuItem(
                          icon: Icons.description_outlined,
                          label: 'Documents',
                          textColor: textColor,
                          iconColor: iconColor,
                          isActive: widget.currentRoute == '/documents',
                          onTap: () => _navigateTo(context, const DocumentsPage()),
                        ),
                        _MenuItem(
                          icon: Icons.event_outlined,
                          label: 'Événements',
                          textColor: textColor,
                          iconColor: iconColor,
                          isActive: widget.currentRoute == '/evenements',
                          onTap: () => _navigateTo(context, const EvenementsPage()),
                        ),
                        _MenuItem(
                          icon: Icons.settings_outlined,
                          label: 'Paramètres',
                          textColor: textColor,
                          iconColor: iconColor,
                          isActive: widget.currentRoute == '/settings',
                          onTap: () => _navigateTo(context, const SettingsPage()),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Logout ──
                  InkWell(
                    onTap: () => _logout(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF3F2A2A) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(isDark ? 0.1 : 0.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Déconnexion',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Version Footer ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: !isDark
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.nightlight_round, color: primaryColor, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vous utilisez',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                ),
                              ),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'ClassyOne ',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'v2.0.0',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : const Color(0xFFF9FAFB),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.keyboard_arrow_up_rounded, color: iconColor, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isActive;
  final int? badgeCount;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.iconColor,
    required this.onTap,
    this.isActive = false,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF10B981); // Emerald Green
    final displayTextColor = isActive ? primaryColor : textColor;
    final displayIconColor = isActive ? Colors.white : iconColor;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive 
             ? (isDark ? primaryColor.withOpacity(0.05) : primaryColor.withOpacity(0.05))
             : Colors.transparent,
          border: isActive
              ? Border(
                  left: BorderSide(color: primaryColor, width: 3),
                )
              : const Border(left: BorderSide(color: Colors.transparent, width: 3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: displayIconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: displayTextColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badgeCount != null && badgeCount! > 0)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            Icon(Icons.chevron_right, size: 16, color: isActive ? primaryColor : iconColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
