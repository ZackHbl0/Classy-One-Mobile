import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../screens/notifications_page.dart';
import '../screens/profile_page.dart';
import '../screens/professors_list_screen.dart';
import '../screens/recent_chats_screen.dart';
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
  Size get preferredSize => const Size.fromHeight(56);

  // ───────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Left: Profile Avatar / Sidebar Trigger ──
              SizedBox(
                width: 44,
                height: 44,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ((showBackButton ?? false) == true)
                      ? _ActionButton(
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        )
                      : GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
                              Scaffold.of(context).openDrawer();
                            } else {
                              MainScreen.scaffoldKey.currentState?.openDrawer();
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            color: Colors.transparent, // to increase tap target
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 16,
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 24,
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
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
                        child: Image.asset(
                          'assets/images/classyone_icon.png',
                          height: 56,
                        ),
                      ),
              ),

              // ── Right: Action Notification ──
              SizedBox(
                width: 44,
                height: 44,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ((showNotification ?? true) == true)
                      ? Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black26
                                    : Theme.of(context).primaryColor.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(50),
                              onTap: onNotificationTap ??
                                  () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const NotificationsPage()),
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
    return Text(
      title,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: isDark ? Colors.white : const Color(0xFF2D3A2D),
      ) ?? GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : const Color(0xFF2D3A2D),
        letterSpacing: -0.4,
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
          children: [
            Icon(
              Icons.notifications_none_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
              size: 22,
            ),
            if (hasUnread)
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5,
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
