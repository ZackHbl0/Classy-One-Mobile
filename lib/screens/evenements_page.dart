import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../widgets/screen_header.dart';
import '../models/event_model.dart';
import 'event_detail_page.dart';
import '../widgets/custom_sidebar.dart';

class EvenementsPage extends StatefulWidget {
  const EvenementsPage({super.key});

  @override
  State<EvenementsPage> createState() => _EvenementsPageState();
}

class _EvenementsPageState extends State<EvenementsPage> {
  List<EventModel> _allEvents = [];
  List<EventModel> _filteredEvents = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedCategory = 'Tout';
  final AuthService _authService = AuthService();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Tout', 'icon': Icons.check},
    {'name': 'Académique', 'icon': Icons.school_outlined},
    {'name': 'Sports', 'icon': Icons.sports_soccer_outlined},
    {'name': 'Clubs', 'icon': Icons.groups_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _fetchEvenements();
  }

  Future<void> _fetchEvenements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final prefs = await SharedPreferences.getInstance();
    final idStudent = prefs.getInt('idStudent') ?? 0;

    final result = await _authService.getEvenements(
      idStudent,
      category: 'Tout',
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          final List<dynamic> data = result['data'] ?? [];
          _allEvents = data.map((e) => EventModel.fromJson(e)).toList();
          for (var e in _allEvents) {
            print('DEBUG_CAT: "${e.title}" -> "${e.category}"');
          }
          _filterEvents(_selectedCategory); // apply initial filter
        } else {
          _errorMessage = result['message'] ?? 'Erreur lors du chargement';
        }
      });
    }
  }

  String _normalizeCategory(String cat) {
    return cat.toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .trim();
  }

  void _filterEvents(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'Tout') {
        _filteredEvents = _allEvents;
      } else {
        final normSelected = _normalizeCategory(category);
        _filteredEvents = _allEvents
            .where((e) => _normalizeCategory(e.category) == normSelected)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E241E) : const Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bgColor,
      drawer: const CustomSidebar(currentRoute: '/evenements'),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: const ScreenHeader(
                title: 'Événements',
                showBackButton: false,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? _buildShimmerEffect()
                  : _errorMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilterChips(),
                          const SizedBox(height: 24),
                          _buildEventsSections(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF10B981);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _categories.map((catInfo) {
          final cat = catInfo['name'] as String;
          final icon = catInfo['icon'] as IconData;
          final isSelected = _selectedCategory == cat;

          return GestureDetector(
            onTap: () => _filterEvents(cat),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor
                    : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
                borderRadius: BorderRadius.circular(24),
                boxShadow: !isDark && !isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cat,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF1F2937)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeaturedEventCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF10B981),
              Color(0xFF065F46),
            ], // Emerald to dark green
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative dots (right side)
            Positioned(
              right: 0,
              top: 0,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: List.generate(
                  9,
                  (index) => Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),

            // Robot graphic simulation
            Positioned(
              right: -10,
              bottom: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.code,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: Color(0xFF065F46),
                      size: 50,
                    ),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFBBF24),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'À la une',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Forum IA 2026',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "L'avenir de l'intelligence artificielle",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '23 Juil. 2026',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Casablanca',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Voir les détails',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF065F46),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF065F46),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.favorite_border_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Intéressé',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF1F2937),
            ),
          ),
          Row(
            children: [
              Text(
                'Voir tout',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF10B981),
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventsSections() {
    if (_filteredEvents.isEmpty) {
      return _buildEmptyState();
    }

    // Split events randomly or by date if possible, but here we just split list for demonstration
    // Since API returns events without strict "Today" classification in the current logic,
    // we simulate the groups for UI fidelity.
    final List<EventModel> todayEvents = _filteredEvents.take(1).toList();
    final List<EventModel> weekEvents = _filteredEvents.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (todayEvents.isNotEmpty) ...[
          ...todayEvents.map((e) => _buildSleekEventCard(e, isToday: true)),
        ],
        if (weekEvents.isNotEmpty) ...[
          ...weekEvents.map((e) => _buildSleekEventCard(e)),
        ],
      ],
    );
  }

  Widget _buildSleekEventCard(EventModel event, {bool isToday = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dayStr = event.dateEvent != null
        ? DateFormat('dd').format(event.dateEvent!)
        : '--';
    final monthStr = event.dateEvent != null
        ? DateFormat('MMM yyyy', 'fr_FR').format(event.dateEvent!)
        : '';
    final timeStr = '09:00 - 11:00'; // Placeholder time

    // Style logic based on index or category
    // We simulate variations since category data might not match perfectly
    Color iconBgColor = const Color(0xFFEEF2FF); // Blueish
    Color iconColor = const Color(0xFF4F46E5);
    Color tagBgColor = const Color(0xFFEEF2FF);
    Color tagColor = const Color(0xFF4F46E5);
    IconData cardIcon = Icons.code_rounded;
    String tagText = event.category;

    if (isToday) {
      iconBgColor = const Color(0xFFDCFCE7);
      iconColor = const Color(0xFF10B981);
      tagBgColor = const Color(0xFFDCFCE7);
      tagColor = const Color(0xFF10B981);
      cardIcon = Icons.school_rounded;
      tagText = "Aujourd'hui";
    } else if (event.category.toLowerCase().contains('sport')) {
      iconBgColor = const Color(0xFFF3E8FF);
      iconColor = const Color(0xFF9333EA);
      tagBgColor = const Color(0xFFF3E8FF);
      tagColor = const Color(0xFF9333EA);
      cardIcon = Icons.sports_soccer_rounded;
    } else if (event.category.toLowerCase().contains('club')) {
      iconBgColor = const Color(0xFFFFEDD5);
      iconColor = const Color(0xFFEA580C);
      tagBgColor = const Color(0xFFFFEDD5);
      tagColor = const Color(0xFFEA580C);
      cardIcon = Icons.groups_rounded;
    } else {
      cardIcon = Icons.school_rounded;
    }

    if (isDark) {
      iconBgColor = iconColor.withOpacity(0.2);
      tagBgColor = tagColor.withOpacity(0.2);
    }

    return GestureDetector(
      onTap: () async {
        final bool? registered = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailPage(event: event),
          ),
        );
        if (registered == true) {
          _fetchEvenements();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
          border: isToday && !isDark
              ? const Border(
                  left: BorderSide(color: Color(0xFF10B981), width: 4),
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Event Image or fallback Icon
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                    ? Image.network(
                        event.imageUrl!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(cardIcon, color: iconColor, size: 32),
                        ),
                        loadingBuilder: (_, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: iconColor,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(cardIcon, color: iconColor, size: 32),
                      ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tagBgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tagText,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: tagColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF10B981),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF10B981),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: Color(0xFF64748B),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$dayStr $monthStr • $timeStr',
                          style: GoogleFonts.poppins(
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Stacked Avatars
                        Row(
                          children: [
                            _buildStackedAvatar(0),
                            _buildStackedAvatar(1),
                            _buildStackedAvatar(2),
                            Container(
                              width: 24,
                              height: 24,
                              transform: Matrix4.translationValues(
                                -16.0,
                                0.0,
                                0.0,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '+${event.participants}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Action Button
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              if (!isToday) ...[
                                Text(
                                  'Voir',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: iconColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: iconColor,
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
      ),
    );
  }

  Widget _buildStackedAvatar(int index) {
    return Container(
      width: 24,
      height: 24,
      transform: Matrix4.translationValues(index * -8.0, 0.0, 0.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.person, size: 14, color: Color(0xFF94A3B8)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedCategory == 'Tout'
                ? 'Aucun événement prévu pour le moment.'
                : 'Aucun événement disponible dans la catégorie "$_selectedCategory".',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: const Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        height: 140,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
