import 'package:flutter/material.dart';
import '../screens/in_app_video_player_screen.dart';
import '../screens/pdf_viewer_screen.dart';
import '../screens/image_viewer_screen.dart';
import '../utils/url_fixer.dart';

/// Determines file type from URL extension and routes to appropriate IN-APP viewer.
/// All content is displayed within the app - no external browser launches.
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
      case 'm3u8':
        return ContentType.video;
      case 'pdf':
        return ContentType.pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
        return ContentType.image;
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
  /// ALL content opens in-app - NO external browser launches
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

      // Fix localhost URLs to use proper server IP
      final fixedUrl = UrlFixer.fixUrl(contentUrl);

      final extension = _getFileExtension(fixedUrl);
      final contentType = _getContentType(extension);

      // Ensure we're still in a valid context before navigation
      if (!context.mounted) {
        onLoadingEnd?.call();
        return;
      }

      switch (contentType) {
        case ContentType.video:
          // Open video in-app
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InAppVideoPlayerScreen(
                videoUrl: fixedUrl,
                videoTitle: contentTitle ?? 'Lecture vidéo',
              ),
            ),
          );
          onLoadingEnd?.call();
          break;

        case ContentType.pdf:
          // Open PDF in-app
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfViewerScreen(
                pdfUrl: fixedUrl,
                pdfTitle: contentTitle ?? 'Document PDF',
              ),
            ),
          );
          onLoadingEnd?.call();
          break;

        case ContentType.image:
          // Open image in-app with zoom
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageViewerScreen(
                imageUrl: fixedUrl,
                imageTitle: contentTitle ?? 'Image',
              ),
            ),
          );
          onLoadingEnd?.call();
          break;

        case ContentType.document:
        case ContentType.unknown:
          // For unsupported types, show a helpful message
          onLoadingEnd?.call();
          if (context.mounted) {
            _showErrorSnackBar(
              context,
              'Type de fichier non supporté: .$extension\nContactez votre professeur.',
            );
          }
          break;
      }
    } catch (e) {
      onLoadingEnd?.call();
      if (context.mounted) {
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
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

/// Content type enumeration
enum ContentType { video, pdf, image, document, unknown }
