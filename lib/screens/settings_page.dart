import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/premium_switch.dart';
import 'contact_support_page.dart';
import 'about_page.dart';
import 'login_page.dart'; // Add login page for logout
import '../services/auth_service.dart'; // Add AuthService for logout
import '../widgets/screen_header.dart';
import '../widgets/custom_sidebar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();

  void _logout() async {
    try {
      await _authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Erreur lors de la déconnexion',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final primaryColor = const Color(0xFF10B981); // Emerald green for this UI

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1E241E)
          : const Color(0xFFF9FAFB),
      drawer: const CustomSidebar(currentRoute: '/settings'),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 32, 20, 0),
            child: ScreenHeader(title: 'Paramètres', showBackButton: false),
          ),
          Expanded(
            child: _buildContent(
              settingsProvider,
              themeProvider,
              context,
              isDark,
              primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    SettingsProvider settingsProvider,
    ThemeProvider themeProvider,
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionHeader('NOTIFICATIONS', isDark, primaryColor),
        _buildSettingsCard(isDark, primaryColor, [
          _buildSwitchTile(
            Icons.notifications_active_outlined,
            'Activer les notifications',
            'Recevez des notifications importantes',
            settingsProvider.notificationsEnabled,
            (val) => settingsProvider.toggleNotifications(val),
            isDark,
            context,
          ),
          _buildSwitchTile(
            Icons.event_outlined,
            'Rappels d\'événements',
            'Soyez notifié des événements à venir',
            settingsProvider.eventRemindersEnabled,
            (val) => settingsProvider.toggleEventReminders(val),
            isDark,
            context,
          ),
          _buildSwitchTile(
            Icons.account_balance_wallet_outlined,
            'Rappels de paiement',
            'Ne manquez jamais une échéance',
            settingsProvider.paymentRemindersEnabled,
            (val) => settingsProvider.togglePaymentReminders(val),
            isDark,
            context,
            showBorder: false,
          ),
        ]),

        const SizedBox(height: 32),

        _buildSectionHeader('PRÉFÉRENCES', isDark, primaryColor),
        _buildSettingsCard(isDark, primaryColor, [
          _buildModeSombreTile(themeProvider, isDark, primaryColor, context),
        ]),

        const SizedBox(height: 32),

        _buildSectionHeader('AIDE & SUPPORT', isDark, primaryColor),
        _buildSettingsCard(isDark, primaryColor, [
          _buildListTile(
            Icons.headset_mic_outlined,
            'Contacter l\'administration',
            'Besoin d\'aide ? Nous sommes là',
            isDark,
            context,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactSupportPage()),
              );
            },
          ),
          _buildListTile(
            Icons.info_outline_rounded,
            'À propos de l\'application',
            'Version 2.0.0 • Politique de confidentialité',
            isDark,
            context,
            showBorder: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutPage()),
              );
            },
          ),
        ]),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, Color primaryColor) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12, start: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: isDark ? Colors.white54 : const Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    bool isDark,
    Color primaryColor,
    List<Widget> children,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A322A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: primaryColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildModeSombreTile(
    ThemeProvider themeProvider,
    bool isDark,
    Color primaryColor,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.dark_mode_outlined,
              color: primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode sombre',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Changer l\'apparence de l\'application',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          // Toggle Buttons
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E241E) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (isDark) themeProvider.toggleTheme();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: !isDark ? primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Clair',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: !isDark
                            ? Colors.white
                            : (isDark
                                  ? Colors.white54
                                  : const Color(0xFF1F2937)),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (!isDark) themeProvider.toggleTheme();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Sombre',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
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

  Widget _buildListTile(
    IconData icon,
    String title,
    String subtitle,
    bool isDark,
    BuildContext context, {
    VoidCallback? onTap,
    bool showBorder = true,
  }) {
    final primaryColor = const Color(0xFF10B981);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: showBorder
                ? Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFFF3F4F6),
                      width: 1,
                    ),
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? Colors.white24 : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
    BuildContext context, {
    bool showBorder = true,
  }) {
    final primaryColor = const Color(0xFF10B981);

    return Container(
      decoration: BoxDecoration(
        border: showBorder
            ? Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFF3F4F6),
                  width: 1,
                ),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          PremiumSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
