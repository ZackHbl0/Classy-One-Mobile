import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../services/auth_service.dart';
import 'evenements_page.dart';
import 'notifications_page.dart';
import 'paiement_page.dart';
import 'planning_page.dart';

import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/global_app_header.dart';
import '../models/course.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _nom = '';
  String _prenom = '';
  String _matricule = '';
  String _filiere = '';
  String _niveau = '';
  String _classe = '';
  int _idStudent = 0;
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentCarouselIndex = 0;

  Map<String, dynamic> _stats = {'dernier_paiement': 'Aucun paiement'};
  List<dynamic> _urgentNotifications = [];
  List<dynamic> _recentActivityFeed = [];
  List<Course> _todaySessions = [];
  Map<String, dynamic>? _nextEvent;
  Map<String, dynamic>? _latestNotification;
  int _currentSessionPageIndex = 0;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _idStudent = prefs.getInt('idStudent') ?? 0;
      _matricule = prefs.getString('matricule') ?? '';
      _nom = prefs.getString('nom') ?? '';
      _prenom = prefs.getString('prenom') ?? '';
    });

    if (_idStudent != 0) {
      await _fetchDashboardData();
      if (mounted) {
        context.read<PaymentProvider>().fetchPaymentData(_idStudent);
        context.read<NotificationProvider>().fetchNotifications(_idStudent);
      }
    } else {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = _todaySessions.isEmpty);

    final result = await _authService.getDashboardData(_idStudent);

    if (mounted) {
      // 1. Handle Session Expiration outside setState
      if (result['success'] == false &&
          result['message'] == 'Session expired') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      // 2. Update UI state
      setState(() {
        _isLoading = false;

        if (result['success'] == true) {
          final data = result['data'];

          if (data['student'] != null) {
            _nom = data['student']['nom'] ?? _nom;
            _prenom = data['student']['prenom'] ?? _prenom;
            _matricule = data['student']['matricule'] ?? _matricule;
            _classe = data['student']['classe'] ?? '';
            _filiere = data['student']['filiere'] ?? '';
            _niveau = data['student']['niveau'] ?? '';
            String telephone = data['student']['telephone'] ?? '';

            SharedPreferences.getInstance().then((prefs) {
              prefs.setString('nom', _nom);
              prefs.setString('prenom', _prenom);
              prefs.setString('matricule', _matricule);
              if (_classe.isNotEmpty) prefs.setString('classe', _classe);
              if (_filiere.isNotEmpty) prefs.setString('filiere', _filiere);
              if (_niveau.isNotEmpty) prefs.setString('niveau', _niveau);
              if (telephone.isNotEmpty) prefs.setString('telephone', telephone);
            });
          }
          if (data['stats'] != null) {
            _stats = data['stats'];
          }

          if (data['urgentNotifications'] != null) {
            _urgentNotifications = data['urgentNotifications'];
            if (_urgentNotifications.isNotEmpty) {
              _latestNotification = _urgentNotifications.first;
            }
          }

          if (data['nextEvent'] != null) {
            _nextEvent = data['nextEvent'];
          }

          if (data['recentActivityFeed'] != null) {
            _recentActivityFeed = data['recentActivityFeed'];
          }

          if (data['planning'] != null) {
            final List<dynamic> sessionList = data['planning'];
            _todaySessions = sessionList
                .map((s) => Course.fromJson(s))
                .toList();
          } else if (data['today_sessions'] != null) {
            final List<dynamic> sessionList = data['today_sessions'];
            _todaySessions = sessionList
                .map((s) => Course.fromJson(s))
                .toList();
          } else {
            _todaySessions = [];
          }
          _errorMessage = '';
        } else {
          _errorMessage =
              result['message'] ?? 'Erreur de chargement des données';
        }
      });
    }
  }

  // --- UI Builders ---

  Widget _buildCarouselCard({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            boxShadow: [
              BoxShadow(
                color: colors[1].withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Stack(
              children: [
                PositionedDirectional(
                  end: -15,
                  bottom: -15,
                  child: Icon(
                    icon,
                    size: 130,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          title.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Row(
                        children: [
                          Text(
                            'Voir détails',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroPanel() {
    if (_todaySessions.isEmpty) {
      return Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).cardColor,
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF1F5F9),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_outlined, color: Colors.grey[400], size: 40),
            const SizedBox(height: 12),
            Text(
              'Aucun cours pour le moment',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: _todaySessions.length,
          options: CarouselOptions(
            height: 175,
            viewportFraction: 0.9,
            enlargeCenterPage: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            onPageChanged: (index, reason) {
              setState(() => _currentSessionPageIndex = index);
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final course = _todaySessions[index];
            final isCurrent = course.isCurrent;

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlanningPage()),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isCurrent
                        ? [const Color(0xFF8B5CF6), const Color(0xFF6366F1)]
                        : [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isCurrent
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFF3B82F6))
                              .withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              course.label.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course.matiere,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  course.time,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  course.salle,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.person_outline,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  course.prof,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (_todaySessions.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _todaySessions.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _currentSessionPageIndex == index ? 16.0 : 6.0,
                height: 6.0,
                margin: const EdgeInsets.symmetric(horizontal: 3.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: const Color(
                    0xFF6366F1,
                  ).withOpacity(_currentSessionPageIndex == index ? 0.9 : 0.2),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading && _todaySessions.isEmpty) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: theme.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        color: theme.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildStatsCarousel(),
                    const SizedBox(height: 12),
                    _buildStatsDots(),
                    const SizedBox(height: 28),
                    _buildSectionHeader(
                      'COURS DU JOUR',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlanningPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHeroPanel(),
                    const SizedBox(height: 28),
                    _buildSectionHeader(
                      'NOTIFICATIONS URGENTES',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildUrgentNotification(),
                    const SizedBox(height: 28),
                    _buildSectionHeader('ACTIVITÉ RÉCENTE', null),
                    const SizedBox(height: 16),
                    _buildActivityFeed(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Compose subtitle from available info
    final parts = [
      if (_classe.isNotEmpty) _classe,
      if (_filiere.isNotEmpty) _filiere,
    ];
    final subtitle = parts.join(' • ');

    return GlobalAppHeader(
      greeting: 'Bonjour,',
      userName: '$_prenom $_nom'.trim(),
      subtitle: subtitle.isNotEmpty ? subtitle : null,
      avatarUrl: null, // swap for a real URL when backend provides one
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
    );
  }

  Widget _buildStatsCarousel() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 180,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5),
        enlargeCenterPage: true,
        viewportFraction: 1.0,
        onPageChanged: (index, reason) {
          setState(() => _currentCarouselIndex = index);
        },
      ),
      items: [
        _buildCarouselCard(
          title: 'AGENDA',
          subtitle: _nextEvent != null
              ? (_nextEvent!['titre'] ?? 'Événement')
              : 'Aucun événement',
          value: _nextEvent != null
              ? (_nextEvent!['date_evenement'] ?? '')
              : 'Rien de prévu',
          icon: Icons.calendar_today_outlined,
          colors: [const Color(0xFFFBBF24), const Color(0xFFF59E0B)],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EvenementsPage()),
          ),
        ),
        _buildCarouselCard(
          title: 'NOTIFICATIONS',
          subtitle: _latestNotification != null
              ? (_latestNotification!['titre'] ?? '')
              : 'Pas de message',
          value: _latestNotification != null
              ? (_latestNotification!['message'] ?? '')
              : 'Vérifiez plus tard',
          icon: Icons.notifications_active_outlined,
          colors: [const Color(0xFF60A5FA), const Color(0xFF3B82F6)],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationsPage()),
          ),
        ),

        _buildCarouselCard(
          title: 'FINANCES',
          subtitle: 'Dernier statut: ${_stats['dernier_paiement']}',
          value: 'Suivez vos règlements',
          icon: Icons.account_balance_wallet_outlined,
          colors: [const Color(0xFFF87171), const Color(0xFFEF4444)],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PaiementPage(showBackButton: true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => Container(
          width: _currentCarouselIndex == index ? 20.0 : 6.0,
          height: 6.0,
          margin: const EdgeInsets.symmetric(horizontal: 3.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: const Color(
              0xFF64748B,
            ).withOpacity(_currentCarouselIndex == index ? 0.3 : 0.1),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).textTheme.titleLarge?.color,
            letterSpacing: 0.5,
          ),
        ),
        if (onTap != null)
          TextButton(
            onPressed: onTap,
            child: const Text(
              'Voir tout',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUrgentNotification() {
    if (_urgentNotifications.isEmpty) return const SizedBox.shrink();
    final notif = _urgentNotifications.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFEF4444).withOpacity(0.1)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFEF4444).withOpacity(0.3)
              : const Color(0xFFFEE2E2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif['titre'] ?? 'Notification Importante',
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  notif['message'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed() {
    if (_recentActivityFeed.isEmpty) return const SizedBox.shrink();

    return Column(
      children: _recentActivityFeed.map((item) {
        IconData icon;
        Color color;

        switch (item['type']) {
          case 'document':
            icon = Icons.description_outlined;
            color = const Color(0xFF6366F1);
            break;
          case 'payment':
            icon = Icons.account_balance_wallet_outlined;
            color = const Color(0xFF10B981);
            break;

          case 'event':
            icon = Icons.event_outlined;
            color = const Color(0xFF3B82F6);
            break;
          default:
            icon = Icons.info_outline;
            color = const Color(0xFF64748B);
        }

        return _buildActivityItem(
          icon: icon,
          color: color,
          title: item['title'] ?? '',
          subtitle: item['subtitle'] ?? '',
          time: item['date_formattee'] ?? '',
        );
      }).toList(),
    );
  }
}
