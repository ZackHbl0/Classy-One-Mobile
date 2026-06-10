import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grade.dart';
import '../services/auth_service.dart';

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
      final semester = grade.semester?.isNotEmpty == true ? grade.semester! : 'Semestre 1';
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
            if (result['statistics'] != null && result['statistics'] is Map<String, dynamic>) {
              _summary = GradeSummary.fromJson(result['statistics'] as Map<String, dynamic>);
            }

            // Parse course averages
            if (result['grouped_by_course'] != null && result['grouped_by_course'] is List) {
              for (var courseData in result['grouped_by_course']) {
                if (courseData is Map<String, dynamic>) {
                  final courseName = courseData['subject_name']?.toString() ?? courseData['cours']?.toString() ?? '';
                  final averageStr = courseData['average']?.toString() ?? '0';
                  _courseAverages[courseName] = double.tryParse(averageStr) ?? 0.0;
                }
              }
            }

            // Parse grades
            final gradesData = result['data'];
            if (gradesData != null && gradesData is List) {
              _grades = gradesData
                  .where((g) => g is Map<String, dynamic>)
                  .map((g) => Grade.fromJson(g as Map<String, dynamic>))
                  .toList();
            } else {
              _grades = [];
            }

            _processGrades();
            _errorMessage = null;
          } else {
            _errorMessage = result['message']?.toString() ?? 'Erreur de chargement des notes';
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
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Mes Notes',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: textColor),
        ),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _errorMessage != null
              ? _buildErrorState()
              : _grades.isEmpty
                  ? _buildEmptyState()
                  : _buildGradesContent(isDark),
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
      color: const Color(0xFF6366F1),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Summary gradient header
          if (_summary != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildCompactGradientHeader(isDark),
              ),
            ),
          
          // Semester Sections
          SliverList(
            delegate: SliverChildListDelegate(_buildSemesterSections(isDark)),
          ),
          
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildCompactGradientHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _summary!.statusColor,
            _summary!.statusColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _summary!.statusColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MOYENNE GÉNÉRALE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _summary!.status.toUpperCase(),
                  style: TextStyle(
                    color: _summary!.statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _summary!.moyenneGenerale.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                ' / 20',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(Icons.assessment_outlined, '${_summary!.coursesEvalues}', 'Évalués'),
              Container(width: 1, height: 24, color: Colors.white30),
              _buildStatItem(Icons.school_outlined, '${_summary!.totalCourses}', 'Total'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  List<Widget> _buildSemesterSections(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final semesters = _groupedGrades.keys.toList()..sort();

    return semesters.map((semester) {
      final courses = _groupedGrades[semester]!;
      
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                semester.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: 1.2,
                ),
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

  Widget _buildExpandableCourseCard(String rawCourseName, Map<String, Grade> gradesByType, bool isDark) {
    // Format course name (capitalize each word)
    final courseName = rawCourseName.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');

    final courseAvg = _courseAverages[rawCourseName];
    final isAvgFailing = (courseAvg != null && courseAvg < 10.0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    // Map API types to specific UI columns
    final ctrl1 = _findGrade(gradesByType, ['Contrôle 1', 'Ctrl 1']);
    final ctrl2 = _findGrade(gradesByType, ['Contrôle 2', 'Ctrl 2']);
    final tp = _findGrade(gradesByType, ['TP', 'Projet', 'TP/Projet', 'TP/Proj']);
    final examen = _findGrade(gradesByType, ['Examen Final', 'Examen']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        // Remove the default borders added by ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Colors.grey[500],
          collapsedIconColor: Colors.grey[500],
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  courseName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                courseAvg != null ? courseAvg.toStringAsFixed(2) : '-',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isAvgFailing ? Colors.redAccent : textColor,
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.grey[200]),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildEvaluationItem('Ctrl 1', ctrl1, isDark),
                      _buildEvaluationItem('Ctrl 2', ctrl2, isDark),
                      _buildEvaluationItem('TP/Proj', tp, isDark),
                      _buildEvaluationItem('Examen', examen, isDark),
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

  Widget _buildEvaluationItem(String label, Grade? grade, bool isDark) {
    final isFailing = grade != null && grade.note < 10.0;
    
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
        const SizedBox(height: 4),
        Text(
          grade != null ? grade.note.toStringAsFixed(2) : '-',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isFailing 
                ? Colors.redAccent 
                : (isDark ? Colors.white : const Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }
}
