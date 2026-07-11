import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grade.dart';
import '../services/auth_service.dart';
import '../widgets/screen_header.dart';
import '../widgets/custom_sidebar.dart';

/// Professional grades view using an Elite Expandable Card architecture
class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final AuthService _authService = AuthService();

  GradeSummary? _summary;
  List<Grade> _grades = [];
  final Map<String, double> _courseAverages = {};

  // Data grouping: Semester -> Course -> Evaluation Type -> Grade
  final Map<String, Map<String, Map<String, Grade>>> _groupedGrades = {};

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  void _processGrades() {
    _groupedGrades.clear();
    for (var grade in _grades) {
      // Default to Semestre 1 if not provided
      final semester = grade.semester?.isNotEmpty == true
          ? grade.semester!
          : 'Semestre 1';
      final course = grade.courseName;
      final type = grade.typeEvaluation ?? 'Autre';

      _groupedGrades.putIfAbsent(semester, () => {});
      _groupedGrades[semester]!.putIfAbsent(course, () => {});
      _groupedGrades[semester]![course]![type] = grade;
    }
  }

  Future<void> _loadGrades() async {
    final prefs = await SharedPreferences.getInstance();
    final idStudent = prefs.getInt('idStudent') ?? 0;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (idStudent == 0) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    try {
      final result = await _authService.getGrades(idStudent);

      if (mounted) {
        setState(() {
          _isLoading = false;

          if (result['success'] == true) {
            // Parse summary
            if (result['statistics'] != null &&
                result['statistics'] is Map<String, dynamic>) {
              _summary = GradeSummary.fromJson(
                result['statistics'] as Map<String, dynamic>,
              );
            }

            // Parse course averages
            if (result['grouped_by_course'] != null &&
                result['grouped_by_course'] is List) {
              for (var courseData in result['grouped_by_course']) {
                if (courseData is Map<String, dynamic>) {
                  final courseName =
                      courseData['subject_name']?.toString() ??
                      courseData['cours']?.toString() ??
                      '';
                  final averageStr = courseData['average']?.toString() ?? '0';
                  _courseAverages[courseName] =
                      double.tryParse(averageStr) ?? 0.0;
                }
              }
            }

            // Parse grades
            final gradesData = result['data'];
            if (gradesData != null && gradesData is List) {
              _grades = gradesData.map((e) => Grade.fromJson(e as Map<String, dynamic>)).toList();
              _processGrades();
            }
            _errorMessage = null;
          } else {
            _errorMessage =
                result['message']?.toString() ??
                'Erreur de chargement des notes';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur de traitement: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E241E) : const Color(0xFFF6F7F2);
    final textColor = isDark ? Colors.white : const Color(0xFF2A322A);

    return Scaffold(
      backgroundColor: bgColor,
      drawer: const CustomSidebar(currentRoute: '/grades'),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 32, 20, 0),
            child: ScreenHeader(title: 'Mes Notes', showBackButton: false),
          ),
          Expanded(
            child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF708C70)),
            )
          : _errorMessage != null
          ? _buildErrorState()
          : _grades.isEmpty
          ? _buildEmptyState()
          : _buildGradesContent(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 20),
          Text(_errorMessage ?? 'Erreur', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadGrades,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('Aucune note disponible', style: TextStyle(fontSize: 18)),
    );
  }

  Widget _buildGradesContent(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadGrades,
      color: const Color(0xFF8B5CF6),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // Hero card
          if (_summary != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildHeroCard(isDark),
              ),
            ),
          
          // Summary Grid
          if (_summary != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildSummaryGrid(isDark),
              ),
            ),

          // Semesters List
          SliverList(
            delegate: SliverChildListDelegate(_buildSemesterSections(isDark)),
          ),

          // Conseil du jour
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              child: _buildTipCard(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B5CF6), // Purple
            Color(0xFF6D28D9), // Darker purple
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.4),
            blurRadius: 16,
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
                'MOYENNE GÉNÉRALE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _summary!.status.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _summary!.moyenneGenerale.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6.0, left: 4),
                child: Text(
                  '/ 20',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              // Icon graphic to simulate 3D illustration
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.circle, color: Color(0xFF10B981), size: 10),
              const SizedBox(width: 8),
              Text(
                '${_summary!.status} ! Continue tes efforts',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeroStatItem(Icons.menu_book, '${_summary!.coursesEvalues}', 'Évalués'),
              _buildHeroStatItem(Icons.layers, '${_summary!.totalCourses}', 'Total'),
              _buildHeroProgressItem('${((_summary!.coursesEvalues / (_summary!.totalCourses > 0 ? _summary!.totalCourses : 1)) * 100).toInt()}%', 'Progression'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroProgressItem(String value, String label) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: (_summary!.coursesEvalues / (_summary!.totalCourses > 0 ? _summary!.totalCourses : 1)),
                backgroundColor: Colors.white.withOpacity(0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildSummaryCard(Icons.menu_book, '${_summary!.coursesEvalues}', 'Matières\névaluées', const Color(0xFF8B5CF6), isDark),
          const SizedBox(width: 12),
          _buildSummaryCard(Icons.show_chart, _summary!.moyenneGenerale.toStringAsFixed(2), 'Moyenne\ngénérale', const Color(0xFF10B981), isDark),
          const SizedBox(width: 12),
          _buildSummaryCard(Icons.emoji_events, _summary!.status, 'Niveau\nactuel', const Color(0xFFF59E0B), isDark),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(IconData icon, String value, String label, Color color, bool isDark) {
    return Container(
      width: 135,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E241E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11, height: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSemesterSections(bool isDark) {
    final semesters = _groupedGrades.keys.toList()..sort();
    return semesters.map((semester) {
      final courses = _groupedGrades[semester]!;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 12),
              child: Row(
                children: [
                  const Icon(Icons.bookmark, color: Color(0xFF8B5CF6), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    semester.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8B5CF6),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            ...courses.entries.map((courseEntry) {
              return _buildExpandableCourseCard(courseEntry.key, courseEntry.value, isDark);
            }),
          ],
        ),
      );
    }).toList();
  }

  Color _getGradeColor(double note) {
    if (note >= 12) return const Color(0xFF10B981); // Green
    if (note >= 10) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFFEF4444); // Red
  }

  String _getGradeStatus(double note) {
    if (note >= 16) return 'Excellent';
    if (note >= 14) return 'Très Bien';
    if (note >= 12) return 'Bien';
    if (note >= 10) return 'Passable';
    return 'Insuffisant';
  }

  IconData _getCourseIcon(String courseName) {
    final name = courseName.toLowerCase();
    if (name.contains('uml') || name.contains('dev') || name.contains('react') || name.contains('prog')) return Icons.code;
    if (name.contains('algo') || name.contains('struct') || name.contains('data')) return Icons.storage;
    if (name.contains('math') || name.contains('stat')) return Icons.calculate;
    if (name.contains('eco') || name.contains('mana')) return Icons.business;
    return Icons.book;
  }

  Grade? _findGrade(Map<String, Grade> gradesByType, List<String> possibleKeys) {
    for (var key in possibleKeys) {
      if (gradesByType.containsKey(key)) return gradesByType[key];
    }
    for (var entry in gradesByType.entries) {
      if (possibleKeys.any((k) => k.toLowerCase() == entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return null;
  }

  Widget _buildExpandableCourseCard(String rawCourseName, Map<String, Grade> gradesByType, bool isDark) {
    final courseName = rawCourseName.split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
    final courseAvg = _courseAverages[rawCourseName] ?? 0.0;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final bgColor = isDark ? const Color(0xFF2A322A) : Colors.white;
    final primaryColor = const Color(0xFF8B5CF6);

    final avgColor = _getGradeColor(courseAvg);
    final avgStatus = _getGradeStatus(courseAvg);

    final ctrl1 = _findGrade(gradesByType, ['Contrôle 1', 'Ctrl 1']);
    final ctrl2 = _findGrade(gradesByType, ['Contrôle 2', 'Ctrl 2']);
    final tp = _findGrade(gradesByType, ['TP', 'Projet', 'TP/Projet', 'TP/Proj']);
    final examen = _findGrade(gradesByType, ['Examen Final', 'Examen']);

    final String profName = (gradesByType.values.isNotEmpty && gradesByType.values.first.professor != null && gradesByType.values.first.professor!.isNotEmpty)
        ? gradesByType.values.first.professor!
        : 'Prof. Anonyme';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Colors.grey[400],
          collapsedIconColor: Colors.grey[400],
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getCourseIcon(courseName), color: primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profName,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: avgColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      courseAvg > 0 ? courseAvg.toStringAsFixed(2) : '-',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: avgColor),
                    ),
                    if (courseAvg > 0)
                      Text(
                        avgStatus,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: avgColor),
                      ),
                  ],
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Stack(
                children: [
                  Positioned(
                    left: 25,
                    top: 0,
                    bottom: 20,
                    child: Container(
                      width: 2,
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 56, right: 8, top: 16, bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildEvaluationItem('Ctrl 1', ctrl1, isDark),
                            _buildEvaluationItem('Ctrl 2', ctrl2, isDark),
                            _buildEvaluationItem('TP/Proj', tp, isDark),
                            _buildEvaluationItem('Examen', examen, isDark),
                          ],
                        ),
                      ),
                      if (courseAvg > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 48),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: avgColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Moyenne de la matière', style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          courseAvg.toStringAsFixed(2),
                                          style: TextStyle(color: avgColor, fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        const Text(' / 20', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: avgColor.withOpacity(0.2)),
                                ),
                                child: Text(
                                  avgStatus,
                                  style: TextStyle(color: avgColor, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationItem(String label, Grade? grade, bool isDark) {
    final val = grade != null ? grade.note : -1.0;
    final isFailing = val >= 0 && val < 10.0;
    final color = val < 0 ? (isDark ? Colors.grey[700] : Colors.grey[300])! : (isFailing ? const Color(0xFFEF4444) : (isDark ? Colors.white : const Color(0xFF111827)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          val >= 0 ? val.toStringAsFixed(2) : '-',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTipCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF8B5CF6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Conseil du jour',
                  style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Travaille régulièrement et révise les chapitres clés pour améliorer tes résultats.',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Color(0xFF8B5CF6)),
        ],
      ),
    );
  }
}
