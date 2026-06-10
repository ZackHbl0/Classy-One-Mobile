import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A clean, minimal screen for launching course videos.
/// Features a professional white background with blue accents,
/// displaying only essential elements: title, video icon, and launch button.
class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String? videoTitle;

  const VideoPlayerScreen({super.key, required this.videoUrl, this.videoTitle});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  bool _isLaunching = false;

  Future<void> _openVideoExternally() async {
    setState(() => _isLaunching = true);
    final uri = Uri.parse(widget.videoUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir le lien vidéo.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.videoTitle ?? 'Lecture vidéo',
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Clean video icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_circle_outline_rounded,
                  size: 60,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 32),
              // Video title
              Text(
                widget.videoTitle ?? 'Contenu vidéo',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              // Primary action button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLaunching ? null : _openVideoExternally,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.blue.shade300,
                  ),
                  child: _isLaunching
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Ouvrir la vidéo',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
