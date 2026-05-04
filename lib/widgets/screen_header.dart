import 'package:flutter/material.dart';
import '../screens/notifications_page.dart';
import '../screens/profile_page.dart';
import 'notification_bell.dart';

class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showIcons;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showIcons = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF1A365D); // OSBT Navy Blue
    const slateGrey = Color(0xFF64748B);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : primaryBlue,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : slateGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (showIcons)
          Row(
            children: [
              _buildIconButton(
                context,
                NotificationBell(
                  iconColor: isDark ? Colors.white70 : const Color(0xFF1A365D),
                ),
                isDark,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsPage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildIconButton(
                context,
                Icon(
                  Icons.person_outline,
                  color: isDark ? Colors.white70 : const Color(0xFF1A365D),
                ),
                isDark,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    Widget iconWidget,
    bool isDark,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: iconWidget,
        onPressed: onTap,
      ),
    );
  }
}
