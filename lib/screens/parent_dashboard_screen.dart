import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/parent_dashboard_model.dart';
import '../services/auth_service.dart';
import '../widgets/modern_nav_bar.dart';
import '../widgets/document_detail_sheet.dart';
import '../utils/url_fixer.dart';
import '../utils/content_router.dart';
import 'login_page.dart';
import 'parent_notifications_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;
  ParentDashboardResponse? _dashboardData;
  int _selectedChildIndex = 0;
  int _currentKpiIndex = 0;
  int _currentNavIndex = 0;
  final Set<String> _readNotificationIds = {};

  // Documents state
  List<dynamic> _documentRequests = [];
  bool _isLoadingDocs = false;
  String? _docError;

  static const Color primaryGreen = Color(0xFF19553D);
  static const Color accentGreen = Color(0xFF298A5E);

  static const List<NavBarItem> _navItems = [
    NavBarItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Accueil',
    ),
    NavBarItem(
      icon: Icons.event_busy_outlined,
      activeIcon: Icons.event_busy_rounded,
      label: 'Absences',
    ),
    NavBarItem(
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
      label: 'Notes',
    ),
    NavBarItem(
      icon: Icons.description_outlined,
      activeIcon: Icons.description_rounded,
      label: 'Documents',
    ),
    NavBarItem(
      icon: Icons.credit_card_outlined,
      activeIcon: Icons.credit_card_rounded,
      label: 'Paiement',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadReadNotifications();
    _fetchData();
  }

  Future<void> _loadReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    // Use parent-specific key based on email to isolate between parents
    final email = prefs.getString('parent_email') ?? '';
    final specificKey = 'parent_read_notifs_${email.isNotEmpty ? email : "default"}';
    final specificIds = prefs.getStringList(specificKey) ?? [];
    if (mounted) {
      setState(() {
        _readNotificationIds.addAll(specificIds);
      });
    }
  }

  Future<void> _saveReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('parent_email') ?? '';
    final specificKey = 'parent_read_notifs_${email.isNotEmpty ? email : "default"}';
    await prefs.setStringList(specificKey, _readNotificationIds.toList());
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.getParentDashboard();

    if (!mounted) return;

    if (result['success'] == true && result['data'] is ParentDashboardResponse) {
      final data = result['data'] as ParentDashboardResponse;
      int childIdx = _selectedChildIndex;
      if (childIdx >= data.children.length) {
        childIdx = 0;
      }
      setState(() {
        _dashboardData = data;
        _isLoading = false;
        _selectedChildIndex = childIdx;
      });

      if (data.children.isNotEmpty) {
        _fetchDocuments(data.children[childIdx].details.idStudent);
      }
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Impossible de charger les données du portail parent.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDocuments(int studentId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingDocs = true;
      _docError = null;
    });

    final result = await _authService.getParentDocumentRequests(studentId: studentId);
    if (!mounted) return;

    setState(() {
      _isLoadingDocs = false;
      if (result['success'] == true) {
        _documentRequests = result['data'] ?? [];
      } else {
        _docError = result['message'] ?? 'Impossible de charger les demandes de documents.';
      }
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: primaryGreen),
            SizedBox(width: 10),
            Text(
              'Déconnexion',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter de votre espace parent ?',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Se déconnecter', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _authService.parentLogout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF141914) : const Color(0xFFF8FAF9);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    color: primaryGreen,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Chargement de votre espace parent...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                ),
                const SizedBox(height: 18),
                Text(
                  'Une erreur est survenue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _fetchData,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Réessayer', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final parent = _dashboardData?.parent;
    final children = _dashboardData?.children ?? [];

    if (children.isEmpty) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.family_restroom, size: 54, color: primaryGreen),
                ),
                const SizedBox(height: 20),
                Text(
                  'Aucun élève rattaché',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Aucun enfant n\'est actuellement associé à votre compte parent. Veuillez contacter l\'administration scolaire.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activeChild = children[_selectedChildIndex];

    final pages = [
      _buildOverviewTab(parent, children, activeChild, isDark),
      _buildAbsencesTab(children, activeChild, isDark),
      _buildGradesTab(children, activeChild, isDark),
      _buildDocumentsTab(children, activeChild, isDark),
      _buildPaymentsTab(children, activeChild, isDark),
    ];

    return Scaffold(
      backgroundColor: bg,
      extendBody: false,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentNavIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: CustomModernNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
        items: _navItems,
      ),
    );
  }

  // =============================================================
  // TAB 0: ACCUEIL (OVERVIEW)
  // =============================================================
  Widget _buildOverviewTab(
    ParentInfo? parent,
    List<ChildData> children,
    ChildData activeChild,
    bool isDark,
  ) {
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: primaryGreen,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          _buildTopHeader(parent, activeChild, isDark),
          const SizedBox(height: 16),
          _buildChildSelectorBar(children, isDark),
          const SizedBox(height: 20),
          _buildHeroCard(activeChild),
          const SizedBox(height: 22),
          _buildKpiRow(activeChild, isDark),
          const SizedBox(height: 26),
          _buildQuickActions(activeChild, isDark),
          const SizedBox(height: 26),
          _buildAnnouncementsSection(activeChild.announcements, isDark),
        ],
      ),
    );
  }

  // =============================================================
  // TAB 1: ABSENCES & PRÉSENCES
  // =============================================================
  Widget _buildAbsencesTab(
    List<ChildData> children,
    ChildData activeChild,
    bool isDark,
  ) {
    final attendance = activeChild.attendance;

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: primaryGreen,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          _buildTabHeader('Absences', '', Icons.event_busy, const Color(0xFFEF4444), isDark),
          const SizedBox(height: 14),
          _buildChildSelectorBar(children, isDark),
          const SizedBox(height: 20),

          // 3 Stat Counters Row
          Row(
            children: [
              Expanded(
                child: _buildStatBadge(
                  title: 'Total Absences',
                  value: attendance.totalAbsences.toString(),
                  subtitle: 'enregistrée(s)',
                  color: const Color(0xFFEF4444),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBadge(
                  title: 'Justifiées',
                  value: attendance.justifiedAbsences.toString(),
                  subtitle: 'validée(s)',
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBadge(
                  title: 'Non justifiées',
                  value: attendance.unjustifiedAbsences.toString(),
                  subtitle: 'à justifier',
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historique des séances',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${attendance.history.length} enregistrée(s)',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (attendance.history.isEmpty)
            _buildEmptyState(
              icon: Icons.check_circle_outline,
              color: const Color(0xFF10B981),
              title: 'Excellente assiduité !',
              subtitle: 'Aucune absence enregistrée pour ${activeChild.details.prenom}. Félicitations !',
              isDark: isDark,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: attendance.history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final item = attendance.history[i];
                final isJustified = item.isJustified;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2B1E) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (isJustified ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isJustified ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                          color: isJustified ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.matiere,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.dateFormatted ?? item.date ?? 'Date non définie'} • Séance : ${item.seance}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                            if (item.justificationReason != null && item.justificationReason!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.justificationReason!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (isJustified ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isJustified ? 'Justifiée' : 'Non justifiée',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isJustified ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // =============================================================
  // TAB 2: NOTES & ÉVALUATIONS
  // =============================================================
  Widget _buildGradesTab(
    List<ChildData> children,
    ChildData activeChild,
    bool isDark,
  ) {
    final grades = activeChild.grades;

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: primaryGreen,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          _buildTabHeader('Notes', '', Icons.school_outlined, const Color(0xFF6366F1), isDark),
          const SizedBox(height: 14),
          _buildChildSelectorBar(children, isDark),
          const SizedBox(height: 20),

          // Big General Average Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryGreen, accentGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Moyenne Générale',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              grades.average.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            const Text(
                              ' / 20',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        (grades.mention != null && grades.mention!.isNotEmpty) ? grades.mention! : _getAppreciation(grades.average),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (grades.average / 20).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniStat('Meilleure', '${grades.highestGrade.toStringAsFixed(1)}/20'),
                    _buildMiniStat('Plus basse', '${grades.lowestGrade.toStringAsFixed(1)}/20'),
                    _buildMiniStat('Total saisies', '${grades.totalGrades} notes'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Detailed Grades List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Détail des évaluations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                '${grades.list.length} note(s)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (grades.list.isEmpty)
            _buildEmptyState(
              icon: Icons.menu_book,
              color: Colors.orange,
              title: 'Aucune note disponible',
              subtitle: 'Les notes et contrôles de ${activeChild.details.prenom} apparaîtront ici une fois saisis.',
              isDark: isDark,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: grades.list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final item = grades.list[i];
                final score = item.note;
                final isGood = score >= 12;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2B1E) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (isGood ? primaryGreen : Colors.orange).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            isGood ? Icons.auto_awesome : Icons.edit_note,
                            color: isGood ? primaryGreen : Colors.orange,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.subjectName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.type}' + (item.coefficient > 0 ? ' • Coeff. ' + (item.coefficient % 1 == 0 ? item.coefficient.toInt().toString() : item.coefficient.toString()) : '') + ' • ' + item.semester,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                            if (item.examDateFormatted != null && item.examDateFormatted!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.examDateFormatted!,
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: (isGood ? primaryGreen : Colors.orange).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${score.toStringAsFixed(1)} / 20',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isGood ? primaryGreen : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // =============================================================
  // TAB 3: DOCUMENTS SCOLAIRES
  // =============================================================
  Widget _buildDocumentsTab(
    List<ChildData> children,
    ChildData activeChild,
    bool isDark,
  ) {
    final totalDocs = _documentRequests.length;
    final enAttente = _documentRequests.where((d) => d['status'] == 'En attente' || d['status'] == 'En cours').length;
    final prets = _documentRequests.where((d) => d['status'] == 'Prêt' || d['status'] == 'Validé' || d['status'] == 'Disponible').length;

    return RefreshIndicator(
      onRefresh: () => _fetchDocuments(activeChild.details.idStudent),
      color: primaryGreen,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          _buildTabHeader('Documents', '', Icons.description_outlined, const Color(0xFF14B8A6), isDark),
          const SizedBox(height: 14),
          _buildChildSelectorBar(children, isDark),
          const SizedBox(height: 18),

          // Primary Action: Nouvelle demande
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryGreen, accentGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showNewDocumentModal(activeChild),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Demander un document officiel',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Certificat, relevé de notes, attestation pour ${activeChild.details.prenom}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 3 Stat Badges Row
          Row(
            children: [
              Expanded(
                child: _buildStatBadge(
                  title: 'Total demandes',
                  value: totalDocs.toString(),
                  subtitle: 'soumise(s)',
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBadge(
                  title: 'En traitement',
                  value: enAttente.toString(),
                  subtitle: 'en attente',
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBadge(
                  title: 'Disponibles',
                  value: prets.toString(),
                  subtitle: 'prêt(s)',
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historique des demandes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20, color: primaryGreen),
                tooltip: 'Actualiser',
                onPressed: () => _fetchDocuments(activeChild.details.idStudent),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Document Requests List
          if (_isLoadingDocs)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: primaryGreen),
              ),
            )
          else if (_docError != null)
            _buildDocErrorCard(_docError!, () => _fetchDocuments(activeChild.details.idStudent), isDark)
          else if (_documentRequests.isEmpty)
            _buildEmptyState(
              icon: Icons.folder_open_outlined,
              color: primaryGreen,
              title: 'Aucune demande enregistrée',
              subtitle: 'Vous n\'avez pas encore effectué de demande de document officiel pour ${activeChild.details.prenom}.',
              isDark: isDark,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _documentRequests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final doc = _documentRequests[i];
                return _buildDocumentCard(doc, isDark);
              },
            ),
        ],
      ),
    );
  }

  String _formatParentReadyDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final parsed = DateTime.parse(raw.toString().replaceAll(' ', 'T'));
      return "${DateFormat('dd/MM/yyyy').format(parsed)} à ${DateFormat('HH:mm').format(parsed)}";
    } catch (_) {
      return raw.toString();
    }
  }

  
  void _showRequestDetail(dynamic doc) {
    final Map<String, dynamic> mapReq = doc is Map<String, dynamic>
        ? Map<String, dynamic>.from(doc)
        : (doc is Map ? Map<String, dynamic>.from(doc) : <String, dynamic>{});

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DocumentDetailSheet(request: mapReq),
    );
  }

  Widget _buildDocumentCard(dynamic doc, bool isDark) {
    final String type = doc['document_type'] ?? 'Document Officiel';
    final String status = doc['status'] ?? 'En attente';
    final String urgency = doc['urgency'] ?? 'Normale';
    final String? comments = doc['comments'] ?? doc['reason'];
    final String? rejectionReason = doc['rejection_reason'];
    final String? pdfUrl = doc['pdf_url'];
    final bool hasPdf = doc['has_pdf'] == true || (pdfUrl != null && pdfUrl.isNotEmpty);
    final String dateStr = doc['request_date'] ?? doc['created_at'] ?? '';
    final String readyDateFormatted = _formatParentReadyDate(doc['ready_date']);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (status == 'Prêt' || status == 'Disponible' || status == 'Validé' || status == 'ready') {
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle_outline;
      statusText = 'Disponible / Prêt';
    } else if (status == 'En cours' || status == 'processing') {
      statusColor = const Color(0xFF6366F1);
      statusIcon = Icons.hourglass_top_outlined;
      statusText = 'En cours de traitement';
    } else if (status == 'Rejeté' || status == 'Refusé' || status == 'rejected') {
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.cancel_outlined;
      statusText = 'Demande rejetée';
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.access_time;
      statusText = 'En attente de validation';
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2B1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showRequestDetail(doc),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.description, color: primaryGreen, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (dateStr.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade500),
                                const SizedBox(width: 5),
                                Text(
                                  'Demandé le : $dateStr',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (urgency.toLowerCase() == 'urgente' || urgency.toLowerCase() == 'urgent') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'Urgente',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Date de disponibilité
                if (readyDateFormatted.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_available_rounded, size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Disponible le : $readyDateFormatted',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Remarks or Rejection Reason
                if (comments != null && comments.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Motif / Note : $comments',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],

                if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: Colors.red),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Motif du refus : $rejectionReason',
                            style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Download PDF Action Button
                if (hasPdf && (status == 'Prêt' || status == 'Disponible' || status == 'Validé' || status == 'ready')) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (pdfUrl != null && pdfUrl.isNotEmpty) {
                          final fixedUrl = UrlFixer.fixUrl(pdfUrl);
                          await ContentRouter.routeContent(
                            context,
                            contentUrl: fixedUrl,
                            contentTitle: doc['document_type'] ?? 'Document PDF',
                          );
                        }
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text(
                        'Télécharger le document PDF',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNewDocumentModal(ChildData activeChild) {
    String selectedDocType = 'Certificat de scolarité';
    String selectedUrgency = 'normal';
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    final List<Map<String, dynamic>> docTypes = [
      {'label': 'Certificat de scolarité',  'icon': Icons.school_outlined,           'color': const Color(0xFF10B981)},
      {'label': 'Relevé de notes',          'icon': Icons.description_outlined,      'color': const Color(0xFF6366F1)},
      {'label': 'Attestation de scolarité', 'icon': Icons.assignment_outlined,       'color': const Color(0xFF8B5CF6)},
      {'label': 'Convention de stage',      'icon': Icons.work_outline_rounded,      'color': const Color(0xFFF59E0B)},
      {'label': 'Attestation de présence',  'icon': Icons.co_present_outlined,       'color': const Color(0xFFEF4444)},
      {'label': 'Autre document',           'icon': Icons.insert_drive_file_outlined,'color': const Color(0xFF14B8A6)},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final modalBg = isDark ? const Color(0xFF141914) : const Color(0xFFF8FAF9);
            final cardBg = isDark ? const Color(0xFF1E2620) : Colors.white;
            final textDark = isDark ? Colors.white : const Color(0xFF0F172A);

            return Container(
              height: MediaQuery.of(context).size.height * 0.92,
              decoration: BoxDecoration(
                color: modalBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag Handle
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 4,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Top Gradient Hero Banner (matching img2) ──
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF0284C7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0284C7).withOpacity(0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.note_add_outlined,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Nouvelle demande',
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 19,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Pour : ${activeChild.details.nomComplet}',
                                            style: GoogleFonts.inter(
                                              color: Colors.white.withOpacity(0.92),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    _buildDocStatBadge(Icons.access_time_rounded, 'Délai', '24h'),
                                    const SizedBox(width: 8),
                                    _buildDocStatBadge(Icons.sell_outlined, 'Coût', 'Gratuit'),
                                    const SizedBox(width: 8),
                                    _buildDocStatBadge(Icons.trending_up_rounded, 'Réussite', '98%'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Form Container Card ──
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.025),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── 1. Type de document ──
                                Text(
                                  '1. Type de document',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textDark,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 2.3,
                                  ),
                                  itemCount: docTypes.length,
                                  itemBuilder: (context, index) {
                                    final item = docTypes[index];
                                    final isSelected = selectedDocType == item['label'];
                                    return GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setModalState(() => selectedDocType = item['label'] as String);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF10B981)
                                                : (isDark ? Colors.white12 : const Color(0xFFF1F5F9)),
                                            width: isSelected ? 1.8 : 1,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(0xFF10B981).withOpacity(0.12),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  )
                                                ]
                                              : [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.015),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  )
                                                ],
                                        ),
                                        child: Stack(
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(7),
                                                  decoration: BoxDecoration(
                                                    color: (item['color'] as Color).withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    item['icon'] as IconData,
                                                    color: item['color'] as Color,
                                                    size: 17,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    item['label'] as String,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11.5,
                                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                      color: textDark,
                                                      height: 1.25,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (isSelected)
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: Container(
                                                  padding: const EdgeInsets.all(2.5),
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF10B981),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.check,
                                                    size: 9,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 26),

                                // ── 2. Niveau d'urgence ──
                                Text(
                                  '2. Niveau d\'urgence',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textDark,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          setModalState(() => selectedUrgency = 'normal');
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: selectedUrgency == 'normal'
                                                ? (isDark ? const Color(0xFF1B3524) : const Color(0xFFECFDF5))
                                                : (isDark ? Colors.white.withOpacity(0.02) : Colors.white),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: selectedUrgency == 'normal'
                                                  ? const Color(0xFF10B981)
                                                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                              width: selectedUrgency == 'normal' ? 1.8 : 1,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.check_circle_outline_rounded,
                                                    size: 18,
                                                    color: selectedUrgency == 'normal'
                                                        ? const Color(0xFF10B981)
                                                        : const Color(0xFF94A3B8),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Normal',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      color: selectedUrgency == 'normal'
                                                          ? (isDark ? Colors.white : const Color(0xFF047857))
                                                          : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Traitement standard',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: const Color(0xFF94A3B8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          setModalState(() => selectedUrgency = 'urgent');
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: selectedUrgency == 'urgent'
                                                ? (isDark ? const Color(0xFF381C1C) : const Color(0xFFFEF2F2))
                                                : (isDark ? Colors.white.withOpacity(0.02) : Colors.white),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: selectedUrgency == 'urgent'
                                                  ? const Color(0xFFEF4444)
                                                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                              width: selectedUrgency == 'urgent' ? 1.8 : 1,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.bolt_rounded,
                                                    size: 18,
                                                    color: selectedUrgency == 'urgent'
                                                        ? const Color(0xFFEF4444)
                                                        : const Color(0xFF94A3B8),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Urgent',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      color: selectedUrgency == 'urgent'
                                                          ? (isDark ? Colors.white : const Color(0xFFB91C1C))
                                                          : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Traitement prioritaire',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: const Color(0xFF94A3B8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 26),

                                // ── 3. Motif (Optionnel) ──
                                Text(
                                  '3. Motif (Optionnel)',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textDark,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: reasonController,
                                  maxLength: 500,
                                  maxLines: 4,
                                  onChanged: (_) => setModalState(() {}),
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    color: textDark,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Expliquez brièvement le motif de votre demande...',
                                    hintStyle: GoogleFonts.inter(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 13,
                                    ),
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.only(bottom: 56),
                                      child: Icon(
                                        Icons.edit_note_rounded,
                                        color: Color(0xFF10B981),
                                        size: 22,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF10B981),
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    counterStyle: GoogleFonts.inter(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 26),

                                // ── Submit Gradient Button ──
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF10B981), Color(0xFF0284C7)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0284C7).withOpacity(0.3),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: isSubmitting
                                          ? null
                                          : () async {
                                              HapticFeedback.mediumImpact();
                                              setModalState(() => isSubmitting = true);
                                              final result = await _authService.createParentDocumentRequest(
                                                studentId: activeChild.details.idStudent,
                                                documentType: selectedDocType,
                                                reason: reasonController.text.trim(),
                                                comments: reasonController.text.trim(),
                                                urgency: selectedUrgency == 'urgent' ? 'urgent' : 'normal',
                                              );
                                              setModalState(() => isSubmitting = false);

                                              if (!context.mounted) return;

                                              if (result['success'] == true) {
                                                Navigator.pop(ctx);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Row(
                                                      children: [
                                                        const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Text(
                                                            result['message'] ?? 'Votre demande a été soumise avec succès !',
                                                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    backgroundColor: primaryGreen,
                                                    behavior: SnackBarBehavior.floating,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  ),
                                                );
                                                _fetchDocuments(activeChild.details.idStudent);
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      result['message'] ?? 'Erreur lors de la création de la demande.',
                                                      style: GoogleFonts.inter(),
                                                    ),
                                                    backgroundColor: Colors.red,
                                                    behavior: SnackBarBehavior.floating,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  ),
                                                );
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 0,
                                      ),
                                      child: isSubmitting
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                                                const SizedBox(width: 10),
                                                Text(
                                                  'ENVOYER LA DEMANDE',
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.8,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocStatBadge(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 10),
            ),
            Text(
              value,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocErrorCard(String msg, VoidCallback onRetry, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2B1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 36, color: Colors.red),
          const SizedBox(height: 10),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16, color: primaryGreen),
            label: const Text('Réessayer', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // TAB 4: FRAIS DE SCOLARITÉ & PAIEMENTS
  // =============================================================
  Widget _buildPaymentsTab(
    List<ChildData> children,
    ChildData activeChild,
    bool isDark,
  ) {
    final payments = activeChild.payments;
    final isUpToDate = payments.totalRemaining <= 0;
    final double progress = payments.totalAmount > 0
        ? (payments.totalPaid / payments.totalAmount).clamp(0.0, 1.0)
        : 1.0;

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: primaryGreen,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          _buildTabHeader('Paiements', '', Icons.credit_card_outlined, const Color(0xFFF59E0B), isDark),
          const SizedBox(height: 14),
          _buildChildSelectorBar(children, isDark),
          const SizedBox(height: 20),

          // Summary Balance Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isUpToDate
                    ? [primaryGreen, accentGreen]
                    : [const Color(0xFF2C3E50), const Color(0xFF34495E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Situation Financière',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isUpToDate ? const Color(0xFF10B981) : Colors.orange).withOpacity(0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        payments.overallStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Reste à payer',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${payments.totalRemaining.toStringAsFixed(0)} MAD',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total scolarité : ${payments.totalAmount.toStringAsFixed(0)} MAD',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      'Payé : ${payments.totalPaid.toStringAsFixed(0)} MAD',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tranches Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Échéancier des tranches',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                '${payments.tranches.length} tranche(s)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (payments.tranches.isEmpty)
            _buildEmptyState(
              icon: Icons.receipt_long_outlined,
              color: Colors.teal,
              title: 'Aucune tranche enregistrée',
              subtitle: 'Aucun échéancier financier n\'est actuellement configuré pour cet élève.',
              isDark: isDark,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payments.tranches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final tranche = payments.tranches[i];
                final isPaid = tranche.status.toLowerCase() == 'payé' || tranche.status.toLowerCase() == 'paye';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2B1E) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (isPaid ? const Color(0xFF10B981) : Colors.orange).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isPaid ? Icons.check_circle : Icons.pending_actions,
                          color: isPaid ? const Color(0xFF10B981) : Colors.orange,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tranche.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Échéance : ${tranche.dueDate}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            tranche.amount,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isPaid ? const Color(0xFF10B981) : Colors.orange).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isPaid ? 'Payé' : 'En attente',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isPaid ? const Color(0xFF10B981) : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryGreen.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20, color: primaryGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pour tout règlement par virement ou chèque, merci de vous adresser directement au service comptabilité de l\'établissement.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      height: 1.3,
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

  // =============================================================
  // REUSABLE DASHBOARD WIDGETS
  // =============================================================

  Widget _buildTopHeader(ParentInfo? parent, ChildData activeChild, bool isDark) {
    final parentInitial = (parent?.name.isNotEmpty == true) ? parent!.name[0].toUpperCase() : 'M';
    final parentName = (parent?.name.isNotEmpty == true) ? parent!.name : 'Mohammed Alami';

    final notifications = _getNotifications(activeChild);
    final unreadCount = notifications.where((n) => !_readNotificationIds.contains(n.id)).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF134E35),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  parentInitial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue,',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  parentName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            // ── Modern Notification Bell Button with Badge ──
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openNotificationCenter(notifications, activeChild.details.nomComplet),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2B22) : const Color(0xFFF1F8F5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? primaryGreen.withOpacity(0.3) : const Color(0xFFD1E7DD),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: Icon(
                          Icons.notifications_outlined,
                          size: 22,
                          color: isDark ? Colors.white : primaryGreen,
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? const Color(0xFF141914) : Colors.white,
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
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ── Logout Button ──
            InkWell(
              onTap: _logout,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A1E1E) : const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.red.withOpacity(0.2) : const Color(0xFFFFE4E6),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.exit_to_app_rounded,
                    size: 20,
                    color: Color(0xFFEF5350),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Extract all dynamic notifications for active child ──
  List<ParentNotificationItem> _getNotifications(ChildData activeChild) {
    final List<ParentNotificationItem> items = [];

    // 1. Absences
    for (final abs in activeChild.attendance.history) {
      final id = 'abs_${abs.id}';
      items.add(
        ParentNotificationItem(
          id: id,
          title: abs.isJustified ? 'Absence justifiée' : 'Absence enregistrée',
          message: '${abs.matiere} • ${abs.seance} (${abs.professeur})',
          time: abs.dateFormatted ?? abs.date ?? 'Récemment',
          category: 'Absence',
          icon: Icons.event_busy_rounded,
          color: const Color(0xFFEF4444),
          bgColor: const Color(0xFFFEF2F2),
          targetTabIndex: 1, // Absences tab
          isUnread: !_readNotificationIds.contains(id),
        ),
      );
    }

    // 2. Notes
    for (final grade in activeChild.grades.list) {
      final id = 'grade_${grade.id}';
      items.add(
        ParentNotificationItem(
          id: id,
          title: 'Nouvelle note : ${grade.subjectName}',
          message: 'Note : ${grade.noteFormatted}/20 (${grade.type}) • ${grade.teacherName}',
          time: grade.examDateFormatted ?? grade.examDate ?? 'Ce semestre',
          category: 'Note',
          icon: Icons.school_rounded,
          color: const Color(0xFF10B981),
          bgColor: const Color(0xFFECFDF5),
          targetTabIndex: 2, // Notes tab
          isUnread: !_readNotificationIds.contains(id),
        ),
      );
    }

    // 3. Documents
    for (int i = 0; i < _documentRequests.length; i++) {
      final doc = _documentRequests[i];
      if (doc is Map) {
        final docId = doc['id']?.toString() ?? 'doc_$i';
        final id = 'doc_$docId';
        final docTitle = doc['type_document'] ?? doc['titre'] ?? 'Document scolaire';
        final status = doc['statut'] ?? doc['status'] ?? 'En attente';
        items.add(
          ParentNotificationItem(
            id: id,
            title: 'Statut Document : $docTitle',
            message: 'Statut actuel : $status',
            time: doc['created_at']?.toString() ?? 'Récemment',
            category: 'Document',
            icon: Icons.description_rounded,
            color: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF5F3FF),
            targetTabIndex: 3, // Documents tab
            isUnread: !_readNotificationIds.contains(id),
          ),
        );
      }
    }

    // 4. Avis & Annonces scolaires
    for (final ann in activeChild.announcements) {
      final id = 'ann_${ann.id}';
      items.add(
        ParentNotificationItem(
          id: id,
          title: ann.titre,
          message: ann.message,
          time: ann.dateRelative ?? ann.createdAt ?? 'Récemment',
          category: 'Annonce',
          icon: Icons.campaign_rounded,
          color: const Color(0xFF3B82F6),
          bgColor: const Color(0xFFEFF6FF),
          targetTabIndex: 0, // Accueil tab
          isUnread: !_readNotificationIds.contains(id),
        ),
      );
    }

    // 5. Paiements
    for (final p in activeChild.payments.tranches) {
      final id = 'pay_${p.id}';
      items.add(
        ParentNotificationItem(
          id: id,
          title: 'Échéance paiement : ${p.title}',
          message: 'Montant : ${p.amount} • Statut : ${p.status}',
          time: p.dueDate,
          category: 'Paiement',
          icon: Icons.credit_card_rounded,
          color: const Color(0xFF0D9488),
          bgColor: const Color(0xFFF0FDFA),
          targetTabIndex: 4, // Paiements tab
          isUnread: !_readNotificationIds.contains(id),
        ),
      );
    }

    return items;
  }

  // ── Open Dedicated Full-Screen Notification Center ──
  void _openNotificationCenter(List<ParentNotificationItem> notifications, String childName) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParentNotificationsPage(
          childName: childName,
          notifications: notifications,
          readNotificationIds: _readNotificationIds,
          onMarkAsRead: (id) {
            setState(() => _readNotificationIds.add(id.toString()));
            _saveReadNotifications();
          },
          onMarkAllAsRead: () {
            setState(() {
              for (final n in notifications) {
                _readNotificationIds.add(n.id.toString());
              }
            });
            _saveReadNotifications();
          },
          onNavigateToTab: (targetTabIndex) {
            setState(() => _currentNavIndex = targetTabIndex);
          },
        ),
      ),
    );
  }

  Widget _buildTabHeader(String title, String subtitle, IconData icon, Color accentColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2B22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withOpacity(isDark ? 0.28 : 0.20),
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentColor.withOpacity(isDark ? 0.14 : 0.06),
            isDark ? const Color(0xFF1E2B22) : Colors.white,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(isDark ? 0.18 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey.shade400).withOpacity(isDark ? 0.25 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Subtle glowing halo behind the icon
          Positioned(
            top: -10,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withOpacity(isDark ? 0.22 : 0.15),
                    accentColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Left watermark icon
          Positioned(
            left: -8,
            bottom: -12,
            child: Opacity(
              opacity: isDark ? 0.04 : 0.04,
              child: Icon(
                icon,
                size: 72,
                color: accentColor,
              ),
            ),
          ),
          // Right watermark icon
          Positioned(
            right: -8,
            top: -12,
            child: Opacity(
              opacity: isDark ? 0.04 : 0.04,
              child: Icon(
                icon,
                size: 80,
                color: accentColor,
              ),
            ),
          ),
          // Main centered content
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Glowing Icon Badge with double border and neon effect
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withOpacity(isDark ? 0.40 : 0.28),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(isDark ? 0.30 : 0.20),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withOpacity(isDark ? 0.35 : 0.22),
                        accentColor.withOpacity(isDark ? 0.12 : 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: accentColor.withOpacity(0.35),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isDark ? Colors.white : accentColor,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Centered Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              // Subtle gradient glow indicator bar under title
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 36,
                height: 3.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withOpacity(0.2),
                      accentColor,
                      accentColor.withOpacity(0.2),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              // Subtitle (if present)
              if (subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChildSelectorBar(List<ChildData> children, bool isDark) {
    if (children.length <= 1) {
      return const SizedBox.shrink(); // Hide the selector if only one child
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enfant sélectionné (${children.length}) :',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: children.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final child = children[index];
              final isSelected = index == _selectedChildIndex;

              return GestureDetector(
                onTap: () {
                  if (_selectedChildIndex != index) {
                    setState(() => _selectedChildIndex = index);
                    _fetchDocuments(children[index].details.idStudent);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryGreen : (isDark ? const Color(0xFF1E2B1E) : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? primaryGreen : Colors.grey.shade300,
                      width: isSelected ? 1.6 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? primaryGreen.withOpacity(0.2) : Colors.black.withOpacity(0.02),
                        blurRadius: isSelected ? 10 : 4,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isSelected ? Colors.white : primaryGreen.withOpacity(0.12),
                        radius: 15,
                        child: Text(
                          child.details.prenom.isNotEmpty ? child.details.prenom[0].toUpperCase() : 'E',
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${child.details.prenom} ${child.details.nom}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          ),
                          Text(
                            child.details.classe,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white70 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(ChildData child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: primaryGreen,
        gradient: const LinearGradient(
          colors: [Color(0xFF19553D), Color(0xFF20664B)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                child.details.prenom.isNotEmpty ? child.details.prenom[0].toUpperCase() : 'E',
                style: const TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Line 1: Student Name + Status Badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${child.details.prenom} ${child.details.nom}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge: Élève actif
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.8),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Élève actif',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                
                // Line 2: Class tag + Matricule
                Row(
                  children: [
                    if (child.details.classe.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.5),
                        ),
                        child: Text(
                          child.details.classe,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        'Matricule : ${child.details.matricule}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildKpiRow(ChildData child, bool isDark) {
    final isUpToDate = child.payments.totalRemaining <= 0;

    String getMention(double moyenne) {
      if (moyenne >= 16) return 'Très Bien';
      if (moyenne >= 14) return 'Bien';
      if (moyenne >= 12) return 'Assez Bien';
      if (moyenne >= 10) return 'Passable';
      return 'Insuffisant';
    }

    final List<Widget> slides = [
      _buildNewKpiCard(
        title: 'Moyenne',
        value: '${child.grades.average.toStringAsFixed(1)}/20',
        subtitle: 'Mention : ${getMention(child.grades.average)}',
        badgeText: 'Favorable',
        badgeColor: const Color(0xFF10B981),
        icon: Icons.school,
        iconBgColor: const Color(0xFFE8F3ED),
        iconColor: primaryGreen,
        isDark: isDark,
      ),
      _buildNewKpiCard(
        title: 'Absences',
        value: '${child.attendance.totalAbsences} séance(s)',
        subtitle: 'Semestre en cours',
        badgeText: child.attendance.totalAbsences > 0 ? 'Attention' : 'Excellent',
        badgeColor: child.attendance.totalAbsences > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        icon: Icons.event_busy,
        iconBgColor: child.attendance.totalAbsences > 0 ? const Color(0xFFFDE8E8) : const Color(0xFFE8F3ED),
        iconColor: child.attendance.totalAbsences > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        isDark: isDark,
      ),
      _buildNewKpiCard(
        title: 'Scolarité',
        value: isUpToDate ? 'À jour' : '${child.payments.totalRemaining.toStringAsFixed(0)} MAD',
        subtitle: 'Frais de scolarité',
        badgeText: isUpToDate ? 'Réglé' : 'Impayé',
        badgeColor: isUpToDate ? const Color(0xFF10B981) : Colors.orange,
        icon: Icons.credit_card,
        iconBgColor: isUpToDate ? const Color(0xFFE8F3ED) : const Color(0xFFFEF3C7),
        iconColor: isUpToDate ? primaryGreen : Colors.orange,
        isDark: isDark,
      ),
    ];

    return Column(
      children: [
        CarouselSlider(
          items: slides,
          options: CarouselOptions(
            height: 110,
            viewportFraction: 1.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 3),
            onPageChanged: (index, reason) {
              setState(() {
                _currentKpiIndex = index;
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: slides.asMap().entries.map((entry) {
            return Container(
              width: _currentKpiIndex == entry.key ? 16.0 : 6.0,
              height: 6.0,
              margin: const EdgeInsets.symmetric(horizontal: 2.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3.0),
                color: _currentKpiIndex == entry.key
                    ? primaryGreen
                    : (isDark ? Colors.white24 : Colors.grey.shade300),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNewKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withOpacity(0.2) : iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? badgeColor.withOpacity(0.2) : badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ChildData child, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accès Rapide',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                title: 'Absences',
                subtitle: '${child.attendance.totalAbsences} séance(s)',
                icon: Icons.event_busy_outlined,
                color: const Color(0xFFEF4444),
                onTap: () => setState(() => _currentNavIndex = 1),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionTile(
                title: 'Notes',
                subtitle: '${child.grades.totalGrades} note(s)',
                icon: Icons.school_outlined,
                color: primaryGreen,
                onTap: () => setState(() => _currentNavIndex = 2),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionTile(
                title: 'Documents',
                subtitle: 'Demandes & PDF',
                icon: Icons.description_outlined,
                color: const Color(0xFF6366F1),
                onTap: () => setState(() => _currentNavIndex = 3),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionTile(
                title: 'Paiements',
                subtitle: child.payments.overallStatus,
                icon: Icons.credit_card_outlined,
                color: const Color(0xFF10B981),
                onTap: () => setState(() => _currentNavIndex = 4),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2B1E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsSection(List<ChildAnnouncement> announcements, bool isDark) {
    if (announcements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.campaign, size: 18, color: primaryGreen),
            ),
            const SizedBox(width: 12),
            Text(
              'Avis & Annonces scolaires',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF111827),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Announcements List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: announcements.take(3).length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final ann = announcements[i];
            
            // Determine category based on title
            final String titleLower = ann.titre.toLowerCase();
            IconData iconData = Icons.notifications_none;
            Color iconColor = primaryGreen;
            Color iconBg = primaryGreen.withOpacity(0.1);
            
            if (titleLower.contains('événement') || titleLower.contains('event')) {
              iconData = Icons.event;
              iconColor = const Color(0xFF3B82F6); // Blue
              iconBg = const Color(0xFFEFF6FF);
            } else if (titleLower.contains('urgent') || titleLower.contains('attention') || titleLower.contains('alerte')) {
              iconData = Icons.warning_amber_rounded;
              iconColor = const Color(0xFFEF4444); // Red
              iconBg = const Color(0xFFFEF2F2);
            } else if (titleLower.contains('succès') || titleLower.contains('félicitations')) {
              iconData = Icons.emoji_events_outlined;
              iconColor = const Color(0xFFF59E0B); // Orange/Gold
              iconBg = const Color(0xFFFFFBEB);
            }

            if (isDark) {
              iconBg = iconColor.withOpacity(0.2);
            }

            final bool isUnread = i == 0; // Simulate unread for the first item for SaaS feel

            return Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
                  width: 1,
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left border accent stripe for unread
                    Container(
                      width: 4,
                      color: isUnread ? iconColor : Colors.transparent,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dynamic Icon
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: iconBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(iconData, size: 22, color: iconColor),
                            ),
                            const SizedBox(width: 14),
                            
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ann.titre,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (ann.dateRelative != null && ann.dateRelative!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                                          child: Text(
                                            ann.dateRelative!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    ann.message,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatBadge({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2B1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2B1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.4),
          ),
        ],
      ),
    );
  }

  String _getAppreciation(double avg) {
    if (avg >= 18.0) return 'Excellent';
    if (avg >= 16.0) return 'Très Bien';
    if (avg >= 14.0) return 'Bien';
    if (avg >= 12.0) return 'Assez Bien';
    if (avg >= 10.0) return 'Passable';
    return 'Ajourné';
  }
}