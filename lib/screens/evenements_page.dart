import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/auth_service.dart';
import '../widgets/screen_header.dart';
import '../models/event_model.dart';
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

  Future<void> _registerForEvent(int idEvent) async {
    final prefs = await SharedPreferences.getInstance();
    final idStudent = prefs.getInt('idStudent') ?? 0;

    if (idStudent != 0) {
      // Re-using the existing registerForEvent service method.
      // Note: In PHP, 'idNotification' is currently mapped to 'idEvent' in our new logic.
      final result = await _authService.registerForEvent(idStudent, idEvent);

      if (result['success'] == true) {
        _fetchEvenements();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inscription réussie !')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Erreur lors de l\'inscription',
              ),
            ),
          );
        }
      }
    }
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
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
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

    return Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Error Handling
            Container(
              width: 90,
              height: 110,
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  event.imageUrl != null && event.imageUrl!.startsWith('http')
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        event.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.celebration_outlined,
                              color: primaryBlue,
                              size: 30,
                            ),
                      ),
                    )
                  : const Icon(
                      Icons.celebration_outlined,
                      color: primaryBlue,
                      size: 30,
                    ),
            ),

            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Date Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          children: [
                            Text(
                              dayStr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              monthStr,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Participants
                      Row(
                        children: [
                          const Icon(
                            Icons.people_alt,
                            size: 12,
                            color: slateGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${event.participants}',
                            style: const TextStyle(
                              color: slateGrey,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

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
                        Icons.location_on_outlined,
                        size: 12,
                        color: slateGrey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${event.location} - ${event.dateEvent != null ? DateFormat('HH:mm').format(event.dateEvent!) : "10:00 AM"}',
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

                  const SizedBox(height: 12),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: event.isConfirmed
                        ? Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Déjà Inscrit',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Calendrier',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  foregroundColor: primaryBlue,
                                ),
                              ),
                            ],
                          )
                        : ElevatedButton(
                            onPressed: () => _registerForEvent(event.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'S\'inscrire',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
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
    );
  }
}
