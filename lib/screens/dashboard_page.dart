import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'notifications_page.dart';

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

  // Data from API
  Map<String, dynamic> _stats = {
    'non_lues': 0,
    'cours_aujourdhui': 0,
    'evenements': 0,
    'impayes': 0,
  };
  List<dynamic> _urgentNotifications = [];
  List<dynamic> _planning = [];

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // First load what we have locally to show something quickly
    setState(() {
      _idStudent = prefs.getInt('idStudent') ?? 0;
      _matricule = prefs.getString('matricule') ?? '';
      _nom = prefs.getString('nom') ?? '';
      _prenom = prefs.getString('prenom') ?? '';
    });

    if (_idStudent != 0) {
      await _fetchDashboardData();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Utilisateur non connecté';
      });
    }
  }

  Future<void> _fetchDashboardData() async {
    final result = await _authService.getDashboardData(_idStudent);

    if (mounted) {
      setState(() {
        _isLoading = false;

        if (result['success'] == true) {
          final data = result['data'];

          // Update personal info with fresh DB data
          if (data['student'] != null) {
            _nom = data['student']['nom'] ?? _nom;
            _prenom = data['student']['prenom'] ?? _prenom;
            _matricule = data['student']['matricule'] ?? _matricule;
            _classe = data['student']['classe'] ?? '';
            _filiere = data['student']['filiere'] ?? '';
            _niveau = data['student']['niveau'] ?? '';
          }

          if (data['stats'] != null) {
            _stats = data['stats'];
          }

          if (data['urgent_notifications'] != null) {
            _urgentNotifications = data['urgent_notifications'];
          }

          if (data['planning'] != null) {
            _planning = data['planning'];
          }
        } else {
          _errorMessage =
              result['message'] ?? 'Erreur lors du chargement des données';
        }
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all saved data

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // --- UI Builders ---

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFFF4B41A) : const Color(0xFF94A3B8),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFFF4B41A)
                : const Color(0xFFCBD5E1),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        tileColor: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        onTap: onTap ?? () {},
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentNotification({
    required String badgeText,
    required Color badgeColor,
    required String date,
    required String title,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                date,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanningItem({
    required String startTime,
    required String endTime,
    required String title,
    required String subtitle,
    required String type,
    required Color lineColor,
    required Color typeColor,
    required Color typeBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                startTime,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                endTime,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: typeBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              type,
              style: TextStyle(
                color: typeColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
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
        automaticallyImplyLeading: false,
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      endDrawer: Drawer(
        backgroundColor: const Color(0xFF203B68),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.shield,
                            color: Color(0xFF203B68),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'OSBT NOTIFY',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildDrawerItem(
                icon: Icons.window_outlined,
                title: 'Tableau de bord',
                isSelected: true,
              ),
              _buildDrawerItem(
                icon: Icons.notifications_none,
                title: 'Notifications',
                onTap: () {
                  Navigator.pop(context); // Close Drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                },
              ),
              _buildDrawerItem(
                icon: Icons.calendar_today_outlined,
                title: 'Planning',
              ),
              _buildDrawerItem(
                icon: Icons.event_note_outlined,
                title: 'Événements',
              ),
              _buildDrawerItem(
                icon: Icons.credit_card_outlined,
                title: 'Paiement',
              ),
              const Spacer(),
              _buildDrawerItem(
                icon: Icons.login_outlined,
                title: 'Se déconnecter',
                onTap: _logout,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF203B68)),
            )
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
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
                      _fetchDashboardData();
                    },
                    child: const Text(
                      'Réessayer',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Bonjour, $_prenom 👋',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_filiere.isNotEmpty ? _filiere : "Filière inconnue"} — ${_niveau.isNotEmpty ? _niveau : "Niveau inconnu"} —\n$_classe',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Stats Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Non lues',
                            icon: Icons.notifications_none,
                            value: _stats['non_lues'].toString(),
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            title: "Cours\naujourd'hui",
                            icon: Icons.calendar_month_outlined,
                            value:
                                _stats['cours_aujourdhui']?.toString() ?? '0',
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Événements',
                            icon: Icons.event_note_outlined,
                            value: _stats['evenements'].toString(),
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Impayés',
                            icon: Icons.credit_card_outlined,
                            value: _stats['impayes'].toString(),
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Urgent Notifications
                    if (_urgentNotifications.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBEAEA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 22,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Notifications urgentes',
                                  style: TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ..._urgentNotifications.map((notif) {
                              Color badgeColor = const Color(0xFF3B82F6);
                              String badgeText = notif['categorie'] ?? 'Info';
                              if (badgeText.toLowerCase().contains('examen'))
                                badgeColor = const Color(0xFFF59E0B);
                              else if (badgeText.toLowerCase().contains(
                                'urgent',
                              ))
                                badgeColor = const Color(0xFFDC2626);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildUrgentNotification(
                                  badgeText: badgeText,
                                  badgeColor: badgeColor,
                                  date: notif['date_formattee'] ?? '',
                                  title: notif['titre'] ?? '',
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Planning du jour
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.access_time,
                                    color: Color(0xFF64748B),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Planning du jour',
                                    style: TextStyle(
                                      color: Color(0xFF1E293B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const Text(
                                'Voir tout',
                                style: TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_planning.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'Aucun cours programmé pour aujourd\'hui',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          else
                            ..._planning.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildPlanningItem(
                                  startTime: item['startTime'] ?? '',
                                  endTime: item['endTime'] ?? '',
                                  title: item['title'] ?? '',
                                  subtitle: item['subtitle'] ?? '',
                                  type: item['type'] ?? 'COURS',
                                  lineColor: const Color(0xFFF4B41A),
                                  typeColor: const Color(0xFF3B82F6),
                                  typeBgColor: const Color(0xFFDBEAFE),
                                ),
                              );
                            }).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32), // Bottom padding
                  ],
                ),
              ),
            ),
    );
  }
}
