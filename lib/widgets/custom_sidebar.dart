import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../screens/profile_page.dart';
import '../screens/grades_screen.dart';
import '../screens/absences_screen.dart';
import '../screens/evenements_page.dart';
import '../screens/paiement_page.dart';
import '../screens/settings_page.dart';
import '../screens/main_screen.dart';
import '../screens/documents_page.dart';
import '../screens/recent_chats_screen.dart';

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
    final bgColor = isDark ? const Color(0xFF1E241E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    final primaryColor = Theme.of(context).primaryColor;

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
                      ),
                      const SizedBox(width: 12),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Classy',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            TextSpan(
                              text: 'One',
                              style: TextStyle(
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
                        color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                            color: primaryColor.withOpacity(0.5),
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 32),
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
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                    style: TextStyle(fontSize: 14, color: iconColor, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(24),
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
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.wb_sunny_outlined, size: 18, color: !themeProvider.isDarkMode ? primaryColor : iconColor),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Light',
                                        style: TextStyle(
                                          fontSize: 14,
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
                                              blurRadius: 4,
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
                                        style: TextStyle(
                                          fontSize: 14,
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
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
                    icon: Icons.chat_bubble_outline,
                    label: 'Messagerie',
                    textColor: textColor,
                    iconColor: iconColor,
                    isActive: widget.currentRoute == '/messagerie',
                    onTap: () => _navigateTo(context, const RecentChatsScreen()),
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

            // ── Footer (Logout) ──
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: InkWell(
                onTap: () => _logout(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                      const SizedBox(width: 12),
                      const Text(
                        'Déconnexion',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
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

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.iconColor,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final displayTextColor = isActive ? primaryColor : textColor;
    final displayIconColor = isActive ? primaryColor : iconColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isActive 
             ? (isDark ? primaryColor.withOpacity(0.15) : primaryColor.withOpacity(0.08))
             : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Left active bar
            Container(
              width: 3,
              height: 24,
              margin: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isActive ? primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 16),
            Icon(icon, size: 22, color: displayIconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: displayTextColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isActive)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(Icons.chevron_right, size: 18, color: iconColor.withOpacity(0.5)),
              ),
          ],
        ),
      ),
    );
  }
}
