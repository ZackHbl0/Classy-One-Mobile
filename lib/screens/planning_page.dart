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

  String _getMonthName(int month) {
    const months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    return months[month - 1];
  }

  Widget _buildMatiereIcon(String matiere) {
    final m = matiere.toLowerCase();
    Widget iconContent;
    
    if (m.contains('javascript') || m.contains('code') || m.contains('dev')) {
      iconContent = const Text('</>', style: TextStyle(color: Color(0xFF2A593E), fontWeight: FontWeight.bold, fontSize: 16));
    } else if (m.contains('sport') || m.contains('eps')) {
      iconContent = const Icon(Icons.directions_run, color: Color(0xFF2A593E), size: 20);
    } else if (m.contains('arab')) {
      iconContent = const Text('ض', style: TextStyle(color: Color(0xFF2A593E), fontWeight: FontWeight.bold, fontSize: 18));
    } else if (m.contains('php')) {
      iconContent = const Text('php', style: TextStyle(color: Color(0xFF2A593E), fontWeight: FontWeight.bold, fontSize: 14));
    } else {
      iconContent = Text(matiere.isNotEmpty ? matiere.substring(0, 1).toUpperCase() : 'C', style: const TextStyle(color: Color(0xFF2A593E), fontWeight: FontWeight.bold, fontSize: 18));
    }

    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: iconContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGreen = const Color(0xFF3BBE7A);
    final todaysClasses = _getClassesForSelectedDay();

    final now = DateTime.now();
    final selectedDate = now.subtract(Duration(days: now.weekday - _selectedDayOfWeek));
    final dateString = "${selectedDate.day} ${_getMonthName(selectedDate.month)} ${selectedDate.year}";

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E241E) : const Color(0xFFF9FAFB),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 10),
              child: const ScreenHeader(title: 'Emploi du temps', showBackButton: true),
            ),

            const SizedBox(height: 10),

            // ── Static Weekday Tabs ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: List.generate(7, (index) {
                  final dayIndex = index + 1; // 1=Mon … 7=Sun
                  final isSelected = dayIndex == _selectedDayOfWeek;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDayOfWeek = dayIndex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: isSelected ? const LinearGradient(
                            colors: [Color(0xFF3BBE7A), Color(0xFF2A9D60)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ) : null,
                          color: isSelected ? null : (isDark ? const Color(0xFF2A322A) : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: primaryGreen.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            else
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _dayLabels[index],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.grey[700]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── Date and Filter Header ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.calendar_today_outlined, color: Color(0xFF2A593E), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dayFullNames[_selectedDayOfWeek - 1],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateString,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Timeline ─────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchTimetable,
                      child: todaysClasses.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                              itemCount: todaysClasses.length,
                              itemBuilder: (context, index) => _buildTimelineCard(
                                todaysClasses[index],
                                isDark,
                                isLast: index == todaysClasses.length - 1,
                              ),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Timeline Card ────────────────────────────────────────
  Widget _buildTimelineCard(dynamic classData, bool isDark, {bool isLast = false}) {
    final primaryGreen = const Color(0xFF3BBE7A);

    final matiere = classData['matiere'] ?? 'Cours';
    final salle = classData['salle'] ?? 'Salle Non Spécifiée';
    final professeur = classData['professeur_name'] ?? 'Prof. Non Assigné';

    String format(String t) => t.length >= 5 ? t.substring(0, 5) : t;
    final startTime = format(classData['check_in'] ?? '00:00:00');
    final endTime = format(classData['check_out'] ?? '00:00:00');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time column
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 24),
                Text(
                  startTime,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  endTime,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),

          // Vertical line with dot
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 28,
                    bottom: -20, // extend to next item
                    child: Container(
                      width: 2,
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                    ),
                  ),
                Positioned(
                  top: 28,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A322A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left colored border
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                  
                  // Card Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _buildMatiereIcon(matiere),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  matiere,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 14,
                                      color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        professeur,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        salle,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // "Cours" badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Cours',
                              style: TextStyle(
                                color: Color(0xFF3BBE7A),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
