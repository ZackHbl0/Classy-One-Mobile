import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../widgets/screen_header.dart';


class UnifiedPlanningPage extends StatefulWidget {
  const UnifiedPlanningPage({super.key});

  @override
  State<UnifiedPlanningPage> createState() => _UnifiedPlanningPageState();
}

class _UnifiedPlanningPageState extends State<UnifiedPlanningPage> {
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
    
    // Resiliently get idStudent (some old logic might store it as String)
    int idStudent = 0;
    final idRaw = prefs.get('idStudent');
    if (idRaw is int) {
      idStudent = idRaw;
    } else if (idRaw is String) {
      idStudent = int.tryParse(idRaw) ?? 0;
    }

    if (idStudent == 0) {
      setState(() {
        _isLoading = false;
        _weeks = [];
      });
      if (mounted) {
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
        // Success silent or tiny info
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
                      alignment: AlignmentDirectional.centerStart,
                    ),
                  const ScreenHeader(title: 'Planning'),
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
                            if (_weeks.isEmpty)
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

  Widget _buildMonthPicker() {
    return GestureDetector(
      onTap: _selectMonth,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
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
      childAspectRatio: 1.7, // Increased height for better text containment
      children: [
        _buildSummaryCard(
          "Early Leave",
          _summary['early_leave'],
          const Color(0xFF3B82F6),
        ),
        _buildSummaryCard(
          "Absents",
          _summary['absents'],
          const Color(0xFFA855F7),
        ),
        _buildSummaryCard(
          "Late in",
          _summary['late_in'],
          const Color(0xFFEF4444),
        ),
        _buildSummaryCard(
          "Leaves",
          _summary['leaves'],
          const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding to libere space
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10)],
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
              style: const TextStyle(
                color: Colors.black54,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    week['title'] ?? 'Semaine',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (week['stats'] != null &&
                      (week['stats']['Absent'] ?? 0) > 0)
                    _buildBadge(
                      "${week['stats']['Absent']} Absent",
                      const Color(0xFFA855F7),
                    ),
                  if (week['stats'] != null &&
                      (week['stats']['Leave'] ?? 0) > 0) ...[
                    const SizedBox(width: 5),
                    _buildBadge(
                      "${week['stats']['Leave']} Leave",
                      const Color(0xFFF59E0B),
                    ),
                  ],
                  if (week['stats'] != null &&
                      (week['stats']['Late'] ?? 0) > 0) ...[
                    const SizedBox(width: 5),
                    _buildBadge(
                      "${week['stats']['Late']} Late",
                      const Color(0xFFEF4444),
                    ),
                  ],
                  const SizedBox(width: 10),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.black26),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (week['items'] != null)
          ...((week['items'] as List)
              .map((item) => _buildUnifiedItem(item))
              .toList()),
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
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUnifiedItem(dynamic item) {
    if (item['type'] == 'schedule') {
      return _buildScheduleItem(item);
    }
    return _buildAttendanceItem(item);
  }

  Widget _buildScheduleItem(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE0F2FE),
            child: Icon(
              Icons.picture_as_pdf,
              color: Colors.blueAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['label'] ?? 'Planning PDF',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Text(
                  'Emploi du temps hebdomadaire',
                  style: TextStyle(color: Colors.black45, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final url = Uri.parse(item['fileUrl']);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            child: const Text(
              'VOIR',
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(dynamic day) {
    bool isSpecialStr =
        day['status'] != null &&
        (day['status'].toString().toLowerCase().contains('sick') ||
            day['status'].toString().toLowerCase().contains('absent'));

    if (isSpecialStr) {
      Color color = day['status'].toString().toLowerCase().contains('sick')
          ? const Color(0xFFF59E0B)
          : const Color(0xFFA855F7);
      return _buildSpecialDayTile(day, color);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: IntrinsicHeight(
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day['date'] ?? '--',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    day['dayName'] ?? '--',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Container(
              width: 2,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: const Color(0xFFE5E7EB),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTimeInfo(
                      "Check in",
                      day['checkIn'] ?? "--:--",
                      Icons.access_time,
                      Colors.teal,
                    ),
                    _buildTimeInfo(
                      "Check Out",
                      day['checkOut'] ?? "--:--",
                      Icons.access_time_filled,
                      Colors.redAccent,
                    ),
                    _buildTimeInfo(
                      "Total Hours",
                      day['totalHours'] ?? "--",
                      Icons.timer_outlined,
                      Colors.blueAccent,
                    ),
                    if (day['fileUrl'] != null && day['fileUrl'].toString().isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.blueAccent, size: 20),
                        onPressed: () async {
                          final url = Uri.parse(day['fileUrl']);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
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

  Widget _buildSpecialDayTile(dynamic day, Color color) {
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
                border: BorderDirectional(
                  end: BorderSide(color: color.withOpacity(0.2)),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day['date'] ?? '--',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                  Text(
                    day['dayName'] ?? '--',
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Text(
              day['status'] ?? '--',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color.withOpacity(0.7)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.black45, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 100),
          const Icon(
            Icons.history_toggle_off,
            color: Colors.black12,
            size: 100,
          ),
          const SizedBox(height: 20),
          const Text(
            'Pas d\'historique trouvé',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vos plannings et présences apparaîtront ici.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
