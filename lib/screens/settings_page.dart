import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/premium_switch.dart';
import 'contact_support_page.dart';
import 'about_page.dart';
import '../widgets/screen_header.dart';
import '../widgets/custom_sidebar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1E241E)
          : const Color(0xFFF6F7F2),
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
        _buildSectionHeader(
          'Notifications',
          isDark,
          primaryColor,
        ),
        _buildSettingsCard([
          _buildSwitchTile(
            Icons.notifications_active_outlined,
            'Activer les notifications',
            settingsProvider.notificationsEnabled,
            (val) => settingsProvider.toggleNotifications(val),
            isDark,
            context,
          ),
          _buildSwitchTile(
            Icons.event_outlined,
            'Rappels d\'événements',
            settingsProvider.eventRemindersEnabled,
            (val) => settingsProvider.toggleEventReminders(val),
            isDark,
            context,
          ),
          _buildSwitchTile(
            Icons.account_balance_wallet_outlined,
            'Rappels de paiement',
            settingsProvider.paymentRemindersEnabled,
            (val) => settingsProvider.togglePaymentReminders(val),
            isDark,
            context,
            showBorder: false,
          ),
        ], isDark),

        const SizedBox(height: 32),

        _buildSectionHeader('Aide & Support', isDark, primaryColor),
        _buildSettingsCard([
          _buildListTile(
            Icons.headset_mic_outlined,
            'Contacter l\'administration',
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
        ], isDark),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, Color primaryColor) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 14, start: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDark ? Colors.white54 : const Color(0xFF64748B),
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A322A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.05))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title,
    bool isDark,
    BuildContext context, {
    VoidCallback? onTap,
    bool showBorder = true,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Colors.redAccent
        : (isDark ? Colors.white : const Color(0xFF2A322A));

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
                          : const Color(0xFFE2E5E0),
                      width: 1,
                    ),
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.redAccent.withOpacity(0.1)
                      : Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isDestructive
                      ? Colors.redAccent
                      : Theme.of(context).primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDestructive
                    ? Colors.redAccent.withOpacity(0.3)
                    : (isDark ? Colors.white24 : Colors.black26),
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
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
    BuildContext context, {
    bool showBorder = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: showBorder
            ? Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFE2E5E0),
                  width: 1,
                ),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF2A322A),
              ),
            ),
          ),
          PremiumSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
