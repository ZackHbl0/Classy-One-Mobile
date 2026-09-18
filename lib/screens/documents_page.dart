import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/screen_header.dart';
import '../widgets/document_detail_sheet.dart';
import 'package:flutter_application_1/screens/new_document_request_page.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_sidebar.dart';
import 'package:google_fonts/google_fonts.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final AuthService _authService = AuthService();
  List<dynamic> _requests = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final idStudent = prefs.getInt('idStudent') ?? 0;

    if (idStudent == 0) return;

    final result = await _authService.getDocumentRequests(idStudent);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _requests = result['data'] ?? [];
        } else {
          _errorMessage = result['message'] ?? 'Erreur lors du chargement';
        }
      });
    }
  }

  int get _total => _requests.length;
  int get _enCours => _requests.where((r) => r['status'] == 'En cours').length;
  int get _enAttente =>
      _requests.where((r) => r['status'] == 'En attente').length;
  int get _disponibles => _requests.where((r) => r['status'] == 'Prêt').length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1E241E)
          : const Color(0xFFF9FAFB),
      drawer: const CustomSidebar(currentRoute: '/documents'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchRequests,
          color: const Color(0xFF2A8B5B),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              const ScreenHeader(title: 'Mes Documents', showBackButton: false),
              const SizedBox(height: 24),

              // New Request Button
              _buildNewRequestButton(),
              const SizedBox(height: 24),

              // Stats Row
              _buildStatsRow(isDark),
              const SizedBox(height: 32),

              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(
                    color: isDark
                        ? const Color(0xFF3BBE7A)
                        : const Color(0xFF2A8B5B),
                  ),
                )
              else if (_errorMessage.isNotEmpty)
                Center(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else if (_requests.isEmpty)
                _buildEmptyState()
              else
                ..._buildTimelineRequests(isDark),

              const SizedBox(height: 40), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewRequestButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4E3B), Color(0xFF3BBE7A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A8B5B).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewDocumentRequestPage(),
            ),
          );
          if (result == true) {
            setState(() {
              _isLoading = true;
            });
            _fetchRequests();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Nouvelle demande',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(flex: 2),
            const Icon(Icons.chevron_right, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A322A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            Icons.description_outlined,
            const Color(0xFFE8F5E9),
            const Color(0xFF2A8B5B),
            'Total demandes',
            _total.toString(),
            true,
            isDark,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            Icons.access_time,
            const Color(0xFFEEF2FF),
            const Color(0xFF6366F1),
            'En cours',
            _enCours.toString(),
            false,
            isDark,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            Icons.hourglass_empty,
            const Color(0xFFFFF7ED),
            const Color(0xFFF59E0B),
            'En attente',
            _enAttente.toString(),
            false,
            isDark,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            Icons.check_circle_outline,
            const Color(0xFFECFDF5),
            const Color(0xFF10B981),
            'Disponibles',
            _disponibles.toString(),
            false,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.withOpacity(0.15),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    Color bgColor,
    Color iconColor,
    String title,
    String value,
    bool isActive,
    bool isDark,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? bgColor.withOpacity(0.1) : bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF6B7280),
          ),
        ),
        if (isActive) ...[
          const SizedBox(height: 12),
          Container(
            height: 4,
            width: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF2A8B5B),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ] else ...[
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  List<Widget> _buildTimelineRequests(bool isDark) {
    List<Widget> items = [];
    for (int i = 0; i < _requests.length; i++) {
      items.add(
        _buildTimelineItem(_requests[i], i == _requests.length - 1, isDark),
      );
    }
    return items;
  }

  Widget _buildTimelineItem(dynamic req, bool isLast, bool isDark) {
    final String status = req['status'] ?? 'pending';
    final String dateStr = req['request_date'] != null
        ? DateFormat(
            'dd MMM yyyy',
            'fr',
          ).format(DateTime.parse(req['request_date']))
        : 'Date inconnue';

    Color dotColor = const Color(0xFF6366F1); // Blue default
    if (status == 'En attente') dotColor = const Color(0xFFF59E0B);
    if (status == 'Prêt' || status.toLowerCase() == 'ready' || status.toLowerCase() == 'disponible') dotColor = const Color(0xFF10B981);
    if (status == 'Rejeté') dotColor = const Color(0xFFEF4444);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 40,
                    bottom: -20,
                    child: Container(
                      width: 1,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                Positioned(
                  top: 40,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1E241E)
                            : const Color(0xFFF9FAFB),
                        width: 3,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 36,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: dotColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Card
          Expanded(
            child: InkWell(
              onTap: () => _showRequestDetail(req),
              borderRadius: BorderRadius.circular(20),
              child: _buildRequestCard(req, isDark, dotColor, status, dateStr),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
    dynamic req,
    bool isDark,
    Color mainColor,
    String status,
    String dateStr,
  ) {
    final String type = req['document_type'] ?? 'Document';
    bool isPdf = type.toLowerCase().contains('relevé');

    Color iconBgColor = isDark
        ? mainColor.withOpacity(0.1)
        : mainColor.withOpacity(0.08);
    IconData docIcon = isPdf
        ? Icons.picture_as_pdf_outlined
        : Icons.description_outlined;

    String statusLabel = status;
    int progress = 100;

    if (status == 'En cours') {
      statusLabel = 'En cours de traitement';
      progress = 80;
    } else if (status == 'En attente') {
      statusLabel = 'En attente de validation';
      progress = 60;
    } else if (status == 'Prêt') {
      statusLabel = 'Disponible';
    } else if (status == 'Rejeté') {
      statusLabel = 'Signature requise';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A322A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Icon
          Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(docIcon, color: mainColor, size: 32),
                if (status == 'Prêt')
                  Positioned(
                    bottom: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  )
                else if (status == 'Rejeté')
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Color(0xFFEF4444),
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        type,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Demandé le : $dateStr',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                Builder(
                  builder: (context) {
                    final String readyDateFormatted = _formatReadyDate(req['ready_date']);
                    if (readyDateFormatted.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event_available_rounded,
                            size: 13,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Disponible le : $readyDateFormatted',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? mainColor.withOpacity(0.15)
                        : mainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: mainColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Progress bar or specific action
                if (status == 'En cours' || status == 'En attente') ...[
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                color: mainColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$progress%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (status == 'Prêt')
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _downloadDoc(req),
                          icon: const Icon(
                            Icons.file_download_outlined,
                            size: 18,
                          ),
                          label: const Text(
                            'Télécharger',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            side: const BorderSide(color: Color(0xFF10B981)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      )
                    else if (status == 'Rejeté')
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRequestDetail(req),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text(
                            'Signer maintenant',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      )
                    else ...[
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          onPressed: status == 'En cours'
                              ? () => _downloadDoc(req)
                              : () => _showRequestDetail(req),
                          icon: Icon(
                            status == 'En cours'
                                ? Icons.file_download_outlined
                                : Icons.chat_bubble_outline,
                            size: 20,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(8),
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatReadyDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final parsed = DateTime.parse(raw.toString().replaceAll(' ', 'T'));
      return "${DateFormat('dd/MM/yyyy').format(parsed)} à ${DateFormat('HH:mm').format(parsed)}";
    } catch (_) {
      return raw.toString();
    }
  }

  void _showRequestDetail(dynamic req) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DocumentDetailSheet(request: req),
    );
  }

  Future<void> _downloadDoc(dynamic req) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final id = req['id'];

    final String? pdfUrl = req['pdf_url'];
    final url = Uri.parse(
      pdfUrl != null && pdfUrl.isNotEmpty
          ? '$pdfUrl?token=$token'
          : '${AuthService.baseUrl}/documents/$id/download?token=$token',
    );

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir le lien')),
        );
      }
    }
  }

  Widget _buildSupportBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.headset_mic_outlined,
              color: Color(0xFF2A8B5B),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Besoin d'aide ?",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Notre équipe est là pour vous aider.",
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A8B5B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Centre d\'aide',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        children: [
          SizedBox(height: 48),
          Icon(Icons.description_outlined, size: 80, color: Color(0x3394A3B8)),
          SizedBox(height: 16),
          Text(
            'Aucune demande effectuée',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
          ),
        ],
      ),
    );
  }
}
