import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/auth_service.dart';
import '../widgets/screen_header.dart';
import '../models/event_model.dart';
import 'event_detail_page.dart';
import 'package:intl/intl.dart';

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

  final List<String> _categories = ['Tout', 'Académique', 'Sports', 'Clubs'];

  @override
  void initState() {
    super.initState();
    _fetchEvenements();
  }

  Future<void> _fetchEvenements({String? category}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      if (category != null) _selectedCategory = category;
    });

    final prefs = await SharedPreferences.getInstance();
    final idStudent = prefs.getInt('idStudent') ?? 0;

    final result = await _authService.getEvenements(
      idStudent,
      category: _selectedCategory,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          final List<dynamic> data = result['data'] ?? [];
          _allEvents = data.map((e) => EventModel.fromJson(e)).toList();
          _filteredEvents = _allEvents;
        } else {
          _errorMessage = result['message'] ?? 'Erreur lors du chargement';
        }
      });
    }
  }

  void _filterEvents(String category) {
    if (_selectedCategory == category && !_isLoading) return;
    _fetchEvenements(category: category);
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF203B68);
    const slateGrey = Color(0xFF64748B);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                  ScreenHeader(title: 'events.title'.tr()),
                  const SizedBox(height: 16),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (val) => _filterEvents(cat),
                            selectedColor: primaryBlue.withOpacity(0.15),
                            checkmarkColor: primaryBlue,
                            labelStyle: TextStyle(
                              color: isSelected ? primaryBlue : slateGrey,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                            backgroundColor: isDark
                                ? Colors.white10
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? primaryBlue
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Events List
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
                  : _filteredEvents.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filteredEvents.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _filteredEvents.length)
                          return const SizedBox(height: 30);
                        return _buildSleekEventCard(_filteredEvents[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
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
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 16,
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
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget _buildSleekEventCard(EventModel event) {
    const primaryBlue = Color(0xFF203B68);
    const slateGrey = Color(0xFF64748B);

    final dayStr = event.dateEvent != null
        ? DateFormat('dd').format(event.dateEvent!)
        : '--';
    final monthStr = event.dateEvent != null
        ? DateFormat('MMM').format(event.dateEvent!).toUpperCase()
        : 'À VENIR';

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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Small Thumbnail
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    event.imageUrl != null && event.imageUrl!.startsWith('http')
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Builder(
                          builder: (context) {
                            debugPrint('Trying to load image: ${event.imageUrl}');
                            return Image.network(
                              event.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Image load error for ${event.imageUrl}: $error');
                                return const Icon(
                                  Icons.celebration_outlined,
                                  color: primaryBlue,
                                  size: 20,
                                );
                              },
                            );
                          }
                        ),
                      )
                    : const Icon(
                        Icons.celebration_outlined,
                        color: primaryBlue,
                        size: 20,
                      ),
              ),

              const SizedBox(width: 16),

              // Title and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: slateGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$dayStr $monthStr',
                          style: const TextStyle(
                            color: slateGrey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: slateGrey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: slateGrey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
