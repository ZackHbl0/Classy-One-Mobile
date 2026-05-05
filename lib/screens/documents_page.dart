import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/screen_header.dart';
import '../widgets/document_detail_sheet.dart';
import 'package:flutter_application_1/screens/new_document_request_page.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchRequests,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
            physics: const BouncingScrollPhysics(),
            children: [
              const ScreenHeader(title: 'Mes Documents'),
              const SizedBox(height: 24),

              // New Request Button
              _buildNewRequestButton(),

              const SizedBox(height: 32),

              Text(
                'Demandes récentes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),

              const SizedBox(height: 16),

              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).primaryColor
                        : const Color(0xFF203B68),
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
                ..._requests.map((req) => _buildRequestCard(req)),

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
          colors: [Color(0xFF203B68), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF203B68).withOpacity(0.3),
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
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Nouvelle demande',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestDetail(dynamic req) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DocumentDetailSheet(request: req),
    );
  }

  Widget _buildRequestCard(dynamic req) {
    final String status = req['status'] ?? 'pending';
    final Color statusColor = _getStatusColor(status);
    final String statusLabel = _getStatusLabel(status);
    final String dateStr = req['request_date'] != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(req['request_date']))
        : 'Date inconnue';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: InkWell(
        onTap: () => _showRequestDetail(req),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    req['document_type'] ?? 'Document',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                _buildStatusBadge(statusLabel, statusColor),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                Text(
                  'Demandé le : $dateStr',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white38
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            if (req['urgency'] == 'urgent') ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.speed, size: 14, color: Color(0xFFEF4444)),
                  SizedBox(width: 6),
                  Text(
                    'Urgent',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'Prêt') ...[
              const SizedBox(height: 20),
              _buildDownloadButton(req),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton(dynamic req) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token') ?? '';
          final id = req['id'];

          // Use direct PDF URL if available, otherwise fallback to generation endpoint
          final String? pdfUrl = req['pdf_url'];
          final url = Uri.parse(
            pdfUrl != null && pdfUrl.isNotEmpty
                ? '$pdfUrl?token=$token'
                : '${AuthService.baseUrl}/documents/$id/download?token=$token',
          );

          try {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Impossible d\'ouvrir le lien de téléchargement'),
              ),
            );
          }
        },
        icon: const Icon(Icons.file_download_outlined, size: 18),
        label: const Text('Télécharger le certificat (PDF)'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF10B981),
          side: const BorderSide(color: Color(0xFF10B981)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF10B981).withOpacity(0.05)
              : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        children: [
          SizedBox(height: 48),
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Color(0x3394A3B8),
          ),
          SizedBox(height: 16),
          Text(
            'Aucune demande effectuée',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'En attente':
        return const Color(0xFFF59E0B); // Amber
      case 'En cours':
        return const Color(0xFF3B82F6); // Blue
      case 'Prêt':
        return const Color(0xFF10B981); // Green
      case 'Rejeté':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'En attente':
        return '🟡 En attente';
      case 'En cours':
        return '🔵 En cours de traitement';
      case 'Prêt':
        return '🟢 Prêt à récupérer';
      case 'Rejeté':
        return '🔴 Refusé';
      default:
        return status;
    }
  }
}
