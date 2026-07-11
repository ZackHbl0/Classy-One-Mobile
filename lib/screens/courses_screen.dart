import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/screen_header.dart';
import '../utils/content_router.dart';
import '../config/constants.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _courses = [];
  List<dynamic> _filteredCourses = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fetchCourses();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredCourses = _courses.where((course) {
        final title = (course['title'] ?? '').toString().toLowerCase();
        final description = (course['description'] ?? '').toString().toLowerCase();
        return title.contains(_searchQuery) || description.contains(_searchQuery);
      }).toList();
    });
  }

  Future<void> _fetchCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/courses'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _courses = data['data'] ?? [];
            _filteredCourses = _courses;
            _isLoading = false;
          });
          _animationController.forward();
        } else {
          setState(() {
            _errorMessage =
                data['message'] ?? 'Erreur lors du chargement des cours';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Erreur serveur: Code ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Impossible de se connecter au serveur. Vérifiez votre connexion.';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      final date = DateTime.parse(isoString);
      final months = [
        'Janv.', 'Févr.', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juil.', 'Août', 'Sept.', 'Oct.', 'Nov.', 'Déc.',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return 'N/A';
    }
  }

  Map<String, dynamic> _getCourseBranding(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('c#') || lower.contains('c sharp')) {
      return {
        'category': 'Programmation',
        'color': const Color(0xFF34D399),
        'bgColor': const Color(0xFFE6F7F0),
        'iconText': 'C#',
      };
    } else if (lower.contains('react')) {
      return {
        'category': 'Frontend',
        'color': const Color(0xFF8B5CF6),
        'bgColor': const Color(0xFFF3E8FF),
        'iconText': 'React',
      };
    } else if (lower.contains('js') || lower.contains('javascript')) {
      return {
        'category': 'Frontend',
        'color': const Color(0xFFF59E0B),
        'bgColor': const Color(0xFFFEF3C7),
        'iconText': 'JS',
      };
    } else if (lower.contains('java') && !lower.contains('javascript')) {
      return {
        'category': 'Backend',
        'color': const Color(0xFFF43F5E),
        'bgColor': const Color(0xFFFFE4E6),
        'iconText': 'Java',
      };
    } else if (lower.contains('python')) {
      return {
        'category': 'Programmation',
        'color': const Color(0xFF3B82F6),
        'bgColor': const Color(0xFFEFF6FF),
        'iconText': 'Py',
      };
    }
    return {
      'category': 'Programmation',
      'color': const Color(0xFF34D399),
      'bgColor': const Color(0xFFE6F7F0),
      'iconText': title.length > 2
          ? title.substring(0, 2).toUpperCase()
          : title.toUpperCase(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1E241E) : const Color(0xFFF8F9FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 32.0, left: 20.0, right: 20.0, bottom: 24.0),
              child: ScreenHeader(title: 'Mes Cours'),
            ),
            // Subtitle
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_courses.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF34D399),
                    ),
                  ),
                  Text(
                    ' cours disponible${_courses.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white54
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20.0, vertical: 8.0),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A322A) : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: isDark
                      ? Border.all(
                          color: Colors.white.withOpacity(0.05), width: 1)
                      : Border.all(
                          color: Colors.grey.withOpacity(0.1), width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: isDark ? Colors.white54 : Colors.grey[400],
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un cours...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey[400],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        child: Icon(
                          Icons.close,
                          color: isDark ? Colors.white54 : Colors.grey[400],
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Main Content Area
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF708C70)),
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _filteredCourses.isEmpty
                          ? _buildEmptyState()
                          : _buildCoursesList(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _fetchCourses,
      color: const Color(0xFF708C70),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        physics: const BouncingScrollPhysics(),
        itemCount: _filteredCourses.length,
        itemBuilder: (context, index) {
          final course = _filteredCourses[index];

          final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                (index / _filteredCourses.length).clamp(0.0, 1.0),
                1.0,
                curve: Curves.easeOut,
              ),
            ),
          );

          return FadeTransition(
            opacity: animation,
            child: _buildModernCourseCard(course, index, isDark),
          );
        },
      ),
    );
  }

  Widget _buildModernCourseCard(
      dynamic course, int index, bool isDark) {
    final title = course['title'] ?? 'Nouveau Cours';
    final branding = _getCourseBranding(title);
    final categoryColor = branding['color'] as Color;
    final bgColor = isDark
        ? categoryColor.withOpacity(0.15)
        : (branding['bgColor'] as Color);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A322A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: isDark
            ? Border.all(
                color: Colors.white.withOpacity(0.05), width: 1)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            ContentRouter.routeContent(
              context,
              contentUrl: course['video_url'] ?? '',
              contentTitle: course['title'],
              onLoadingStart: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chargement du contenu...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Colorful Logo Box
                    Container(
                      width: 90,
                      height: 100,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: -10,
                            right: -10,
                            child: Icon(Icons.circle,
                                color: categoryColor.withOpacity(0.1),
                                size: 40),
                          ),
                          Positioned(
                            bottom: 10,
                            left: 10,
                            child: Icon(Icons.star,
                                color: categoryColor.withOpacity(0.15),
                                size: 16),
                          ),
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2A322A)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: categoryColor.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: branding['iconText'] == 'React'
                                ? Icon(Icons.science,
                                    color: categoryColor, size: 30)
                                : branding['iconText'] == 'Java'
                                    ? Icon(Icons.local_cafe,
                                        color: categoryColor, size: 28)
                                    : Text(
                                        branding['iconText'],
                                        style: TextStyle(
                                          color: categoryColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Right Content Area
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              branding['category'],
                              style: TextStyle(
                                color: categoryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Title
                          Text(
                            title,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // Description
                          Text(
                            course['description'] ??
                                'Aucune description disponible pour ce cours.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF64748B),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.15),
                ),
                const SizedBox(height: 12),

                // Bottom Metadata Row
                Row(
                  children: [
                    _buildMetaIcon(Icons.person_outline, isDark),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Professeur',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey[500],
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            course['professor_name'] ?? 'Inconnu',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        width: 1,
                        height: 24,
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.2),
                      ),
                    ),

                    _buildMetaIcon(
                        Icons.calendar_today_outlined, isDark),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Publié le',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white38
                                : Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          _formatDate(course['created_at']),
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 8),

                    // Action Arrow
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: isDark
                            ? null
                            : Border.all(
                                color: Colors.grey.withOpacity(0.2)),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: categoryColor,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaIcon(IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFF1F5F9),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 14,
        color: isDark ? Colors.white60 : const Color(0xFF64748B),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: const Color(0xFF708C70).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.class_outlined,
                size: 80,
                color: Color(0xFF708C70),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun cours disponible',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A322A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre professeur n\'a pas encore publié de cours pour votre classe.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchCourses,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF708C70),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: Colors.redAccent),
            const SizedBox(height: 20),
            Text(
              _errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchCourses,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF708C70),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
