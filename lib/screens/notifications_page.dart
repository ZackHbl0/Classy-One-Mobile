import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

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
          for (var notif in _notifications) {
            notif['isRead'] = false;
          }
        } else {
          _errorMessage =
              result['message'] ??
              'Erreur lors du chargement des notifications';
        }
      });
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var notif in _notifications) {
        notif['isRead'] = true;
      }
    });
  }

  int get _unreadCount {
    return _notifications.where((n) => !(n['isRead'] as bool)).length;
  }

  List<dynamic> get _filteredNotifications {
    if (_selectedFilter == 'Toutes') {
      return _notifications;
    } else if (_selectedFilter == 'Non lues') {
      return _notifications.where((n) => !(n['isRead'] as bool)).toList();
    } else {
      return _notifications
          .where((n) => n['categorie'] == _selectedFilter)
          .toList();
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
        return const Color(
          0xFFFBBF24,
        ); // Slightly yellow-orange to ensure text readability if needed
      case 'Urgent':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getCategoryTextColor(String category) {
    if (category == 'Paiement') {
      return const Color(0xFF1E293B); // Dark text for yellow bg
    }
    return Colors.white;
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF203B68) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(dynamic notif) {
    final bool isRead = notif['isRead'] ?? false;
    final String category = notif['categorie'] ?? 'Info';
    final bool isHighPriority = category == 'Urgent' || category == 'Examen';
    final Color categoryColor = _getCategoryColor(category);
    final Color categoryTextColor = _getCategoryTextColor(category);
    final String dateStr = notif['dateStr'] ?? '';
    final String title = notif['titre'] ?? '';
    final String message = notif['message'] ?? '';
    final String sender = notif['sender'] ?? 'Système';
    final String target = notif['target'] ?? 'Tous';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead
              ? const Color(0xFFE2E8F0)
              : const Color(
                  0xFFFEF4C6,
                ), // Or FDE047 for a bit stronger yellow border like mockups
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  // Dot indicator
                  if (!isRead)
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4B41A),
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(width: 20), // Placeholder to keep alignment
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: categoryTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // High Priority Badge
                  if (isHighPriority) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Priorité haute',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                dateStr,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.only(
              left: isRead ? 20 : 20,
            ), // align with badges
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Par $sender',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '•',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cible : $target',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF203B68),
        elevation: 0,
        automaticallyImplyLeading: false, // Don't show generic back button
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shield,
                color: Color(0xFF203B68),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'OSBT NOTIFY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Area
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.notifications_none,
                          color: Color(0xFF1E293B),
                          size: 28,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Notifications',
                          style: TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_unreadCount non lue(s)',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _unreadCount > 0 ? _markAllAsRead : null,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Tout marquer lu'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Filters Area
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _filters
                  .map((filter) => _buildFilterChip(filter))
                  .toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Notifications List Area
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF203B68)),
                  )
                : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF203B68),
                          ),
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = '';
                            });
                            _fetchNotifications();
                          },
                          child: const Text(
                            'Réessayer',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredNotifications.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune notification trouvée.',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredNotifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(
                        _filteredNotifications[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
