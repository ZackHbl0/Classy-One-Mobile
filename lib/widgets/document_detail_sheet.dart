import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../utils/url_fixer.dart';
import '../utils/content_router.dart';

class DocumentDetailSheet extends StatelessWidget {
  final Map<String, dynamic> request;

  const DocumentDetailSheet({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final String rawStatus = (request['status'] ?? request['raw_status'] ?? 'pending').toString();
    final Color statusColor = _getStatusColor(rawStatus);
    final String statusLabel = _getStatusLabel(rawStatus);

    // Safe Request Date Parsing
    String dateStr = 'Date inconnue';
    final rawDate = request['request_date'] ?? request['created_at'];
    if (rawDate != null && rawDate.toString().trim().isNotEmpty) {
      final str = rawDate.toString().trim();
      try {
        final parsed = DateTime.parse(str.replaceAll(' ', 'T'));
        dateStr = DateFormat('dd MMM yyyy', 'fr').format(parsed);
      } catch (_) {
        dateStr = str;
      }
    }

    // Safe Ready Date Parsing
    final String? rawReadyDate = request['ready_date'];
    String? readyDateStr;
    if (rawReadyDate != null && rawReadyDate.trim().isNotEmpty) {
      try {
        final parsed = DateTime.parse(rawReadyDate.replaceAll(' ', 'T'));
        readyDateStr = "${DateFormat('dd/MM/yyyy').format(parsed)} \u00e0 ${DateFormat('HH:mm').format(parsed)}";
      } catch (_) {
        readyDateStr = rawReadyDate;
      }
    }

    final String? studentName = request['student_name'];
    final String? reason = request['reason'] ?? request['comments'];
    final String? rejectionReason = request['rejection_reason'];
    final bool isRejected = rawStatus.toLowerCase().contains('rejet') ||
        rawStatus.toLowerCase().contains('refus') ||
        rawStatus.toLowerCase().contains('reject');

    final String adminMessage = (rejectionReason != null && rejectionReason.trim().isNotEmpty)
        ? rejectionReason.trim()
        : (request['admin_message'] ?? request['admin_note'] ?? 'Aucun message de l\'administration.');

    final String? pdfUrl = request['pdf_url'];
    final String urgency = (request['urgency_label'] ?? request['urgency'] ?? '').toString().toLowerCase();
    final bool isUrgent = urgency.contains('urg');

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool isReady = rawStatus.toLowerCase().contains('pr\u00eat') ||
        rawStatus.toLowerCase().contains('pret') ||
        rawStatus.toLowerCase().contains('ready') ||
        rawStatus.toLowerCase().contains('disponible') ||
        rawStatus.toLowerCase().contains('valid');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header: Title, Student info, Date, Status Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['document_type'] ?? 'Document Officiel',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (studentName != null && studentName.trim().isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Élève : $studentName',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: isDark ? Colors.grey.shade500 : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Demandé le : $dateStr',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatusBadge(statusLabel, statusColor),
                    if (isUrgent) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'Urgente',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Date de disponibilité (Highlight Card)
            if (readyDateStr != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(isDark ? 0.35 : 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.event_available_rounded,
                        color: Color(0xFF10B981),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date de disponibilité',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            readyDateStr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Motif de la demande (if exists)
            if (reason != null && reason.trim().isNotEmpty) ...[
              Text(
                'Motif de la demande',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  reason.trim(),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Admin Message / Rejection Note Section
            Text(
              isRejected ? 'Motif du refus' : 'Message de l\'administration',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isRejected
                    ? Colors.red
                    : (isDark ? Colors.white : const Color(0xFF1E293B)),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isRejected
                    ? Colors.red.withOpacity(0.08)
                    : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isRejected
                      ? Colors.red.withOpacity(0.25)
                      : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Text(
                adminMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: isRejected
                      ? Colors.red.shade700
                      : (isDark ? Colors.white70 : const Color(0xFF475569)),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Download PDF Action Button
            if (pdfUrl != null && pdfUrl.isNotEmpty)
              _buildDownloadButton(context, pdfUrl)
            else if (isReady)
              _buildDownloadButton(context, null)
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Ce document sera disponible au téléchargement une fois validé.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Fermer',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
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
          'Télécharger le document PDF',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
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

    String resolvedUrl = '';
    if (directUrl != null && directUrl.isNotEmpty) {
      resolvedUrl = UrlFixer.fixUrl(directUrl);
    } else {
      resolvedUrl = UrlFixer.fixUrl('${AuthService.baseUrl}/documents/$id/download?token=$token');
    }

    try {
      if (!context.mounted) return;
      await ContentRouter.routeContent(
        context,
        contentUrl: resolvedUrl,
        contentTitle: request['document_type'] ?? 'Certificat de scolarité',
      );
    } catch (_) {
      final uri = Uri.parse(resolvedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir le document PDF'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('attente') || s.contains('pending')) return const Color(0xFFF59E0B);
    if (s.contains('cours') || s.contains('process')) return const Color(0xFF6366F1);
    if (s.contains('pr\u00eat') || s.contains('pret') || s.contains('ready') || s.contains('disponible') || s.contains('valid')) return const Color(0xFF10B981);
    if (s.contains('rejet') || s.contains('refus') || s.contains('reject')) return const Color(0xFFEF4444);
    return const Color(0xFF64748B);
  }

  String _getStatusLabel(String status) {
    final s = status.toLowerCase();
    if (s.contains('attente') || s.contains('pending')) return 'En attente';
    if (s.contains('cours') || s.contains('process')) return 'En cours';
    if (s.contains('pr\u00eat') || s.contains('pret') || s.contains('ready') || s.contains('disponible') || s.contains('valid')) return 'Disponible / Pr\u00eat';
    if (s.contains('rejet') || s.contains('refus') || s.contains('reject')) return 'Rejet\u00e9e';
    return status;
  }
}
