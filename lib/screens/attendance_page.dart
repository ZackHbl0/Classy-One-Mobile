import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../widgets/screen_header.dart';

class AttendanceSummaryPage extends StatefulWidget {
  const AttendanceSummaryPage({super.key});

  @override
  State<AttendanceSummaryPage> createState() => _AttendanceSummaryPageState();
}

class _AttendanceSummaryPageState extends State<AttendanceSummaryPage> {
  bool _isLoading = true;
  final AuthService _authService = AuthService();

  Map<String, dynamic> _summary = {
    "early_leave": 0,
    "absents": 0,
    "late_in": 0,
    "leaves": 0,
  };
  List<dynamic> _weeks = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    
    int idStudent = prefs.getInt('idStudent') ?? 0;
    if (idStudent == 0) {
      // Fallback
      final idRaw = prefs.getString('idStudent');
      idStudent = int.tryParse(idRaw ?? '') ?? 0;
    }

    if (idStudent == 0) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: Aucun ID étudiant trouvé. Veuillez vous reconnecter.')),
        );
      }
      return;
    }

    final result = await _authService.getAttendance(
      idStudent,
      month: _selectedDate.month,
      year: _selectedDate.year,
    );

    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _summary = result['data']['summary'] ?? _summary;
          _weeks = result['data']['weeks'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _weeks = [];
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

  void _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'SÉLECTIONNEZ LE MOIS',
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month);
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
                      alignment: AlignmentDirectional.centerStart,
                    ),
                  const ScreenHeader(title: 'Assiduité'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMonthPicker(),
                            const SizedBox(height: 20),
                            _buildSummaryGrid(),
                            const SizedBox(height: 30),
                            if (_isWeeksEmptyOrNoAbsences())
                              _buildEmptyState()
                            else
                              _buildWeeksList(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isWeeksEmptyOrNoAbsences() {
    if (_weeks.isEmpty) return true;
    for (var week in _weeks) {
      if (week['items'] != null) {
        final filteredItems = (week['items'] as List).where((item) {
          final status = (item['status'] ?? '').toString().toLowerCase();
          return item['type'] != 'schedule' && 
                 (status.contains('sick') || status.contains('absent') || status.contains('late'));
        }).toList();
        if (filteredItems.isNotEmpty) return false;
      }
    }
    return true;
  }

  Widget _buildMonthPicker() {
    return GestureDetector(
      onTap: _selectMonth,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
              blurRadius: 10
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month, color: Color(0xFF1E293B)),
                const SizedBox(width: 12),
                Text(
                  DateFormat('MMMM yyyy', 'fr_FR').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.7,
      children: [
        _buildSummaryCard("Early Leave", _summary['early_leave'], const Color(0xFF3B82F6)),
        _buildSummaryCard("Absents", _summary['absents'], const Color(0xFFA855F7)),
        _buildSummaryCard("Late in", _summary['late_in'], const Color(0xFFEF4444)),
        _buildSummaryCard("Leaves", _summary['leaves'], const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _buildSummaryCard(String title, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.1 : 0.05), 
            blurRadius: 10
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              (value ?? 0).toString(),
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeksList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _weeks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 25),
      itemBuilder: (context, index) {
        final week = _weeks[index];
        return _buildWeekSection(week);
      },
    );
  }

  Widget _buildWeekSection(dynamic week) {
    List<dynamic> filteredItems = [];
    if (week['items'] != null) {
      filteredItems = (week['items'] as List).where((item) {
        final status = (item['status'] ?? '').toString().toLowerCase();
        return item['type'] != 'schedule' && 
               (status.contains('sick') || status.contains('absent') || status.contains('late'));
      }).toList();
    }

    if (filteredItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6).withOpacity(0.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                week['title'] ?? 'Semaine',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Row(
                children: [
                  if (week['stats'] != null && (week['stats']['Absent'] ?? 0) > 0)
                    _buildBadge("${week['stats']['Absent']} Absent", const Color(0xFFA855F7)),
                  if (week['stats'] != null && (week['stats']['Leave'] ?? 0) > 0) ...[
                    const SizedBox(width: 5),
                    _buildBadge("${week['stats']['Leave']} Leave", const Color(0xFFF59E0B)),
                  ],
                  if (week['stats'] != null && (week['stats']['Late'] ?? 0) > 0) ...[
                    const SizedBox(width: 5),
                    _buildBadge("${week['stats']['Late']} Late", const Color(0xFFEF4444)),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...filteredItems.map((item) => _buildAttendanceItem(item)).toList(),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAttendanceItem(dynamic day) {
    Color color = const Color(0xFFA855F7); // Default purple for Absence
    final status = (day['status'] ?? '').toString().toLowerCase();
    
    if (status.contains('sick') || status.contains('leave')) {
      color = const Color(0xFFF59E0B); // Amber
    } else if (status.contains('late')) {
      color = const Color(0xFFEF4444); // Red
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: BorderDirectional(end: BorderSide(color: color.withOpacity(0.2))),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day['date'] ?? '--',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                  ),
                  Text(
                    day['dayName'] ?? '--',
                    style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Text(
              day['status'] ?? '--',
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 16, 
                color: Theme.of(context).textTheme.bodyLarge?.color,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 100),
          const SizedBox(height: 20),
          const Text(
            'Aucune absence à signaler !',
            style: TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vous avez une assiduité parfaite pour ce mois.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
