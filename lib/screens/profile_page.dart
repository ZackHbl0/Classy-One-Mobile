import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/theme_provider.dart';
import 'login_page.dart';
import 'settings_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _nom = '';
  String _prenom = '';
  String _matricule = '';
  String _classe = '';
  String _telephone = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _nom = prefs.getString('nom') ?? '';
        _prenom = prefs.getString('prenom') ?? '';
        _matricule = prefs.getString('matricule') ?? '';
        _classe = prefs.getString('classe') ?? '';
        _telephone = prefs.getString('telephone') ?? 'Non défini';
        _isLoading = false;
      });
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
                'profile.choose_language'.tr(),
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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final primaryDarkBlue = const Color(0xFF1A365D);
    final slateGrey = const Color(0xFF64748B);

    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryDarkBlue)),
      );
    }

    // Determine initials
    String initials = '';
    if (_prenom.isNotEmpty) initials += _prenom[0].toUpperCase();
    if (_nom.isNotEmpty) initials += _nom[0].toUpperCase();
    if (initials.isEmpty) initials = 'MA';

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // Top Background Gradient
          Container(
            height: 350,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [
                        const Color(0xFFCBD5E1).withOpacity(0.3),
                        const Color(0xFFF1F5F9),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // App Bar like row (Back Button)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: isDark ? Colors.white : primaryDarkBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'profile.title'.tr(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : primaryDarkBlue,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Profile Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Large Avatar
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: primaryDarkBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: primaryDarkBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${_prenom} ${_nom}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : primaryDarkBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_prenom.toLowerCase()}.${_nom.toLowerCase()}@school.ma',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : slateGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _classe.isNotEmpty ? _classe : 'Aucune classe',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.circle,
                              size: 4,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _matricule.isNotEmpty ? _matricule : 'Matricule inconnu',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.phone_rounded,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _telephone,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Dark Blue Edit Profile Button
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfilePage(),
                              ),
                            ).then((_) => _loadUserData());
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text('profile.edit'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryDarkBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Individual Settings Rows
                  _buildProfileTile(
                    icon: Icons.language_outlined,
                    title: 'profile.language'.tr(),
                    isDark: isDark,
                    onTap: () => _showLanguagePicker(context),
                  ),
                  _buildProfileTile(
                    icon: Icons.brightness_medium_outlined,
                    title: 'profile.display_mode'.tr(),
                    isDark: isDark,
                    onTap: () {}, // Handled by Switch
                    trailing: Switch(
                      value: isDark,
                      activeColor: primaryDarkBlue,
                      activeTrackColor: primaryDarkBlue.withOpacity(0.3),
                      onChanged: (val) {
                        Provider.of<ThemeProvider>(
                          context,
                          listen: false,
                        ).toggleTheme(val);
                      },
                    ),
                  ),
                  _buildProfileTile(
                    icon: Icons.settings_outlined,
                    title: 'profile.settings_preferences'.tr(),
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      ).then((_) => _loadUserData());
                    },
                  ),
                  _buildProfileTile(
                    icon: Icons.logout_rounded,
                    title: 'profile.logout'.tr(),
                    isDark: isDark,
                    isDestructive: true,
                    onTap: _logout,
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    const primaryDarkBlue = Color(0xFF1A365D);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(
          icon,
          color: isDestructive
              ? Colors.redAccent
              : (isDark ? Colors.white70 : primaryDarkBlue),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDestructive
                ? Colors.redAccent
                : (isDark ? Colors.white : primaryDarkBlue.withOpacity(0.9)),
          ),
        ),
        trailing:
            trailing ??
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDestructive
                  ? Colors.redAccent.withOpacity(0.5)
                  : (isDark ? Colors.white24 : Colors.black26),
            ),
      ),
    );
  }
}
