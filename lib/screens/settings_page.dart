import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import 'contact_support_page.dart';
import 'about_page.dart';

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

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'settings.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildContent(settingsProvider, themeProvider, context, isDark),
    );
  }

  Widget _buildContent(
    SettingsProvider settingsProvider,
    ThemeProvider themeProvider,
    BuildContext context,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      physics: const BouncingScrollPhysics(),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('settings.preferences'.tr(), isDark),
            _buildSettingsCard([
              _buildListTile(
                Icons.language_rounded,
                'settings.language'.tr(),
                isDark,
                context,
                trailingText: _getLanguageName(context.locale.languageCode),
                onTap: () => _showLanguagePicker(context),
              ),
              _buildSwitchTile(
                Icons.dark_mode_outlined,
                'settings.dark_mode'.tr(),
                themeProvider.isDarkMode,
                (val) => themeProvider.toggleTheme(val),
                isDark,
                context,
                showBorder: false,
              ),
            ], isDark),
          ],
        ),

        const SizedBox(height: 32),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('settings.notifications'.tr(), isDark),
            _buildSettingsCard([
              _buildSwitchTile(
                Icons.notifications_active_outlined,
                'settings.enable_notifications'.tr(),
                settingsProvider.notificationsEnabled,
                (val) => settingsProvider.toggleNotifications(val),
                isDark,
                context,
              ),
              _buildSwitchTile(
                Icons.event_outlined,
                'settings.event_reminders'.tr(),
                settingsProvider.eventRemindersEnabled,
                (val) => settingsProvider.toggleEventReminders(val),
                isDark,
                context,
              ),
              _buildSwitchTile(
                Icons.account_balance_wallet_outlined,
                'settings.payment_reminders'.tr(),
                settingsProvider.paymentRemindersEnabled,
                (val) => settingsProvider.togglePaymentReminders(val),
                isDark,
                context,
                showBorder: false,
              ),
            ], isDark),
          ],
        ),

        const SizedBox(height: 32),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('settings.help_support'.tr(), isDark),
            _buildSettingsCard([
              _buildListTile(
                Icons.headset_mic_outlined,
                'settings.contact_admin'.tr(),
                isDark,
                context,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ContactSupportPage(),
                    ),
                  );
                },
              ),
              _buildListTile(
                Icons.info_outline_rounded,
                'settings.about_app'.tr(),
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
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12, start: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title,
    bool isDark,
    BuildContext context, {
    VoidCallback? onTap,
    bool showBorder = true,
    String? trailingText,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: showBorder
                ? Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      width: 1,
                    ),
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (trailingText != null)
                Text(
                  trailingText,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? Colors.white30 : Colors.black26,
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
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          border: showBorder
              ? Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'fr':
        return 'Français';
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      default:
        return 'Français';
    }
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'settings.choose_language'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildLangItem(context, 'Français', const Locale('fr')),
              _buildLangItem(context, 'العربية', const Locale('ar')),
              _buildLangItem(context, 'English', const Locale('en')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLangItem(BuildContext context, String name, Locale locale) {
    final isSelected = context.locale == locale;
    return ListTile(
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).primaryColor)
          : null,
      onTap: () {
        context.setLocale(locale);
        Navigator.pop(context);
        setState(() {}); // Refresh UI
      },
    );
  }
}
