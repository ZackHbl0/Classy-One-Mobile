import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  final int receiverId;
  final String receiverName;
  final bool isOnline;
  final String lastSeenDiff;
  final String targetType;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.isOnline = false,
    this.lastSeenDiff = 'Jamais connecté',
    this.targetType = 'user',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  List<dynamic> _messages = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  List<int>? _attachmentBytes;
  String? _attachmentName;
  
  bool _isRecording = false;
  bool _isSending = false;
  int _recordingDuration = 0;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchHistory(isPolling: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _recordTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory({bool isPolling = false}) async {
    final msgs = await _authService.getChatHistory(widget.receiverId, targetType: widget.targetType);
    if (!mounted) return;
    
    bool isNewMessage = _messages.length != msgs.length;
    
    setState(() {
      _messages = msgs;
      if (!isPolling) _isLoading = false;
    });

    if (isNewMessage || !isPolling) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAttachment() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _attachmentBytes = result.files.single.bytes;
        _attachmentName = result.files.single.name;
      });
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        String? path;
        if (!kIsWeb) {
          final directory = await getTemporaryDirectory();
          path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path ?? '',
        );
        setState(() {
          _isRecording = true;
          _recordingDuration = 0;
        });
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
          if (mounted) {
            setState(() {
              _recordingDuration++;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    _recordTimer?.cancel();
    if (!await _audioRecorder.isRecording()) return;

    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
    });

    if (cancel || path == null) return;

    // Wait for the file to be completely written to disk
    await Future.delayed(const Duration(milliseconds: 500));

    // Auto send audio
    final xfile = XFile(path);
    final bytes = await xfile.readAsBytes();
    final extension = kIsWeb ? 'webm' : 'm4a';
    final audioName = 'audio_${DateTime.now().millisecondsSinceEpoch}.$extension';
    
    setState(() { _isSending = true; });
    final result = await _authService.sendMessage(
      widget.receiverId, 
      '',
      receiverType: widget.targetType == 'group' ? 'group' : null,
      audioBytes: bytes,
      audioName: audioName,
    );
    setState(() { _isSending = false; });
    if (result['data'] != null || result['message'] == 'Message sent successfully.') {
      _fetchHistory();
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _attachmentBytes == null) return;
    if (_isSending || _isRecording) return;

    setState(() {
      _isSending = true;
    });

    // Optimistic UI for text only
    if (text.isNotEmpty && _attachmentBytes == null) {
      setState(() {
        final now = DateTime.now();
        final formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        _messages.add({
          'sender_id': -1, // placeholder to represent "me"
          'sender_type': 'student',
          'message': text,
          'created_at': now.toIso8601String(),
          'formatted_time': formattedTime,
          'tick_status': 'sent',
        });
      });
      _scrollToBottom();
    }

    final savedAttachmentBytes = _attachmentBytes;
    final savedAttachmentName = _attachmentName;
    
    _messageController.clear();
    setState(() {
      _attachmentBytes = null;
      _attachmentName = null;
    });

    final result = await _authService.sendMessage(
      widget.receiverId, 
      text,
      receiverType: widget.targetType == 'group' ? 'group' : null,
      attachmentBytes: savedAttachmentBytes,
      attachmentName: savedAttachmentName,
    );
    
    setState(() {
      _isSending = false;
    });

    if (result['data'] != null || result['message'] == 'Message sent successfully.') {
      _fetchHistory();
    }
  }

  String _formatDateHeader(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final msgDate = DateTime(date.year, date.month, date.day);
      
      if (msgDate == today) return "Aujourd'hui";
      if (msgDate == yesterday) return "Hier";
      
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return '';
    }
  }

  String _fixMediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) {
      if (!kIsWeb) {
        try {
          final baseUri = Uri.parse(AuthService.baseUrl);
          final originalUri = Uri.parse(url);
          if (originalUri.host == '127.0.0.1' || originalUri.host == 'localhost') {
            return originalUri.replace(host: baseUri.host, port: baseUri.port).toString();
          }
        } catch (_) {}
      }
      return url;
    }
    return AuthService.baseUrl.replaceAll('/api', '') + (url.startsWith('/') ? url : '/$url');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: [
            Text(
              widget.receiverName,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.isOnline ? const Color(0xFF5AB64B) : Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.isOnline 
                      ? 'En ligne' 
                      : (widget.lastSeenDiff == 'Jamais connecté' 
                          ? 'Jamais connecté' 
                          : 'En ligne ${widget.lastSeenDiff}'),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: widget.isOnline ? const Color(0xFF5AB64B) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF1F2937),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
              shape: BoxShape.circle,
              border: isDark ? null : Border.all(color: Colors.grey.shade200),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                shape: BoxShape.circle,
                border: isDark ? null : Border.all(color: Colors.grey.shade200),
              ),
              child: IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : const Color(0xFFF8F9FA),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['sender_type'] == 'student';
                          
                          bool showDateHeader = false;
                          String dateHeader = '';
                          if (index == 0) {
                            showDateHeader = true;
                            dateHeader = _formatDateHeader(msg['created_at']);
                          } else {
                            final prevMsg = _messages[index - 1];
                            final currentHeader = _formatDateHeader(msg['created_at']);
                            final prevHeader = _formatDateHeader(prevMsg['created_at']);
                            if (currentHeader != prevHeader && currentHeader.isNotEmpty) {
                              showDateHeader = true;
                              dateHeader = currentHeader;
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showDateHeader)
                                Center(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 24),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.grey[800] : const Color(0xFFE5E7EB),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      dateHeader,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.grey[300] : const Color(0xFF4B5563),
                                      ),
                                    ),
                                  ),
                                ),
                              _buildMessageBubble(msg, isMe, isDark),
                            ],
                          );
                        },
                      ),
              ),
              if (_attachmentBytes != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  color: isDark ? Colors.black26 : Colors.white54,
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_attachmentName ?? 'Fichier joint', overflow: TextOverflow.ellipsis)),
                      IconButton(icon: const Icon(Icons.close, size: 20, color: Colors.red), onPressed: () => setState(() { _attachmentBytes = null; _attachmentName = null; })),
                    ],
                  ),
                ),
              _buildMessageInput(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe, bool isDark) {
    final text = msg['message'] ?? '';
    final attachmentUrl = msg['attachment_url'];
    final audioUrl = msg['audio_url'];

    Widget avatar = CircleAvatar(
      radius: 14,
      backgroundColor: isMe 
          ? Colors.white.withOpacity(0.2) 
          : (isDark ? const Color(0xFF334155) : const Color(0xFFEEF2FF)),
      child: Text(
        isMe ? 'M' : widget.receiverName.substring(0, 1).toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          color: isMe 
              ? Colors.white 
              : const Color(0xFF6366F1),
        ),
      ),
    );

    Widget bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: isMe 
            ? const LinearGradient(
                colors: [Color(0xFF63D068), Color(0xFF4BAE4F)], 
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isMe 
            ? null 
            : (isDark ? const Color(0xFF2A322A) : Colors.white),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(24),
          topRight: const Radius.circular(24),
          bottomLeft: Radius.circular(isMe ? 24 : 6),
          bottomRight: Radius.circular(isMe ? 6 : 24),
        ),
        boxShadow: isMe ? [
          BoxShadow(
            color: const Color(0xFF4BAE4F).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.targetType == 'group' && !isMe && msg['sender_name'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                msg['sender_name'],
                style: GoogleFonts.inter(
                  color: const Color(0xFF5AB64B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (attachmentUrl != null) 
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: attachmentUrl.toLowerCase().endsWith('.jpg') || 
                           attachmentUrl.toLowerCase().endsWith('.jpeg') || 
                           attachmentUrl.toLowerCase().endsWith('.png') 
                        ? Image.network(
                            _fixMediaUrl(attachmentUrl),
                            fit: BoxFit.cover,
                          )
                        : Row(
                            children: [
                              Icon(Icons.insert_drive_file, color: isMe ? Colors.white : Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Fichier joint', style: TextStyle(color: isMe ? Colors.white : Colors.black))),
                            ],
                          )
                  ),
                  if (attachmentUrl.toLowerCase().endsWith('.jpg') || 
                      attachmentUrl.toLowerCase().endsWith('.jpeg') || 
                      attachmentUrl.toLowerCase().endsWith('.png'))
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.download_rounded, size: 18, color: Color(0xFF374151)),
                      ),
                    ),
                ]
              ),
            ),
          if (audioUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: _AudioPlayerWidget(
                url: _fixMediaUrl(audioUrl), 
                isMe: isMe
              ),
            ),
          if (text.isNotEmpty)
            Text(
              text,
              style: GoogleFonts.inter(
                color: isMe 
                    ? Colors.white 
                    : (isDark ? Colors.white : const Color(0xFF111827)),
                fontSize: 15,
                height: 1.4,
              ),
            ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  msg['formatted_time'] ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe ? Colors.white70 : (isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  if (msg['tick_status'] == 'sent')
                    const Icon(Icons.check, size: 14, color: Colors.white70)
                  else if (msg['tick_status'] == 'delivered')
                    const Icon(Icons.done_all, size: 14, color: Colors.white70)
                  else if (msg['tick_status'] == 'read')
                    const Icon(Icons.done_all, size: 14, color: Colors.white)
                ]
              ],
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            avatar,
            const SizedBox(width: 8),
          ],
          bubble,
          if (isMe) ...[
            const SizedBox(width: 8),
            avatar,
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    bool hasContent = _messageController.text.isNotEmpty || _attachmentBytes != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : const Color(0xFFF9FAFB),
      ),
      child: Row(
        children: [
          GestureDetector(
             onTap: _pickAttachment,
             child: Container(
               width: 42,
               height: 42,
               decoration: BoxDecoration(
                 color: const Color(0xFF6366F1).withOpacity(0.08),
                 shape: BoxShape.circle,
               ),
               child: const Icon(Icons.add, color: Color(0xFF6366F1), size: 24),
             ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A322A) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: _isRecording ? _buildRecordingView(isDark) : _buildNormalInput(isDark),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isRecording ? () => _stopRecording(cancel: false) : _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF5AB64B),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNormalInput(bool isDark) {
    return Row(
      children: [
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _messageController,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendMessage(),
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Type your message...',
              hintStyle: GoogleFonts.inter(
                color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
                fontSize: 14,
              ),
              border: InputBorder.none,
            ),
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        Icon(Icons.sentiment_satisfied_alt, color: isDark ? Colors.white54 : const Color(0xFF9CA3AF), size: 22),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _startRecording,
          child: Icon(Icons.mic_none_rounded, color: isDark ? Colors.white54 : const Color(0xFF6366F1), size: 22),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildRecordingView(bool isDark) {
    String minutes = (_recordingDuration ~/ 60).toString().padLeft(2, '0');
    String seconds = (_recordingDuration % 60).toString().padLeft(2, '0');
    return Row(
      children: [
        const SizedBox(width: 16),
        Opacity(
          opacity: _recordingDuration % 2 == 0 ? 1.0 : 0.0,
          child: const Icon(Icons.mic, color: Colors.red, size: 20),
        ),
        const SizedBox(width: 8),
        Text('$minutes:$seconds', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600)),
        const Spacer(),
        GestureDetector(
          onTap: () => _stopRecording(cancel: true),
          child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

class _StaticWaveform extends StatelessWidget {
  final bool isMe;
  final double progress;
  const _StaticWaveform({required this.isMe, required this.progress});

  @override
  Widget build(BuildContext context) {
    final heights = [10.0, 14.0, 22.0, 14.0, 18.0, 10.0, 6.0, 22.0, 18.0, 14.0, 26.0, 14.0, 10.0, 18.0, 10.0, 6.0, 14.0];
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(heights.length, (index) {
        final barProgress = index / heights.length;
        final isActive = barProgress <= progress;
        final color = isMe 
           ? (isActive ? Colors.white : Colors.white.withOpacity(0.4))
           : (isActive ? const Color(0xFF5AB64B) : const Color(0xFF5AB64B).withOpacity(0.3));
        return Container(
          width: 3,
          height: heights[index],
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

class _AudioPlayerWidget extends StatefulWidget {
  final String url;
  final bool isMe;

  const _AudioPlayerWidget({required this.url, required this.isMe});

  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    
    _audioPlayer.setSource(UrlSource(widget.url)).catchError((e) {
      debugPrint('Audio initialization error: $e');
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() { _isPlaying = state == PlayerState.playing; });
    });
    
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() { _duration = d; });
    });
    
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() { 
          _position = p; 
          if (_duration.inMilliseconds == 0 || p.inMilliseconds > _duration.inMilliseconds) {
             _duration = p;
          }
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0 
         ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0) 
         : 0.0;
         
    return Container(
      width: 240,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () async {
              if (_isPlaying) {
                await _audioPlayer.pause();
              } else {
                await _audioPlayer.play(UrlSource(widget.url));
              }
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: widget.isMe ? Colors.white : const Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                color: widget.isMe ? const Color(0xFF5AB64B) : Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: _StaticWaveform(isMe: widget.isMe, progress: progress)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.isMe ? Colors.white.withOpacity(0.2) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '1x',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: widget.isMe ? Colors.white : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(_position.inMilliseconds > 0 ? _position : _duration),
                  style: TextStyle(color: widget.isMe ? Colors.white70 : const Color(0xFF9CA3AF), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

