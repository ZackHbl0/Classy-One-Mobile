import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';

class DocumentDetailSheet extends StatelessWidget {
  final Map<String, dynamic> request;

  const DocumentDetailSheet({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final String status = request['status'] ?? 'pending';
    final Color statusColor = _getStatusColor(status);
    final String statusLabel = _getStatusLabel(status);
    final String dateStr = request['request_date'] != null
        ? DateFormat(
            'dd MMM yyyy',
          ).format(DateTime.parse(request['request_date']))
        : 'Date inconnue';
    final String adminMessage =
        request['admin_message'] ?? 'Aucun message de l\'administration.';
    final String? pdfUrl = request['pdf_url'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header: Title and Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['document_type'] ?? 'Document',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(statusLabel, statusColor),
            ],
          ),
          const SizedBox(height: 32),

          // Admin Message Section
          const Text(
            'Message de l\'administration',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              adminMessage,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Download Action
          if (pdfUrl != null && pdfUrl.isNotEmpty)
            _buildDownloadButton(context, pdfUrl)
          else if (status == 'Prêt')
            // Fallback to legacy download method if pdf_url is missing but status is Ready
            _buildDownloadButton(context, null)
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Text(
                'Ce document sera disponible au téléchargement une fois validé.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Close Button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Fermer',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDownloadButton(BuildContext context, String? directUrl) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _handleDownload(context, directUrl),
        icon: const Icon(Icons.file_download_outlined, color: Colors.white),
        label: const Text(
          'Télécharger PDF',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDownload(BuildContext context, String? directUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final id = request['id'];

    Uri url;
    if (directUrl != null && directUrl.isNotEmpty) {
      // If it's a relative path, prepend base URL
      if (directUrl.startsWith('/')) {
        final String base = AuthService.baseUrl.replaceAll('/api', '');
        url = Uri.parse('$base$directUrl?token=$token');
      } else {
        url = Uri.parse('$directUrl?token=$token');
      }
    } else {
      // Fallback to secure generation endpoint
      url = Uri.parse(
        '${AuthService.baseUrl}/documents/$id/download?token=$token',
      );
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir le lien de téléchargement'),
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'En attente':
        return const Color(0xFFF59E0B);
      case 'En cours':
        return const Color(0xFF3B82F6);
      case 'Prêt':
        return const Color(0xFF10B981);
      case 'Rejeté':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'En attente':
        return 'En attente';
      case 'En cours':
        return 'En cours';
      case 'Prêt':
        return 'Prêt';
      case 'Rejeté':
        return 'Refusé';
      default:
        return status;
    }
  }
}
