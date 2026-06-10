import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';

/// Full-screen in-app image viewer with zoom and pan capabilities.
/// Displays course images without leaving the app.
class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String? imageTitle;

  const ImageViewerScreen({super.key, required this.imageUrl, this.imageTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          imageTitle ?? 'Image',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: PhotoView(
          imageProvider: CachedNetworkImageProvider(imageUrl),
          backgroundDecoration: const BoxDecoration(color: Colors.white),
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.covered * 2.5,
          initialScale: PhotoViewComputedScale.contained,
          loadingBuilder: (context, event) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded /
                            (event.expectedTotalBytes ?? 1),
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                Text(
                  'Chargement de l\'image...',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          errorBuilder: (context, error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  'Impossible de charger l\'image',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vérifiez votre connexion internet',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
