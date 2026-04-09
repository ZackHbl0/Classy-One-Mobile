import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
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

  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final idStudent = prefs.getInt('idStudent') ?? 0;

    if (idStudent == 0) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Utilisateur non connecté';
        });
      }
      return;
    }

    final result = await _authService.getNotifications(idStudent);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _notifications = result['data'] ?? [];
        } else {
          _errorMessage =
              result['message'] ??
              'Erreur lors du chargement des notifications';
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final idStudent = prefs.getInt('idStudent') ?? 0;

    if (idStudent != 0) {
      final result = await _authService.markNotificationsRead(idStudent);
      if (result['success'] == true) {
        setState(() {
          for (var notif in _notifications) {
            notif['isRead'] = true;
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Erreur lors du marquage'),
            ),
          );
        }
      }
    }
  }

  int get _unreadCount {
    return _notifications.where((n) => n['isRead'] != true).length;
  }

  List<dynamic> get _filteredNotifications {
    if (_selectedFilter == 'Toutes') {
      return _notifications;
    } else if (_selectedFilter == 'Non lues') {
      return _notifications.where((n) => n['isRead'] != true).toList();
    } else {
      return _notifications
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
                        onPressed: _unreadCount > 0 ? _markAllAsRead : null,
                        child: Text(
                          'Tout marquer lu',
                          style: TextStyle(
                            color: _unreadCount > 0
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
                    '$_unreadCount non lue(s)',
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
              child: _isLoading
                  ? _buildShimmerEffect()
                  : _errorMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : _filteredNotifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filteredNotifications.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationCard(
                          _filteredNotifications[index],
                          index,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune notification trouvée.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 16,
              fontWeight: FontWeight.w500,
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

  Widget _buildNotificationCard(dynamic notif, int index) {
    final bool isRead = notif['isRead'] ?? false;
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
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      onDismissed: (direction) {
        setState(() {
          _notifications.removeWhere((n) => n['id'] == notif['id']);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? const Color(0xFFF1F5F9)
                : primaryBlue.withOpacity(0.1),
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
    );
  }
}
