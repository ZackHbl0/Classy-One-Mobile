import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Full-screen in-app video player with hardware codec fallback support.
/// Automatically falls back to WebView if native player fails on older devices.
class InAppVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String? videoTitle;

  const InAppVideoPlayerScreen({
    super.key,
    required this.videoUrl,
    this.videoTitle,
  });

  @override
  State<InAppVideoPlayerScreen> createState() => _InAppVideoPlayerScreenState();
}

class _InAppVideoPlayerScreenState extends State<InAppVideoPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;
  bool _useWebViewFallback = false;
  int _initAttempts = 0;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if it's a YouTube URL
      if (widget.videoUrl.contains('youtube.com') ||
          widget.videoUrl.contains('youtu.be')) {
        setState(() {
          _errorMessage =
              'Les vidéos YouTube ne sont pas supportées.\nVeuillez utiliser un fichier vidéo direct.';
          _isLoading = false;
        });
        return;
      }

      // Initialize video player (removed custom headers like Range that break Laravel local serve)
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      // Set error handler before initialization
      _videoPlayerController!.addListener(() {
        if (_videoPlayerController!.value.hasError) {
          final error = _videoPlayerController!.value.errorDescription;
          debugPrint('Video Player Error: $error');

          // Check for hardware codec errors
          if (error != null &&
              (error.contains('MediaCodec') ||
                  error.contains('VideoRenderer') ||
                  error.contains('codec') ||
                  error.contains('decoder'))) {
            // Hardware codec error - fallback to WebView
            if (_initAttempts == 0) {
              _initAttempts++;
              _fallbackToWebView();
            }
          }
        }
      });

      // Try to initialize
      await _videoPlayerController!.initialize();

      // Check if initialization was successful
      if (!_videoPlayerController!.value.hasError && mounted) {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
          showControls: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: Colors.blue,
            handleColor: Colors.blue,
            backgroundColor: Colors.grey,
            bufferedColor: Colors.lightBlue,
          ),
          placeholder: Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            ),
          ),
          autoInitialize: true,
          allowFullScreen: true,
          allowMuting: true,
          showControlsOnInitialize: false,
          errorBuilder: (context, errorMessage) {
            // If chewie shows error, fallback to WebView
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _initAttempts == 0) {
                _initAttempts++;
                _fallbackToWebView();
              }
            });
            return _buildErrorWidget(errorMessage);
          },
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        // Initialization failed, fallback to WebView
        if (_initAttempts == 0) {
          _initAttempts++;
          _fallbackToWebView();
        } else if (!_useWebViewFallback) {
           setState(() {
            _errorMessage = 'Impossible de charger la vidéo.\nVérifiez le format.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Video initialization error: $e');
      // On any error, fallback to WebView
      if (_initAttempts == 0 && mounted) {
        _initAttempts++;
        _fallbackToWebView();
      } else if (mounted && !_useWebViewFallback) {
        setState(() {
          _errorMessage =
              'Impossible de charger la vidéo.\nVérifiez votre connexion.';
          _isLoading = false;
        });
      }
    }
  }

  void _fallbackToWebView() {
    debugPrint('Falling back to WebView for video playback');
    if (mounted) {
      setState(() {
        _isLoading = false;
        _useWebViewFallback = true;
        _errorMessage = null;
      });
    }
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          const Text(
            'Erreur de lecture',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.blue),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement de la vidéo...',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            )
          : _errorMessage != null
          ? Padding(
              padding: const EdgeInsets.all(32.0),
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
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Try WebView fallback as last resort
                      if (!_useWebViewFallback) {
                        _fallbackToWebView();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    icon: Icon(
                      _useWebViewFallback ? Icons.arrow_back : Icons.refresh,
                    ),
                    label: Text(_useWebViewFallback ? 'Retour' : 'Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : _useWebViewFallback
          ? _buildWebViewPlayer()
          : _chewieController != null
          ? Chewie(controller: _chewieController!)
          : const Center(
              child: Text(
                'Aucune vidéo à afficher',
                style: TextStyle(color: Colors.white),
              ),
            ),
    );
  }

  /// WebView fallback player for older devices with codec issues
  Widget _buildWebViewPlayer() {
    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri(widget.videoUrl),
            headers: {'Accept': 'video/mp4,video/*,*/*'},
          ),
          initialSettings: InAppWebViewSettings(
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            javaScriptEnabled: true,
            domStorageEnabled: true,
            databaseEnabled: true,
            useHybridComposition: true,
            supportZoom: false,
            builtInZoomControls: false,
            displayZoomControls: false,
          ),
          onWebViewCreated: (controller) {
            // Inject HTML to wrap video in a proper player
            final htmlContent =
                '''
              <!DOCTYPE html>
              <html>
              <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
                <style>
                  * { margin: 0; padding: 0; }
                  body { 
                    background: #000; 
                    overflow: hidden;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    height: 100vh;
                  }
                  video {
                    width: 100%;
                    height: 100%;
                    max-width: 100vw;
                    max-height: 100vh;
                    object-fit: contain;
                  }
                </style>
              </head>
              <body>
                <video controls autoplay playsinline>
                  <source src="${widget.videoUrl}" type="video/mp4">
                  Votre navigateur ne supporte pas la lecture de vidéos.
                </video>
              </body>
              </html>
            ''';
            controller.loadData(data: htmlContent, mimeType: 'text/html');
          },
          onLoadError: (controller, url, code, message) {
            debugPrint('WebView load error: $message');
            if (mounted) {
              setState(() {
                _errorMessage =
                    'Impossible de charger la vidéo dans le lecteur alternatif.';
                _useWebViewFallback = false;
              });
            }
          },
          onConsoleMessage: (controller, consoleMessage) {
            debugPrint('WebView Console: ${consoleMessage.message}');
          },
        ),
        // Show loading indicator in corner
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Mode compatibilité',
                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
