import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/notification_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────
const _primaryPurple = Color(0xFF6C63FF);
const _bgLight       = Color(0xFFF8F9FA);
const _textDark      = Color(0xFF1E241E);
const _textLight     = Color(0xFF94A3B8);
const _border        = Color(0xFFE2E8F0);

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _selectedFilter = 'Toutes';

  static const List<Map<String, dynamic>> _filters = [
    {'label': 'Toutes',     'icon': Icons.grid_view_rounded,           'color': _primaryPurple},
    {'label': 'Non lues',   'icon': Icons.notifications_none_rounded,  'color': Color(0xFF8B5CF6)},
    {'label': 'Paiement',   'icon': Icons.account_balance_wallet_outlined, 'color': Color(0xFFF97316)},
    {'label': 'Événements', 'icon': Icons.celebration_outlined,        'color': Color(0xFF10B981)},
    {'label': 'Examens',    'icon': Icons.school_outlined,             'color': Color(0xFF8B5CF6)},
    {'label': 'Planning',   'icon': Icons.calendar_today_outlined,     'color': Color(0xFF3B82F6)},
  ];

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs     = await SharedPreferences.getInstance();
      final idStudent = prefs.getInt('idStudent') ?? 0;
      if (idStudent != 0 && mounted) {
        context.read<NotificationProvider>().fetchNotifications(idStudent);
      }
    });
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String _formatTime(dynamic createdAt) {
    if (createdAt == null) return 'À l\'instant';
    try {
      final dt = createdAt is String ? DateTime.parse(createdAt) : createdAt as DateTime;
      final now = DateTime.now();
      final difference = now.difference(dt);
      
      if (difference.inDays == 0 && now.day == dt.day) {
        if (difference.inMinutes < 60) {
          return 'Il y a ${difference.inMinutes} min';
        } else {
          return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? "s" : ""}';
        }
      } else if (difference.inDays == 1 || (difference.inDays == 0 && now.day != dt.day)) {
        return 'Hier à ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else {
        return '${dt.day} ${_month(dt.month)}';
      }
    } catch (_) {
      return 'À l\'instant';
    }
  }

  String _month(int m) {
    const months = ['Janv', 'Févr', 'Mars', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sept', 'Oct', 'Nov', 'Déc'];
    return m > 0 && m <= 12 ? months[m - 1] : '';
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
            backgroundColor: const Color(0xFFEF4444),
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
        // Match API categories to filter labels
        String apiCat = _selectedFilter;
        if (apiCat == 'Événements') apiCat = 'Événement';
        if (apiCat == 'Examens') apiCat = 'Examen';
        return provider.notifications.where((n) => n['categorie'] == apiCat).toList();
    }
  }

  Map<String, List<dynamic>> _groupNotifications(List<dynamic> notifs) {
    final Map<String, List<dynamic>> grouped = {
      "Aujourd'hui": [],
      "Hier": [],
      "Cette semaine": [],
      "Ce mois-ci": [],
      "Plus ancien": [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    for (var n in notifs) {
      final createdAt = n['createdAt'];
      if (createdAt == null) {
        grouped["Aujourd'hui"]!.add(n);
        continue;
      }
      DateTime dt;
      if (createdAt is String) {
        dt = DateTime.tryParse(createdAt) ?? now;
      } else {
        dt = createdAt as DateTime;
      }
      final date = DateTime(dt.year, dt.month, dt.day);

      if (date == today) {
        grouped["Aujourd'hui"]!.add(n);
      } else if (date == yesterday) {
        grouped["Hier"]!.add(n);
      } else if (date.isAfter(startOfWeek) || date == startOfWeek) {
        grouped["Cette semaine"]!.add(n);
      } else if (date.isAfter(startOfMonth) || date == startOfMonth) {
        grouped["Ce mois-ci"]!.add(n);
      } else {
        grouped["Plus ancien"]!.add(n);
      }
    }

    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }

  IconData _iconFor(String cat) {
    const map = {
      'Planning':  Icons.calendar_today_outlined,
      'Examen':    Icons.school_outlined,
      'Événement': Icons.celebration_outlined,
      'Paiement':  Icons.account_balance_wallet_outlined,
      'Urgent':    Icons.bolt_rounded,
      'Général':   Icons.notifications_outlined,
    };
    return map[cat] ?? Icons.notifications_outlined;
  }

  Color _colorFor(String cat) {
    const map = {
      'Planning':  Color(0xFF3B82F6),
      'Examen':    Color(0xFF8B5CF6),
      'Événement': Color(0xFF10B981),
      'Paiement':  Color(0xFFF97316),
      'Urgent':    Color(0xFFDC2626),
      'Général':   Color(0xFF3B82F6),
    };
    return map[cat] ?? Color(0xFF3B82F6);
  }

  // ── Detail bottom-sheet (kept same logic, updated style) ───────────────────
  void _showDetail(BuildContext ctx, dynamic notif, NotificationProvider provider) async {
    final bool isRead = notif['isRead'] == true || notif['isRead'] == 1;
    final cat         = notif['categorie'] ?? 'Général';
    final catColor    = _colorFor(cat);
    final scaffoldCtx = ctx;

    if (!isRead) {
      final prefs     = await SharedPreferences.getInstance();
      final idStudent = prefs.getInt('idStudent') ?? 0;
      if (idStudent != 0) provider.markAsRead(idStudent, notif['id']);
    }
    if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final list        = _filtered(provider);
        final unreadCount = provider.unreadCount;
        final grouped     = _groupNotifications(list);

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF1E241E) : _bgLight,
          body: SafeArea(
            child: Column(
              children: [
                // 1. Header
                _buildHeader(context, unreadCount, isDark),
                
                // 2. Banner & Filters (Scrollable)
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : provider.errorMessage.isNotEmpty
                          ? Center(child: Text(provider.errorMessage, style: const TextStyle(color: Colors.red)))
                          : CustomScrollView(
                              physics: const BouncingScrollPhysics(),
                              slivers: [
                                SliverToBoxAdapter(
                                  child: Column(
                                    children: [
                                      _buildBanner(unreadCount),
                                      _buildFilterRow(isDark, unreadCount),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                                if (grouped.isEmpty)
                                  SliverFillRemaining(
                                    child: Center(
                                      child: Text(
                                        "Aucune notification",
                                        style: GoogleFonts.inter(color: _textLight, fontSize: 16),
                                      ),
                                    ),
                                  )
                                else
                                  ...grouped.entries.map((entry) {
                                    final groupName = entry.key;
                                    final items = entry.value;
                                    return SliverToBoxAdapter(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                                            child: Text(
                                              groupName,
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white : _textDark,
                                              ),
                                            ),
                                          ),
                                          ...items.map((n) => _buildNotifTile(n, isDark, provider)),
                                        ],
                                      ),
                                    );
                                  }),
                                const SliverToBoxAdapter(child: SizedBox(height: 100)),
                              ],
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? Colors.white : _textDark),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : _textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '$unreadCount',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _primaryPurple,
                        ),
                      ),
                      Text(
                        ' nouvelles notifications',
                        style: GoogleFonts.inter(
                          fontSize: 13,
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                if (!isDark)
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications_none_rounded, size: 24, color: isDark ? Colors.white : _textDark),
                if (unreadCount > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: _primaryPurple,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
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

  Widget _buildBanner(int unreadCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEBE5FF), Color(0xFFF3EFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restez à jour !',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E241E),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), height: 1.4),
                    children: [
                      const TextSpan(text: 'Vous avez '),
                      TextSpan(text: '$unreadCount notifications', style: const TextStyle(fontWeight: FontWeight.w700, color: _primaryPurple)),
                      const TextSpan(text: ' à consulter.'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<NotificationProvider>().markAllAsRead(
                      SharedPreferences.getInstance().then((p) => p.getInt('idStudent') ?? 0) as int
                    ); 
                    _markAllAsRead(context.read<NotificationProvider>());
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                  label: Text('Tout lire', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPurple,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          // Placeholder for the 3D Bell
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_rounded, size: 50, color: _primaryPurple),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(bool isDark, int unreadCount) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive 
                    ? _primaryPurple.withOpacity(0.1) 
                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? _primaryPurple.withOpacity(0.3) : (isDark ? Colors.white10 : _border),
                  width: 1,
                ),
                boxShadow: [
                  if (!isDark && !isActive)
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: isActive ? _primaryPurple : color),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      color: isActive ? _primaryPurple : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    ),
                  ),
                  if (label == 'Toutes' || label == 'Non lues') ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? _primaryPurple : (isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        label == 'Toutes' ? '${context.read<NotificationProvider>().notifications.length}' : '$unreadCount',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : (isDark ? Colors.white : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotifTile(dynamic notif, bool isDark, NotificationProvider provider) {
    final bool isRead = notif['isRead'] == true || notif['isRead'] == 1;
    final String cat  = notif['categorie'] ?? 'Général';
    final Color color = _colorFor(cat);
    final String title = notif['titre'] ?? '';
    final String msg  = notif['message'] ?? '';
    final String time = _formatTime(notif['createdAt']);

    return GestureDetector(
      onTap: () => _showDetail(context, notif, provider),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A322A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : _border.withOpacity(0.5)),
          boxShadow: [
            if (!isDark)
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left unread dot (matches category color)
            if (!isRead)
              Padding(
                padding: const EdgeInsets.only(top: 18, right: 12),
                child: Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              )
            else
              const SizedBox(width: 18),

            // Icon
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Icon(_iconFor(cat), color: color, size: 24),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cat,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            time,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white54 : _textLight,
                            ),
                          ),
                          if (!isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(color: _primaryPurple, shape: BoxShape.circle),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                      color: isDark ? Colors.white : _textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.white54 : _textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DetailSheet 
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
        color: isDark ? const Color(0xFF1E241E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: catColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(catIcon, color: catColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      catLabel,
                      style: GoogleFonts.inter(color: catColor, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(timeStr, style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white54 : _textLight, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 20),
          Text(title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : _textDark, height: 1.3)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 16, color: _textLight),
              const SizedBox(width: 6),
              Text('Envoyé par $sender', style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white54 : _textLight, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : _bgLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : _border),
            ),
            child: Text(
              msg.isNotEmpty ? msg : 'Aucun contenu.',
              style: GoogleFonts.inter(fontSize: 15, color: isDark ? Colors.white70 : const Color(0xFF334155), height: 1.6),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPurple,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Fermer', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
