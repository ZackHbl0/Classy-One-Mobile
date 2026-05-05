import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/notification_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — simplified to rely on context theme where possible
// ─────────────────────────────────────────────────────────────────────────────
const _navy      = Color(0xFF1A365D);
const _blue      = Color(0xFF3B82F6);
const _border    = Color(0xFFE2E8F0);

// ─────────────────────────────────────────────────────────────────────────────
// NotificationsPage
// ─────────────────────────────────────────────────────────────────────────────
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {

  String _selectedFilter = 'Toutes';
  late AnimationController _chipCtrl;

  static const List<Map<String, dynamic>> _filters = [
    {'label': 'Toutes',     'icon': Icons.all_inbox_rounded},
    {'label': 'Non lues',   'icon': Icons.mark_email_unread_outlined},
    {'label': 'Planning',   'icon': Icons.calendar_today_outlined},
    {'label': 'Examen',     'icon': Icons.book_outlined},
    {'label': 'Événement',  'icon': Icons.celebration_outlined},
    {'label': 'Paiement',   'icon': Icons.credit_card_outlined},
    {'label': 'Urgent',     'icon': Icons.bolt_rounded},
  ];

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    _chipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs     = await SharedPreferences.getInstance();
      final idStudent = prefs.getInt('idStudent') ?? 0;
      if (idStudent != 0 && mounted) {
        context.read<NotificationProvider>().fetchNotifications(idStudent);
      }
    });
  }

  @override
  void dispose() {
    _chipCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String _formatTime(dynamic createdAt) {
    if (createdAt == null) return 'À l\'instant';
    try {
      final dt = createdAt is String
          ? DateTime.parse(createdAt)
          : createdAt as DateTime;
      return timeago.format(dt.toLocal(), locale: 'fr');
    } catch (_) {
      return 'À l\'instant';
    }
  }

  Future<void> _markAllAsRead(NotificationProvider provider) async {
    HapticFeedback.lightImpact();
    final prefs     = await SharedPreferences.getInstance();
    final idStudent = prefs.getInt('idStudent') ?? 0;
    if (idStudent != 0) {
      final ok = await provider.markAllAsRead(idStudent);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du marquage', style: GoogleFonts.inter()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFEF4444),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  List<dynamic> _filtered(NotificationProvider provider) {
    switch (_selectedFilter) {
      case 'Non lues':
        return provider.notifications.where((n) => n['isRead'] != true && n['isRead'] != 1).toList();
      case 'Toutes':
        return provider.notifications;
      default:
        return provider.notifications.where((n) => n['categorie'] == _selectedFilter).toList();
    }
  }

  IconData _iconFor(String cat) {
    const map = {
      'Planning':  Icons.calendar_today_outlined,
      'Examen':    Icons.book_outlined,
      'Événement': Icons.celebration_outlined,
      'Paiement':  Icons.credit_card_outlined,
      'Urgent':    Icons.bolt_rounded,
    };
    return map[cat] ?? Icons.notifications_none_outlined;
  }

  Color _colorFor(String cat) {
    const map = {
      'Planning':  Color(0xFF3B82F6),
      'Examen':    Color(0xFFF59E0B),
      'Événement': Color(0xFF10B981),
      'Paiement':  Color(0xFFFBBF24),
      'Urgent':    Color(0xFFDC2626),
    };
    return map[cat] ?? const Color(0xFF64748B);
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final list        = _filtered(provider);
        final unreadCount = provider.unreadCount;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────────
                _Header(
                  unreadCount:    unreadCount,
                  canPop:         Navigator.canPop(context),
                  hasUnread:      unreadCount > 0,
                  onBack:         () => Navigator.pop(context),
                  onMarkAllRead:  () => _markAllAsRead(provider),
                  isDark:         isDark,
                ),

                // ── Filter chips ─────────────────────────────────────────────
                _FilterRow(
                  filters:        _filters,
                  selected:       _selectedFilter,
                  isDark:         isDark,
                  onSelect:       (f) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedFilter = f);
                  },
                ),

                const SizedBox(height: 8),

                // ── List ──────────────────────────────────────────────────────
                Expanded(
                  child: provider.isLoading
                      ? _Shimmer()
                      : provider.errorMessage.isNotEmpty
                          ? _ErrorState(msg: provider.errorMessage)
                          : list.isEmpty
                              ? _EmptyState()
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: list.length,
                                  itemBuilder: (_, i) => _NotifTile(
                                    notif:       list[i],
                                    iconFor:     _iconFor,
                                    colorFor:    _colorFor,
                                    formatTime:  _formatTime,
                                    onDismiss:   () => provider.deleteNotification(list[i]['id']),
                                    onTap:       () => _showDetail(context, list[i], provider),
                                  ),
                                ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Detail bottom-sheet ───────────────────────────────────────────────────
  void _showDetail(BuildContext ctx, dynamic notif, NotificationProvider provider) async {
    final bool isRead = notif['isRead'] == true || notif['isRead'] == 1;
    final cat         = notif['categorie'] ?? 'Info';
    final catColor    = _colorFor(cat);
    // Capture before async gap
    final scaffoldCtx = ctx;

    if (!isRead) {
      final prefs     = await SharedPreferences.getInstance();
      final idStudent = prefs.getInt('idStudent') ?? 0;
      if (idStudent != 0) provider.markAsRead(idStudent, notif['id']);
    }
    if (!mounted) return;

    // ignore: use_build_context_synchronously
    showModalBottomSheet(
      context:            scaffoldCtx,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _DetailSheet(
        notif:    notif,
        catColor: catColor,
        catIcon:  _iconFor(cat),
        catLabel: cat,
        timeStr:  _formatTime(notif['createdAt']),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Header
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int    unreadCount;
  final bool   canPop;
  final bool   hasUnread;
  final bool   isDark;
  final VoidCallback onBack;
  final VoidCallback onMarkAllRead;

  const _Header({
    required this.unreadCount,
    required this.canPop,
    required this.hasUnread,
    required this.isDark,
    required this.onBack,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + title + action
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (canPop)
                InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              if (canPop) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Notifications',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              // Mark all read — text button, prominent but clean
              AnimatedOpacity(
                opacity: hasUnread ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: TextButton.icon(
                  onPressed: hasUnread ? onMarkAllRead : null,
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: Text(
                    'Tout lire',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: _blue,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Unread badge line
          if (unreadCount > 0)
            Row(
              children: [
                Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  '$unreadCount non lue${unreadCount > 1 ? "s" : ""}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _blue,
                  ),
                ),
              ],
            )
          else
            Text(
              'Toutes lues ✓',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF10B981),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FilterRow
// ─────────────────────────────────────────────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final List<Map<String, dynamic>> filters;
  final String selected;
  final bool isDark;
  final ValueChanged<String> onSelect;

  const _FilterRow({
    required this.filters,
    required this.selected,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f         = filters[i];
          final label     = f['label'] as String;
          final icon      = f['icon'] as IconData;
          final isActive  = selected == label;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isActive
                  ? _navy
                  : (isDark ? Colors.white10 : const Color(0xFFEFF2F7)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              onTap: () => onSelect(label),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive) ...[
                      Icon(icon, size: 13, color: Colors.white),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? Colors.white
                            : (isDark ? Colors.white60 : const Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NotifTile  – Compact, swipeable notification row
// ─────────────────────────────────────────────────────────────────────────────
class _NotifTile extends StatelessWidget {
  final dynamic notif;
  final IconData Function(String) iconFor;
  final Color    Function(String) colorFor;
  final String   Function(dynamic) formatTime;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _NotifTile({
    required this.notif,
    required this.iconFor,
    required this.colorFor,
    required this.formatTime,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool   isRead = notif['isRead'] == true || notif['isRead'] == 1;
    final String cat    = notif['categorie'] ?? 'Info';
    final Color  color  = colorFor(cat);
    final String title  = notif['titre'] ?? '';
    final String msg    = notif['message'] ?? '';
    final String time   = formatTime(notif['createdAt']);
    final bool isUrgent = cat == 'Urgent';

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dismissible(
      key: Key('notif_${notif["id"]}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onDismiss();
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 22),
            const SizedBox(height: 2),
            Text(
              'Supprimer',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isRead 
              ? theme.cardColor 
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F7FF)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead 
                ? (isDark ? Colors.white.withOpacity(0.05) : _border) 
                : const Color(0xFFBFDBFE),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Circle avatar icon ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                  ),
                  child: Icon(iconFor(cat), color: color, size: 20),
                ),
              ),

              // ── Content ────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category + time
                      Row(
                        children: [
                          // Urgent badge or category label
                          if (isUrgent)
                            _badge('Urgent', const Color(0xFF991B1B), const Color(0xFFFEE2E2))
                          else
                            Text(
                              cat,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                                letterSpacing: 0.3,
                              ),
                            ),
                          const Spacer(),
                          Text(
                            time,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Title
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Body preview
                      Text(
                        msg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Unread dot ─────────────────────────────────────────────
              if (!isRead)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DetailSheet – polished bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _DetailSheet extends StatelessWidget {
  final dynamic notif;
  final Color   catColor;
  final IconData catIcon;
  final String  catLabel;
  final String  timeStr;

  const _DetailSheet({
    required this.notif,
    required this.catColor,
    required this.catIcon,
    required this.catLabel,
    required this.timeStr,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final title  = notif['titre']   ?? '';
    final msg    = notif['message'] ?? '';
    final sender = notif['sender']  ?? 'Administration';

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 12, 24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Category pill + time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(catIcon, color: catColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      catLabel,
                      style: GoogleFonts.inter(
                        color: catColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                timeStr,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Title
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),

          // Sender
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 15, color: Color(0xFF94A3B8)),
              const SizedBox(width: 5),
              Text(
                'Envoyé par $sender',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Message body
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : _border),
            ),
            child: Text(
              msg.isNotEmpty ? msg : 'Aucun contenu.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Close button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Fermer',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// States
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.done_all_rounded, size: 42, color: _blue),
          ),
          const SizedBox(height: 20),
          Text(
            'Vous êtes à jour !',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Aucune notification pour l\'instant.',
            style: GoogleFonts.inter(
              fontSize: 13, 
              color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white38 
                : const Color(0xFF94A3B8)
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String msg;
  const _ErrorState({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        msg,
        style: GoogleFonts.inter(color: const Color(0xFFEF4444)),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: 6,
      itemBuilder: (_, i) => Container(
        height: 78,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
