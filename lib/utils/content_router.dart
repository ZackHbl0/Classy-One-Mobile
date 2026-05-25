import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/video_player_screen.dart';

/// Determines file type from URL extension and routes to appropriate viewer
class ContentRouter {
  /// Extract file extension from URL
  static String _getFileExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      final lastDotIndex = path.lastIndexOf('.');
      if (lastDotIndex != -1) {
        return path.substring(lastDotIndex + 1).split('?').first;
      }
    } catch (_) {}
    return '';
  }

  /// Determine content type from extension
  static ContentType _getContentType(String extension) {
    switch (extension) {
      case 'mp4':
      case 'mkv':
      case 'webm':
      case 'avi':
      case 'mov':
      case 'flv':
        return ContentType.video;
      case 'pdf':
        return ContentType.pdf;
      case 'doc':
      case 'docx':
      case 'txt':
      case 'xlsx':
      case 'xls':
      case 'pptx':
      case 'ppt':
        return ContentType.document;
      default:
        return ContentType.unknown;
    }
  }

  /// Smart routing function that handles navigation based on file type
  static Future<void> routeContent(
    BuildContext context, {
    required String contentUrl,
    required String? contentTitle,
    VoidCallback? onLoadingStart,
    VoidCallback? onLoadingEnd,
  }) async {
    if (contentUrl.isEmpty) {
      _showErrorSnackBar(context, 'URL du contenu invalide');
      return;
    }

    try {
      onLoadingStart?.call();

      final extension = _getFileExtension(contentUrl);
      final contentType = _getContentType(extension);

      switch (contentType) {
        case ContentType.video:
          if (mounted(context)) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(
                  videoUrl: contentUrl,
                  videoTitle: contentTitle ?? 'Lecture vidéo',
                ),
              ),
            );
          }
          onLoadingEnd?.call();
          break;

        case ContentType.pdf:
          await _launchContentUrl(
            context,
            contentUrl,
            contentTitle ?? 'Document PDF',
          );
          onLoadingEnd?.call();
          break;

        case ContentType.document:
          // For Office docs, launch in browser
          await _launchContentUrl(
            context,
            contentUrl,
            contentTitle ?? 'Document',
          );
          onLoadingEnd?.call();
          break;

        case ContentType.unknown:
          // Try to launch as generic URL
          await _launchContentUrl(
            context,
            contentUrl,
            contentTitle ?? 'Contenu',
          );
          onLoadingEnd?.call();
          break;
      }
    } catch (e) {
      onLoadingEnd?.call();
      if (mounted(context)) {
        _showErrorSnackBar(context, 'Erreur: $e');
      }
    }
  }

  /// Launch URL in external application
  static Future<void> _launchContentUrl(
    BuildContext context,
    String url,
    String title,
  ) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted(context)) {
          _showErrorSnackBar(context, 'Impossible d\'ouvrir le contenu');
        }
      }
    } catch (e) {
      if (mounted(context)) {
        _showErrorSnackBar(context, 'Erreur: $e');
      }
    }
  }

  /// Show error feedback to user
  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Check if context is still mounted (for async safety)
  static bool mounted(BuildContext context) {
    try {
      context.mounted;
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Content type enumeration
enum ContentType { video, pdf, document, unknown }
