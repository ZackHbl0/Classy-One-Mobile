import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../widgets/screen_header.dart';

class PlanningPage extends StatefulWidget {
  final DateTime? initialDate;

  const PlanningPage({super.key, this.initialDate});

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  bool _isLoading = true;
  final AuthService _authService = AuthService();

  List<dynamic> _allClasses = [];

  // 1 = Monday, 2 = Tuesday, ..., 7 = Sunday (Dart's DateTime.weekday)
  late int _selectedDayOfWeek;

  static const List<String> _dayLabels = [
    'LUN',
    'MAR',
    'MER',
    'JEU',
    'VEN',
    'SAM',
    'DIM',
  ];
  static const List<String> _dayFullNames = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  @override
  void initState() {
    super.initState();
    // Default to today's weekday (or initialDate if passed from dashboard)
    final seed = widget.initialDate ?? DateTime.now();
    _selectedDayOfWeek = seed.weekday; // 1 = Monday … 7 = Sunday
    _fetchTimetable();
  }

  Future<void> _fetchTimetable() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    int idStudent = prefs.getInt('idStudent') ?? 0;
    if (idStudent == 0) {
      idStudent = int.tryParse(prefs.getString('idStudent') ?? '') ?? 0;
    }

    if (idStudent == 0) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: ID étudiant introuvable.')),
        );
      }
      return;
    }

    final result = await _authService.getPlanning(idStudent);

    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _allClasses = result['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _allClasses = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur API: ${result['message'] ?? "Inconnu"}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Filter by weekday — shows all entries whose `date` falls on the selected weekday,
  /// regardless of the calendar week. This gives a "recurring" weekly timetable feel.
  List<dynamic> _getClassesForSelectedDay() {
    if (_allClasses.isEmpty) return [];

    final String selectedDayName = _dayFullNames[_selectedDayOfWeek - 1];

    final filtered = _allClasses.where((item) {
      // 1. Check for 'jour' field (New preferred system: 'Lundi', 'Mardi'...)
      if (item['jour'] != null && item['jour'].toString().isNotEmpty) {
        return item['jour'].toString().toLowerCase() ==
            selectedDayName.toLowerCase();
      }

      // 2. Fallback to legacy 'date' parsing (Calculates weekday from specific date)
      if (item['date'] == null) return false;
      try {
        final raw = item['date'].toString().split('T').first;
        final date = DateTime.parse(raw);
        return date.weekday == _selectedDayOfWeek;
      } catch (_) {
        return false;
      }
    }).toList();

    // Sort by start time
    filtered.sort((a, b) {
      final aTime = (a['check_in'] ?? '00:00:00').toString();
      final bTime = (b['check_in'] ?? '00:00:00').toString();
      return aTime.compareTo(bTime);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = const Color(0xFF203B68);
    final todaysClasses = _getClassesForSelectedDay();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1E241E)
          : const Color(0xFFF6F7F2),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ScreenHeader(title: 'Emploi du temps'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Static Weekday Tabs ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: List.generate(7, (index) {
                  final dayIndex = index + 1; // 1=Mon … 7=Sun
                  final isSelected = dayIndex == _selectedDayOfWeek;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedDayOfWeek = dayIndex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryBlue
                              : (isDark
                                    ? const Color(0xFF2A322A)
                                    : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            else
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                              ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _dayLabels[index],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                        ? Colors.white54
                                        : Colors.grey[600]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── Selected Day Full Name ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                _dayFullNames[_selectedDayOfWeek - 1],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),

            // ── Timeline ─────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchTimetable,
                      child: todaysClasses.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                10,
                                20,
                                100,
                              ),
                              itemCount: todaysClasses.length,
                              itemBuilder: (context, index) =>
                                  _buildTimelineCard(
                                    todaysClasses[index],
                                    isDark,
                                  ),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Timeline Card (unchanged design) ────────────────────────────────────────
  Widget _buildTimelineCard(dynamic classData, bool isDark) {
    const accentBlue = Color(0xFF708C70);

    final matiere = classData['matiere'] ?? 'Cours';
    final salle = classData['salle'] ?? 'Salle Non Spécifiée';
    final professeur = classData['professeur_name'] ?? 'Prof. Non Assigné';

    String format(String t) => t.length >= 5 ? t.substring(0, 5) : t;
    final startTime = format(classData['check_in'] ?? '00:00:00');
    final endTime = format(classData['check_out'] ?? '00:00:00');

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time column
            SizedBox(
              width: 65,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    startTime,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    endTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Vertical accent bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              width: 3,
              decoration: BoxDecoration(
                color: accentBlue.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // Content card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A322A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      matiere,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF2A322A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: isDark ? Colors.white54 : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            professeur,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: isDark ? Colors.white54 : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            salle,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
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
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_busy, color: Colors.grey, size: 80),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun cours ce jour',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Profitez de votre temps libre !',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black38, fontSize: 14),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
