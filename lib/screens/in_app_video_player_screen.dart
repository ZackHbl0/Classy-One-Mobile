import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Lecteur vidéo in-app plein écran avec support d'accélération matérielle,
/// saut de ±10 secondes au double-tap (à gauche et à droite), et repli WebView.
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
  InAppWebViewController? _webViewController;

  bool _isLoading = true;
  String? _errorMessage;
  bool _useWebViewFallback = false;
  int _initAttempts = 0;

  // Feedback visuel du saut de 10s (style YouTube)
  bool _showForwardIndicator = false;
  bool _showBackwardIndicator = false;
  Timer? _indicatorTimer;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _useWebViewFallback = false;
    });

    try {
      if (widget.videoUrl.contains('youtube.com') ||
          widget.videoUrl.contains('youtu.be')) {
        setState(() {
          _errorMessage =
              'Les vidéos YouTube ne sont pas supportées.\nVeuillez utiliser un fichier vidéo direct.';
          _isLoading = false;
        });
        return;
      }

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      _videoPlayerController!.addListener(() {
        if (_videoPlayerController!.value.hasError) {
          final error = _videoPlayerController!.value.errorDescription;
          debugPrint('Video Player Error: $error');

          if (error != null &&
              (error.contains('MediaCodec') ||
                  error.contains('VideoRenderer') ||
                  error.contains('codec') ||
                  error.contains('decoder'))) {
            if (_initAttempts == 0) {
              _initAttempts++;
              _fallbackToWebView();
            }
          }
        }
      });

      await _videoPlayerController!.initialize();

      if (!_videoPlayerController!.value.hasError && mounted) {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
          showControls: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: Colors.blueAccent,
            handleColor: Colors.blueAccent,
            backgroundColor: Colors.white24,
            bufferedColor: Colors.white38,
          ),
          placeholder: Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),
          ),
          autoInitialize: true,
          allowFullScreen: true,
          allowMuting: true,
          showControlsOnInitialize: false,
          errorBuilder: (context, errorMessage) {
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
            _useWebViewFallback = false;
          });
        }
      } else {
        if (_initAttempts == 0 && mounted) {
          _initAttempts++;
          _fallbackToWebView();
        }
      }
    } catch (e) {
      debugPrint('Video init error: $e');
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

  /// Saut relatif en avant ou en arrière (±10 secondes)
  void _seekRelative(int seconds) {
    if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      final currentPos = _videoPlayerController!.value.position;
      final totalDuration = _videoPlayerController!.value.duration;
      final target = currentPos + Duration(seconds: seconds);
      final clamped = target < Duration.zero
          ? Duration.zero
          : (target > totalDuration ? totalDuration : target);

      _videoPlayerController!.seekTo(clamped);
      _showSeekIndicator(seconds > 0);
    } else if (_useWebViewFallback && _webViewController != null) {
      _webViewController?.evaluateJavascript(source: """
        (function() {
          var v = document.querySelector('video');
          if (v) {
            v.currentTime = Math.max(0, Math.min(v.duration || 999999, v.currentTime + ($seconds)));
          }
        })();
      """);
      _showSeekIndicator(seconds > 0);
    }
  }

  void _showSeekIndicator(bool isForward) {
    _indicatorTimer?.cancel();
    setState(() {
      if (isForward) {
        _showForwardIndicator = true;
        _showBackwardIndicator = false;
      } else {
        _showBackwardIndicator = true;
        _showForwardIndicator = false;
      }
    });

    _indicatorTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() {
          _showForwardIndicator = false;
          _showBackwardIndicator = false;
        });
      }
    });
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
    _indicatorTimer?.cancel();
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
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.blueAccent),
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
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                // 1. Lecteur principal (Chewie ou WebView)
                if (_useWebViewFallback)
                  _buildWebViewPlayer()
                else if (_chewieController != null)
                  Chewie(controller: _chewieController!)
                else
                  const Center(
                    child: Text(
                      'Aucune vidéo à afficher',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                // 2. Zone tactile Double Tap (Gauche = -10s, Droite = +10s)
                Positioned.fill(
                  bottom: 70, // Laisse la barre de contrôle Chewie accessible en bas
                  top: 0,
                  child: Row(
                    children: [
                      // Moitié gauche : double tap -10s
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onDoubleTap: () => _seekRelative(-10),
                        ),
                      ),
                      // Moitié droite : double tap +10s
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onDoubleTap: () => _seekRelative(10),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Indicateur visuel YouTube -10s à gauche
                if (_showBackwardIndicator)
                  Align(
                    alignment: const Alignment(-0.65, 0.0),
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          shape: BoxShape.circle,
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.replay_10,
                                color: Colors.white, size: 42),
                            SizedBox(height: 4),
                            Text(
                              '-10s',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 4. Indicateur visuel YouTube +10s à droite
                if (_showForwardIndicator)
                  Align(
                    alignment: const Alignment(0.65, 0.0),
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          shape: BoxShape.circle,
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.forward_10,
                                color: Colors.white, size: 42),
                            SizedBox(height: 4),
                            Text(
                              '+10s',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

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
            _webViewController = controller;
            final htmlContent = '''
              <!DOCTYPE html>
              <html>
              <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
                <style>
                  * { margin: 0; padding: 0; box-sizing: border-box; }
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
                <video id="player" controls autoplay playsinline preload="auto">
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
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Mode compatibilité',
                  style: TextStyle(color: Colors.grey[300], fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}