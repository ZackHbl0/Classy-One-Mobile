import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../screens/notifications_page.dart';
import '../screens/profile_page.dart';
import '../screens/main_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GlobalAppHeader
//
// Reusable premium header widget.
//
// Usage (dashboard-style, with greeting):
//   GlobalAppHeader(
//     greeting:  'Bonjour,',
//     userName:  'Ahmed Mkhier',
//     subtitle:  'L3 Informatique • IRI',
//     avatarUrl: null, // pass a network URL to show a real photo
//   )
//
// Usage (page-style, with page title only):
//   GlobalAppHeader(
//     pageTitle: 'Documents',
//   )
// ─────────────────────────────────────────────────────────────────────────────
class GlobalAppHeader extends StatelessWidget implements PreferredSizeWidget {
  // ── Greeting mode ──────────────────────────────────────────────────────────
  final String? greeting;   // e.g. 'Bonjour,'
  final String? userName;   // e.g. 'Ahmed Mkhier'
  final String? subtitle;   // e.g. 'L3 · IRI'
  final String? avatarUrl;  // null → gradient placeholder

  // ── Page-title mode ────────────────────────────────────────────────────────
  final String? pageTitle;  // when set, shows a simple bold title instead

  // ── Visibility flags ───────────────────────────────────────────────────────
  final bool? showNotification;
  final bool? showProfile;
  final bool? showBackButton;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  // ── Layout ─────────────────────────────────────────────────────────────────
  final EdgeInsets padding;

  const GlobalAppHeader({
    super.key,
    // Greeting mode
    this.greeting,
    this.userName,
    this.subtitle,
    this.avatarUrl,
    // Page-title mode
    this.pageTitle,
    // Flags
    this.showNotification = true,
    this.showProfile = true,
    this.showBackButton = false,
    this.onNotificationTap,
    this.onProfileTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  // ───────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Container(
          height: 56.0,
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2922) : Colors.white,
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF1F5F9),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : const Color(0xFF0F172A).withOpacity(0.05),
                blurRadius: 16.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Left: Profile Avatar / Sidebar Trigger ──
              SizedBox(
                width: 42,
                height: 42,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ((showBackButton ?? false) == true)
                      ? _ActionButton(
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 17,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        )
                      : Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
                                Scaffold.of(context).openDrawer();
                              } else {
                                MainScreen.scaffoldKey.currentState?.openDrawer();
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.06)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 2.2,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(height: 3.5),
                                    Container(
                                      width: 12,
                                      height: 2.2,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(height: 3.5),
                                    Container(
                                      width: 16,
                                      height: 2.2,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),

              // ── Center: Brand Identity ──
              Expanded(
                child: (pageTitle != null && pageTitle!.isNotEmpty)
                    ? _PageTitle(title: pageTitle!, isDark: isDark)
                    : Center(
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? Colors.white.withOpacity(0.04)
                                : const Color(0xFF10B981).withOpacity(0.06),
                            border: Border.all(
                              color: const Color(0xFF10B981).withOpacity(0.18),
                              width: 1,
                            ),
                          ),
                          child: Image.asset(
                            'assets/images/classyone_icon.png',
                            height: 34,
                            width: 34,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
              ),

              // ── Right: Action Notification ──
              SizedBox(
                width: 42,
                height: 42,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ((showNotification ?? true) == true)
                      ? Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: onNotificationTap ??
                                  () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const NotificationsPage()),
                                    );
                                  },
                              child: Center(
                                child: _NotifIcon(isDark: isDark),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Avatar
// ─────────────────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String? url;
  final bool isDark;
  final double size;

  const _Avatar({this.url, required this.isDark, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: url != null && url!.isNotEmpty
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _PlaceholderIcon(),
              )
            : _PlaceholderIcon(),
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: 26,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GreetingText  – Two-line greeting hierarchy
// ─────────────────────────────────────────────────────────────────────────────
class _GreetingText extends StatelessWidget {
  final String greeting;
  final String userName;
  final String? subtitle;
  final bool isDark;

  const _GreetingText({
    required this.greeting,
    required this.userName,
    this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          greeting,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF94A3B8),
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          userName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 19,
            color: isDark ? Colors.white : const Color(0xFF2D3A2D),
          ) ?? GoogleFonts.inter(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF2D3A2D),
            letterSpacing: -0.3,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PageTitle – Simple bold page title (for non-dashboard screens)
// ─────────────────────────────────────────────────────────────────────────────
class _PageTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const _PageTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF1E293B),
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ActionButton – Flat, no elevated circle background
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ActionButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NotifIcon – Bell with minimalist red dot (no number)
// ─────────────────────────────────────────────────────────────────────────────
class _NotifIcon extends StatelessWidget {
  final bool isDark;

  const _NotifIcon({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (_, provider, __) {
        final hasUnread = provider.unreadCount > 0;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              size: 21,
            ),
            if (hasUnread)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1F2922) : Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      provider.unreadCount > 99 ? '99+' : provider.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
