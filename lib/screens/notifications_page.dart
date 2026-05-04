import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/screen_header.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _selectedFilter = 'Toutes';

  final List<String> _filters = [
    'Toutes',
    'Non lues',
    'Planning',
    'Examen',
    'Événement',
    'Paiement',
    'Urgent',
  ];

  @override
  void initState() {
    super.initState();
    // Notifications are already fetched by the Dashboard, but we can refresh them
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final idStudent = prefs.getInt('idStudent') ?? 0;
      if (idStudent != 0 && mounted) {
        context.read<NotificationProvider>().fetchNotifications(idStudent);
      }
    });
  }

  Future<void> _markAllAsRead(NotificationProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    final idStudent = prefs.getInt('idStudent') ?? 0;

    if (idStudent != 0) {
      final success = await provider.markAllAsRead(idStudent);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du marquage'),
          ),
        );
      }
    }
  }

  List<dynamic> _getFilteredNotifications(NotificationProvider provider) {
    if (_selectedFilter == 'Toutes') {
      return provider.notifications;
    } else if (_selectedFilter == 'Non lues') {
      return provider.notifications.where((n) => n['isRead'] != true).toList();
    } else {
      return provider.notifications
          .where((n) => n['categorie'] == _selectedFilter)
          .toList();
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Planning':
        return Icons.calendar_today_outlined;
      case 'Examen':
        return Icons.book_outlined;
      case 'Événement':
        return Icons.celebration_outlined;
      case 'Paiement':
        return Icons.attach_money_rounded;
      case 'Urgent':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Planning':
        return const Color(0xFF3B82F6);
      case 'Examen':
        return const Color(0xFFF59E0B);
      case 'Événement':
        return const Color(0xFF10B981);
      case 'Paiement':
        return const Color(0xFFFBBF24);
      case 'Urgent':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF203B68);
    const slateGrey = Color(0xFF64748B);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final filteredList = _getFilteredNotifications(provider);
        final unreadCount = provider.unreadCount;

        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF0F172A)
              : const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Custom Header Area
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      padding: EdgeInsets.zero,
                      alignment: AlignmentDirectional.centerStart,
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: ScreenHeader(
                          title: 'Notifications',
                          showIcons: false,
                        ),
                      ),
                      TextButton(
                        onPressed: unreadCount > 0 ? () => _markAllAsRead(provider) : null,
                        child: Text(
                          'Tout marquer lu',
                          style: TextStyle(
                            color: unreadCount > 0
                                ? primaryBlue
                                : slateGrey.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$unreadCount non lue(s)',
                    style: const TextStyle(
                      color: slateGrey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filters Area
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                            selectedColor: primaryBlue,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : slateGrey,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                            backgroundColor: isDark
                                ? Colors.white10
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : slateGrey.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Notifications List Area
            Expanded(
              child: provider.isLoading
                  ? _buildShimmerEffect()
                  : provider.errorMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        provider.errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : filteredList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationCard(
                          filteredList[index],
                          index,
                          provider,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.done_all_rounded,
              size: 64,
              color: const Color(0xFF203B68).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Vous êtes à jour !',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aucune notification.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(dynamic notif, int index, NotificationProvider provider) {
    final rawIsRead = notif['isRead'];
    final bool isRead = rawIsRead == true || rawIsRead == 1;
    final String category = notif['categorie'] ?? 'Info';
    final bool isUrgent = category == 'Urgent';
    final Color categoryColor = _getCategoryColor(category);
    final String dateStr = notif['dateStr'] ?? '2h ago';
    final String title = notif['titre'] ?? '';
    final String message = notif['message'] ?? '';
    final String sender = notif['sender'] ?? 'Administration';
    const primaryBlue = Color(0xFF203B68);
    const slateGrey = Color(0xFF64748B);

    return Dismissible(
      key: Key(notif['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsetsDirectional.only(end: 30),
        alignment: AlignmentDirectional.centerEnd,
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 28),
            const SizedBox(height: 4),
            const Text(
              'Supprimer',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (direction) {
        provider.removeNotification(notif['id']);
      },
      child: InkWell(
        onTap: () {
          _showNotificationDetails(context, notif, provider);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead
                  ? const Color(0xFFF1F5F9)
                  : const Color(0xFFBFDBFE),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Icon Area
              Container(
                width: 65,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.08),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: categoryColor,
                      size: 24,
                    ),
                  ),
                ),
              ),

              // Content Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (isUrgent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Urgent',
                                style: TextStyle(
                                  color: Color(0xFF991B1B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            Text(
                              category,
                              style: TextStyle(
                                color: categoryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: slateGrey,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Par $sender',
                            style: TextStyle(
                              color: slateGrey.withOpacity(0.6),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: primaryBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _showNotificationDetails(BuildContext context, dynamic notif, NotificationProvider provider) async {
    final rawIsRead = notif['isRead'];
    final bool isRead = rawIsRead == true || rawIsRead == 1;
    final String category = notif['categorie'] ?? 'Info';
    final Color categoryColor = _getCategoryColor(category);
    final String dateStr = notif['dateStr'] ?? '';
    final String title = notif['titre'] ?? '';
    final String message = notif['message'] ?? '';
    final String sender = notif['sender'] ?? 'Administration';
    const primaryBlue = Color(0xFF203B68);
    const slateGrey = Color(0xFF64748B);

    // Mark as read if it's unread
    if (!isRead) {
      final prefs = await SharedPreferences.getInstance();
      final idStudent = prefs.getInt('idStudent') ?? 0;
      if (idStudent != 0) {
        provider.markAsRead(idStudent, notif['id']);
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Header info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getCategoryIcon(category), color: categoryColor, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            category,
                            style: TextStyle(
                              color: categoryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: slateGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),

                // Sender
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: slateGrey),
                    const SizedBox(width: 6),
                    Text(
                      'Envoyé par : $sender',
                      style: const TextStyle(
                        color: slateGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Message Body
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Fermer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
}
