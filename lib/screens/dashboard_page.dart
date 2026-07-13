import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'evenements_page.dart';
import 'notifications_page.dart';
import 'paiement_page.dart';
import 'planning_page.dart';
import 'grades_screen.dart';

import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/global_app_header.dart';
import '../models/course.dart';
import '../models/grade.dart';
import '../widgets/grade_summary_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
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

  // Grades data
  GradeSummary? _gradeSummary;
  bool _isLoadingGrades = false;
  String? _gradesErrorMessage;

  AnimationController? _fadeController;
  Animation<double>? _fadeAnimation;

  ScrollController? _scrollController;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController!,
      curve: Curves.easeOut,
    );

    _scrollController = ScrollController();
    _loadUserData();
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    _fadeController?.dispose();
    super.dispose();
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
      await _fetchGrades();
      if (mounted) {
        context.read<PaymentProvider>().fetchPaymentData(_idStudent);
        context.read<NotificationProvider>().fetchNotifications(_idStudent);
        _fadeController?.forward();
      }
    } else {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _fetchGrades() async {
    setState(() {
      _isLoadingGrades = true;
      _gradesErrorMessage = null;
    });

    try {
      final result = await _authService.getGrades(_idStudent);

      if (mounted) {
        setState(() {
          _isLoadingGrades = false;
          if (result['success'] == true) {
            if (result['statistics'] != null &&
                result['statistics'] is Map<String, dynamic>) {
              _gradeSummary = GradeSummary.fromJson(
                result['statistics'] as Map<String, dynamic>,
              );
            }
            _gradesErrorMessage = null;
          } else {
            _gradesErrorMessage =
                result['message']?.toString() ?? 'Erreur de chargement';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGrades = false;
          _gradesErrorMessage = 'Erreur: $e';
        });
      }
    }
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = _todaySessions.isEmpty);

    final result = await _authService.getDashboardData(_idStudent);

    if (mounted) {
      if (result['success'] == false &&
          result['message'] == 'Session expired') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }

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
            final String telephone = data['student']['telephone'] ?? '';

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

          if (data['stats'] != null) _stats = data['stats'];

          if (data['urgentNotifications'] != null) {
            _urgentNotifications = data['urgentNotifications'];
            if (_urgentNotifications.isNotEmpty) {
              _latestNotification = _urgentNotifications.first;
            }
          }

          if (data['nextEvent'] != null) _nextEvent = data['nextEvent'];

          if (data['recentActivityFeed'] != null) {
            _recentActivityFeed = data['recentActivityFeed'];
          }

          if (data['planning'] != null) {
            _todaySessions = (data['planning'] as List)
                .map((s) => Course.fromJson(s))
                .toList();
          } else if (data['today_sessions'] != null) {
            _todaySessions = (data['today_sessions'] as List)
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

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121A12) : const Color(0xFFF4F6F4);

    if (_isLoading && _todaySessions.isEmpty && _gradeSummary == null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    // Compose subtitle
    final parts = [
      if (_classe.isNotEmpty) _classe,
      if (_filiere.isNotEmpty) _filiere,
    ];
    final subtitle = parts.join(' • ');

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── HEADER EST MAINTENANT DANS LE SCROLL CONTENT VIA SLIVERS ──

            // ── CONTENU REDESIGNÉ ──
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchDashboardData,
                color: Theme.of(context).primaryColor,
                child: _fadeAnimation != null
                    ? FadeTransition(
                        opacity: _fadeAnimation!,
                        child: _buildScrollContent(subtitle),
                      )
                    : _buildScrollContent(subtitle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SCROLL CONTENT
  // ═══════════════════════════════════════════════════════════════

  Widget _buildScrollContent(String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121A12) : const Color(0xFFF4F6F4);

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      slivers: [
        // ── DYNAMIC HEADER ──
        SliverAppBar(
          floating: true, // Le header disparaît au scroll down, réapparaît au scroll up
          snap: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          toolbarHeight: 112, // 56 (GlobalAppHeader standard height) + 32 (top) + 24 (bottom)
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: const EdgeInsets.only(top: 32.0, left: 20.0, right: 20.0, bottom: 24.0),
              child: GlobalAppHeader(
                greeting: 'Bonjour,',
                userName: '$_prenom $_nom'.trim(),
                subtitle: subtitle.isNotEmpty ? subtitle : null,
                avatarUrl: null,
              ),
            ),
          ),
        ),

        // ── CONTENU REDESIGNÉ ──
        SliverToBoxAdapter(
          child: Container(
            color: bg,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── 1. HERO — Notes ──
              _buildHeroGradeCard(isDark),
              const SizedBox(height: 28),

              // ── 2. COURS DU JOUR ──
              _buildSectionLabel('Cours du jour', isDark, onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PlanningPage()));
              }),
              const SizedBox(height: 14),
              _buildTodayCoursesSection(isDark),
              const SizedBox(height: 28),

              // ── 3. NOTIFICATIONS URGENTES ──
              if (_urgentNotifications.isNotEmpty) ...[
                _buildSectionLabel('Notifications urgentes', isDark,
                    onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsPage()));
                }),
                const SizedBox(height: 14),
                _buildUrgentNotificationsSection(isDark),
                const SizedBox(height: 28),
              ],

              // ── 4. ACTIVITÉ RÉCENTE ──
              if (_recentActivityFeed.isNotEmpty) ...[
                _buildSectionLabel('Activité récente', isDark),
                const SizedBox(height: 14),
                _buildActivityFeedSection(isDark),
                const SizedBox(height: 28),
              ],

              // ── 5. PROGRESSION SEMESTRE ──
              _buildProgressionCard(isDark),
              const SizedBox(height: 28),

              // ── 6. RÉSUMÉ RAPIDE ──
              _buildSummaryGrid(isDark),
            ],
          ),
        ),
      ),
    ),
    ],
  );
}

  // ═══════════════════════════════════════════════════════════════
  //  HERO GRADE CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeroGradeCard(bool isDark) {
    if (_isLoadingGrades) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2B1E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(
              color: Color(0xFF4F7942), strokeWidth: 2),
        ),
      );
    }

    final moyenne = _gradeSummary?.moyenneGenerale ?? 0.0;
    final status = _gradeSummary?.status ?? 'N/A';
    final coursesEvalues = _gradeSummary?.coursesEvalues ?? 0;
    final totalCourses = _gradeSummary?.totalCourses ?? 0;
    final progress = (moyenne / 20).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const GradesScreen())),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B3A2A), Color(0xFF2D5A3D), Color(0xFF3B6E4A)],
            stops: [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B3A2A).withOpacity(0.45),
              blurRadius: 32,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Decorative orbs
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: 40,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.03),
                  ),
                ),
              ),
              // Top separator line (glass effect)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.08)),
              ),

              Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top pill + status badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4ADE80),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'MES NOTES',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                              color: Color(0xFF1B3A2A),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Score + ring
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  moyenne.toStringAsFixed(2),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 54,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                    letterSpacing: -2,
                                  ),
                                ),
                                const Text(
                                  ' /20',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Moyenne Générale',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Circular progress ring
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(72, 72),
                                painter: _RingPainter(
                                  progress: progress,
                                  trackColor:
                                      Colors.white.withOpacity(0.1),
                                  progressColor:
                                      const Color(0xFF4ADE80),
                                  strokeWidth: 6,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Stats chips
                    Row(
                      children: [
                        _heroChip(
                            Icons.assessment_outlined,
                            '$coursesEvalues cours évalués'),
                        const SizedBox(width: 10),
                        _heroChip(
                            Icons.school_outlined,
                            '$totalCourses total'),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // CTA
                    Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Voir le bulletin complet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _heroChip(IconData icon, String label) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white60, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  COURS DU JOUR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTodayCoursesSection(bool isDark) {
    if (_todaySessions.isEmpty) {
      return _floatingCard(
        isDark: isDark,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF4F7942).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.event_note_outlined,
                  color: Color(0xFF4F7942), size: 22),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aucun cours aujourd\'hui',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? Colors.white : const Color(0xFF1A1A2E))),
                const SizedBox(height: 2),
                Text('Profitez de votre journée !',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      children: _todaySessions.map((course) {
        final isCurrent = course.isCurrent;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCourseCard(course, isCurrent, isDark),
        );
      }).toList(),
    );
  }

  Widget _buildCourseCard(Course course, bool isCurrent, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PlanningPage())),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isCurrent
              ? const Color(0xFF1B3A2A)
              : (isDark ? const Color(0xFF1E2B1E) : Colors.white),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: isCurrent
                  ? const Color(0xFF1B3A2A).withOpacity(0.3)
                  : Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFF4ADE80).withOpacity(0.2)
                          : const Color(0xFF4F7942).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isCurrent ? 'EN COURS' : course.label.toUpperCase(),
                      style: TextStyle(
                        color: isCurrent
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF4F7942),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Course name
                  Text(
                    course.matiere,
                    style: TextStyle(
                      color: isCurrent
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF1A1A2E)),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Metadata
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _metaChip(Icons.access_time_rounded, course.time,
                            isCurrent, isDark),
                        const SizedBox(width: 10),
                        _metaChip(Icons.location_on_outlined, course.salle,
                            isCurrent, isDark),
                        const SizedBox(width: 10),
                        _metaChip(Icons.person_outline, course.prof,
                            isCurrent, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isCurrent
                    ? Colors.white.withOpacity(0.12)
                    : const Color(0xFF4F7942).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: isCurrent
                    ? Colors.white
                    : const Color(0xFF4F7942),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(
      IconData icon, String text, bool isCurrent, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 12,
            color: isCurrent
                ? Colors.white60
                : (isDark ? Colors.white38 : Colors.grey[500])),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
              fontSize: 12,
              color: isCurrent
                  ? Colors.white70
                  : (isDark ? Colors.white54 : Colors.grey[600]),
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  NOTIFICATIONS URGENTES
  // ═══════════════════════════════════════════════════════════════

  Widget _buildUrgentNotificationsSection(bool isDark) {
    final displayed = _urgentNotifications.take(3).toList();
    final configs = [
      {'color': const Color(0xFFEF4444), 'icon': Icons.school_outlined},
      {
        'color': const Color(0xFFF59E0B),
        'icon': Icons.account_balance_wallet_outlined
      },
      {'color': const Color(0xFF4F7942), 'icon': Icons.event_outlined},
    ];

    return Column(
      children: displayed.asMap().entries.map((e) {
        final notif = e.value;
        final cfg = configs[e.key % configs.length];
        final color = cfg['color'] as Color;
        final icon = cfg['icon'] as IconData;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationsPage())),
            child: _floatingCard(
              isDark: isDark,
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif['titre'] ?? 'Notification',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          notif['message'] ?? '',
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle)),
                      const SizedBox(height: 4),
                      Text(
                        notif['date_formattee'] ?? '',
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ACTIVITÉ RÉCENTE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildActivityFeedSection(bool isDark) {
    return _floatingCard(
      isDark: isDark,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: _recentActivityFeed.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isLast = i == _recentActivityFeed.length - 1;

          IconData icon;
          Color color;
          switch (item['type']) {
            case 'document':
              icon = Icons.description_outlined;
              color = const Color(0xFF4F7942);
              break;
            case 'payment':
              icon = Icons.account_balance_wallet_outlined;
              color = const Color(0xFF10B981);
              break;
            case 'event':
              icon = Icons.event_outlined;
              color = const Color(0xFF8B5CF6);
              break;
            default:
              icon = Icons.info_outline;
              color = const Color(0xFF64748B);
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(icon, color: color, size: 18),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 1.5,
                          margin:
                              const EdgeInsets.symmetric(vertical: 4),
                          color: Colors.grey.withOpacity(0.15),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] ?? '',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1A2E),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['subtitle'] ?? '',
                                style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          item['date_formattee'] ?? '',
                          style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  PROGRESSION SEMESTRE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildProgressionCard(bool isDark) {
    // Si la moyenne générale est dans _stats ou via grades summary
    double userProgress = 0.0;
    if (_gradeSummary != null && _gradeSummary!.moyenneGenerale > 0) {
      // Convertir la moyenne (ex: 14.4 / 20) en pourcentage (ex: 72.0)
      userProgress = _gradeSummary!.moyenneGenerale / 20.0;
    }
    
    // Fallback à 0% si on a pas de données
    final double progress = userProgress > 0 ? userProgress : 0.0;
    final int progressPercent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B3A2A) : const Color(0xFF1B3A2A),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B3A2A).withOpacity(0.4),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'PROGRESSION SEMESTRE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$progressPercent%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      progressPercent >= 50 ? 'Bravo ! Vous êtes sur la bonne voie.' : 'Courage, redoublez d\'efforts !',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(76, 76),
                      painter: _RingPainter(
                        progress: progress,
                        trackColor: Colors.white.withOpacity(0.1),
                        progressColor: const Color(0xFF4ADE80),
                        strokeWidth: 7,
                      ),
                    ),
                    Text(
                      '$progressPercent%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF4ADE80)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin'].map((m) {
              return Text(
                m,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  RÉSUMÉ RAPIDE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSummaryGrid(bool isDark) {
    return Consumer2<PaymentProvider, NotificationProvider>(
      builder: (context, paymentProv, notifProv, _) {
        final items = [
          {
            'label': 'Cours suivis',
            'value': '${_todaySessions.length}',
            'icon': Icons.school_outlined,
            'color': const Color(0xFF4F7942),
            'onTap': () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PlanningPage())),
          },
          {
            'label': 'Paiements',
            'value': paymentProv.isLoading
                ? '...'
                : '${paymentProv.progression.toInt()}%',
            'icon': Icons.account_balance_wallet_outlined,
            'color': const Color(0xFFF59E0B),
            'onTap': () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const PaiementPage(showBackButton: true))),
          },
          {
            'label': 'Notifs',
            'value': '${notifProv.unreadCount}',
            'icon': Icons.notifications_outlined,
            'color': const Color(0xFF8B5CF6),
            'onTap': () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationsPage())),
          },
          {
            'label': 'Événements',
            'value': _nextEvent != null ? '1' : '0',
            'icon': Icons.event_outlined,
            'color': const Color(0xFFEF4444),
            'onTap': () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EvenementsPage())),
          },
        ];

        final topRow = items.sublist(0, 2);
        final bottomRow = items.sublist(2, 4);

        Widget buildCard(Map<String, dynamic> item) {
          final color = item['color'] as Color;
          return Expanded(
            child: GestureDetector(
              onTap: item['onTap'] as VoidCallback,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2B1E) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item['icon'] as IconData,
                          color: color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item['value'] as String,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            Row(
              children: [
                buildCard(topRow[0]),
                const SizedBox(width: 12),
                buildCard(topRow[1]),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                buildCard(bottomRow[0]),
                const SizedBox(width: 12),
                buildCard(bottomRow[1]),
              ],
            ),
          ],
        );
      },
    );
  }


  // ═══════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════

  Widget _floatingCard({
    required bool isDark,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2B1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionLabel(String title, bool isDark,
      {VoidCallback? onTap}) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            letterSpacing: -0.4,
          ),
        ),
        const Spacer(),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF4F7942).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Voir tout',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4F7942),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CUSTOM PAINTER — Ring Progress
// ═══════════════════════════════════════════════════════════════

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = trackColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = progressColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
