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
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;

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
    super.dispose();
  }

  Future<void> _fetchCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch token from SharedPreferences (same storage used by AuthService)
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      // Call our new POST endpoint using centralized baseUrl
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
        'Janv.',
        'Févr.',
        'Mars',
        'Avril',
        'Mai',
        'Juin',
        'Juil.',
        'Août',
        'Sept.',
        'Oct.',
        'Nov.',
        'Déc.',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return 'N/A';
    }
  }

  Color _getGradientColorForIndex(int index) {
    // Array of beautiful gradient color pairs for diversity
    final gradients = [
      const [Color(0xFF818CF8), Color(0xFF6366F1)], // Indigo
      const [Color(0xFF60A5FA), Color(0xFF3B82F6)], // Blue
      const [Color(0xFF34D399), Color(0xFF10B981)], // Emerald
      const [Color(0xFFFBBF24), Color(0xFFF59E0B)], // Amber
      const [Color(0xFFF87171), Color(0xFFEF4444)], // Red
      const [Color(0xFFA78BFA), Color(0xFF8B5CF6)], // Violet
    ];
    return (gradients[index % gradients.length] as List<Color>)[0];
  }

  Color _getGradientColorSecondaryForIndex(int index) {
    final gradients = [
      const [Color(0xFF818CF8), Color(0xFF6366F1)], // Indigo
      const [Color(0xFF60A5FA), Color(0xFF3B82F6)], // Blue
      const [Color(0xFF34D399), Color(0xFF10B981)], // Emerald
      const [Color(0xFFFBBF24), Color(0xFFF59E0B)], // Amber
      const [Color(0xFFF87171), Color(0xFFEF4444)], // Red
      const [Color(0xFFA78BFA), Color(0xFF8B5CF6)], // Violet
    ];
    return (gradients[index % gradients.length] as List<Color>)[1];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              )
            : _errorMessage != null
            ? _buildErrorState()
            : _courses.isEmpty
            ? _buildEmptyState()
            : _buildCoursesList(isDark),
      ),
    );
  }

  Widget _buildCoursesList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _fetchCourses,
      color: const Color(0xFF6366F1),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium Header
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Match the exact header styling used by “Mes Documents”
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: ScreenHeader(title: 'Mes Cours'),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '${_courses.length} cours disponible${_courses.length != 1 ? 's' : ''}',
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
              ),
            ),
          ),
          // Course Cards
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final course = _courses[index];

                // Micro-animation for item entry
                final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      (index / _courses.length).clamp(0.0, 1.0),
                      1.0,
                      curve: Curves.easeOut,
                    ),
                  ),
                );

                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation,
                    child: _buildPremiumCourseCard(course, index, isDark),
                  ),
                );
              }, childCount: _courses.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCourseCard(dynamic course, int index, bool isDark) {
    final primaryGradientColor = _getGradientColorForIndex(index);
    final secondaryGradientColor = _getGradientColorSecondaryForIndex(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.15)
                : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.05), width: 1)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            // Smart content routing based on file extension
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Gradient Header with Accent Bar
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryGradientColor, secondaryGradientColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Subtle accent pattern background
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  course['title'] ?? 'Nouveau Cours',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    overflow: TextOverflow.ellipsis,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                          // Decorative bottom accent
                          Container(
                            height: 4,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Premium Card Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Description
                    if (course['description'] != null &&
                        course['description'].toString().isNotEmpty) ...[
                      Text(
                        course['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    // Metadata Row - Professor & Date
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Professor Info
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        primaryGradientColor.withOpacity(0.8),
                                        secondaryGradientColor.withOpacity(0.8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Professeur',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.grey[500],
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        course['professor_name'] ?? 'N/A',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF1E293B),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Divider
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Container(
                              width: 1,
                              height: 24,
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey[300],
                            ),
                          ),
                          // Date Info
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.calendar_month_rounded,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey[600],
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Publié',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.grey[500],
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDate(course['created_at']),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                color: const Color(0xFF6366F1).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.class_outlined,
                size: 80,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun cours disponible',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
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
                backgroundColor: const Color(0xFF6366F1),
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
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
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
                backgroundColor: const Color(0xFF6366F1),
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
