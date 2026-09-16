import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Notification item data model
// ─────────────────────────────────────────────────────────────────────────────
class ParentNotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final String category; // 'Absence', 'Note', 'Document', 'Annonce', 'Paiement'
  final IconData icon;
  final Color color;
  final Color bgColor;
  final int targetTabIndex;
  final bool isUnread;

  ParentNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.category,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.targetTabIndex,
    this.isUnread = true,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen Parent Notifications Page (matching student NotificationsPage)
// ─────────────────────────────────────────────────────────────────────────────
class ParentNotificationsPage extends StatefulWidget {
  final String childName;
  final List<ParentNotificationItem> notifications;
  final Set<String> readNotificationIds;
  final Function(String id) onMarkAsRead;
  final VoidCallback onMarkAllAsRead;
  final Function(int targetTabIndex) onNavigateToTab;

  const ParentNotificationsPage({
    super.key,
    required this.childName,
    required this.notifications,
    required this.readNotificationIds,
    required this.onMarkAsRead,
    required this.onMarkAllAsRead,
    required this.onNavigateToTab,
  });

  @override
  State<ParentNotificationsPage> createState() => _ParentNotificationsPageState();
}

class _ParentNotificationsPageState extends State<ParentNotificationsPage> {
  String _selectedFilter = 'Toutes';

  static const Color _primaryGreen = Color(0xFF134E35);
  static const Color _accentGreen  = Color(0xFF298A5E);
  static const Color _bgLight      = Color(0xFFF8FAF9);
  static const Color _textDark     = Color(0xFF0F172A);
  static const Color _textLight    = Color(0xFF64748B);

  static const List<Map<String, dynamic>> _filters = [
    {'label': 'Toutes',     'icon': Icons.grid_view_rounded,                'color': _primaryGreen},
    {'label': 'Non lues',   'icon': Icons.notifications_active_outlined,    'color': Color(0xFFEF4444)},
    {'label': 'Absences',   'icon': Icons.event_busy_outlined,             'color': Color(0xFFEF4444)},
    {'label': 'Notes',      'icon': Icons.school_outlined,                  'color': Color(0xFF10B981)},
    {'label': 'Documents',  'icon': Icons.description_outlined,             'color': Color(0xFF8B5CF6)},
    {'label': 'Annonces',   'icon': Icons.campaign_outlined,                'color': Color(0xFF3B82F6)},
    {'label': 'Paiements',  'icon': Icons.account_balance_wallet_outlined,  'color': Color(0xFF0D9488)},
  ];

  int get _unreadCount => widget.notifications
      .where((n) => !widget.readNotificationIds.contains(n.id))
      .length;

  List<ParentNotificationItem> get _filteredList {
    switch (_selectedFilter) {
      case 'Non lues':
        return widget.notifications
            .where((n) => !widget.readNotificationIds.contains(n.id))
            .toList();
      case 'Toutes':
        return widget.notifications;
      case 'Absences':
        return widget.notifications.where((n) => n.category == 'Absence').toList();
      case 'Notes':
        return widget.notifications.where((n) => n.category == 'Note').toList();
      case 'Documents':
        return widget.notifications.where((n) => n.category == 'Document').toList();
      case 'Annonces':
        return widget.notifications.where((n) => n.category == 'Annonce').toList();
      case 'Paiements':
        return widget.notifications.where((n) => n.category == 'Paiement').toList();
      default:
        return widget.notifications;
    }
  }

  void _markAllAsRead() {
    HapticFeedback.lightImpact();
    widget.onMarkAllAsRead();
    setState(() {});
  }

  void _showDetail(ParentNotificationItem notif) {
    widget.onMarkAsRead(notif.id);
    setState(() {});

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2620) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: notif.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: notif.color.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(notif.icon, color: notif.color, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        notif.category.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: notif.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  notif.time,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: isDark ? Colors.white54 : _textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              notif.title,
              style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : _textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                ),
              ),
              child: Text(
                notif.message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext); // Close sheet
                  Navigator.pop(context);      // Close notification page
                  widget.onNavigateToTab(notif.targetTabIndex); // Switch to target tab
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  _actionLabelFor(notif.category),
                  style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _actionLabelFor(String category) {
    switch (category) {
      case 'Absence':
        return 'Consulter le relevé d\'absences';
      case 'Note':
        return 'Voir le carnet de notes';
      case 'Document':
        return 'Consulter les documents';
      case 'Paiement':
        return 'Voir les détails de paiement';
      case 'Annonce':
      default:
        return 'Voir dans les annonces';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unread = _unreadCount;
    final list = _filteredList;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141914) : _bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header with back button & unread indicator
            _buildHeader(context, unread, isDark),

            // 2. Banner & Filters + List
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildBanner(unread, isDark),
                        _buildFilterRow(isDark),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                  if (list.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: _primaryGreen.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_off_outlined,
                                size: 46,
                                color: _primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune notification',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : _textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Vous êtes parfaitement à jour pour ${widget.childName} !',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: _textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final notif = list[index];
                            final isUnread = !widget.readNotificationIds.contains(notif.id);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildNotifTile(notif, isUnread, isDark),
                            );
                          },
                          childCount: list.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 30)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header Widget ──────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, int unreadCount, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: isDark ? Colors.white : _textDark,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.inter(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : _textDark,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '$unreadCount',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                      Text(
                        ' non lue${unreadCount > 1 ? "s" : ""}',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white54 : _textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              style: TextButton.styleFrom(
                foregroundColor: _primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              child: Text(
                'Tout lire',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _primaryGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Hero Banner Widget ─────────────────────────────────────────────────────
  Widget _buildBanner(int unreadCount, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF193222), const Color(0xFF1E3D29)]
              : [const Color(0xFFE8F5E9), const Color(0xFFF1F8F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? primaryBorder(isDark) : const Color(0xFFD1E7DD),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restez informé !',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'Espace de '),
                      TextSpan(
                        text: widget.childName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: ' • $unreadCount notification(s) à consulter.'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _markAllAsRead,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.white),
                  label: Text(
                    'Tout marquer lu',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: _primaryGreen.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              size: 42,
              color: _primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Color primaryBorder(bool isDark) => isDark ? Colors.white10 : const Color(0xFFD1E7DD);

  // ── Filter Row Widget ──────────────────────────────────────────────────────
  Widget _buildFilterRow(bool isDark) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = _filters[i];
          final label = f['label'] as String;
          final icon = f['icon'] as IconData;
          final color = f['color'] as Color;
          final isActive = _selectedFilter == label;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedFilter = label);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? _primaryGreen
                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? _primaryGreen
                      : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: _primaryGreen.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: isActive ? Colors.white : color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Notification Tile Widget ───────────────────────────────────────────────
  Widget _buildNotifTile(ParentNotificationItem notif, bool isUnread, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showDetail(notif),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? (isUnread ? const Color(0xFF1E2820) : const Color(0xFF161C17))
                : (isUnread ? Colors.white : const Color(0xFFFBFDFB)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? (isUnread ? _primaryGreen.withOpacity(0.35) : Colors.white10)
                  : (isUnread ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9)),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black26
                    : (isUnread ? const Color(0xFF0F172A).withOpacity(0.04) : Colors.transparent),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? notif.color.withOpacity(0.18) : notif.bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    notif.icon,
                    color: notif.color,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: notif.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            notif.category.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: notif.color,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          notif.time,
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.grey.shade400 : const Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                        color: isDark ? Colors.white : _textDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notif.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: isDark ? Colors.white38 : const Color(0xFFCBD5E1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
