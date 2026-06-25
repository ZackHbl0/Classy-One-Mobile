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
    final audioName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    
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
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.isOnline ? const Color(0xFF10B981) : Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.isOnline 
                      ? 'En ligne' 
                      : (widget.lastSeenDiff == 'Jamais connecté' 
                          ? 'Jamais connecté' 
                          : 'En ligne ${widget.lastSeenDiff}'),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    color: widget.isOnline ? const Color(0xFF10B981) : Colors.grey.shade500,
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
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [const Color(0xFF1E1E2C), const Color(0xFF2D2D44)]
                : [const Color(0xFFE5E5F0), const Color(0xFFF1F1F8), const Color(0xFFE8E8F2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
                          
                          return _buildMessageBubble(msg, isMe, isDark);
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
          : (isDark ? const Color(0xFF334155) : Colors.white),
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
                colors: [Color(0xFFA855F7), Color(0xFF6366F1)], 
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isMe 
            ? null 
            : (isDark ? const Color(0xFF1E293B).withOpacity(0.9) : Colors.white.withOpacity(0.9)),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isMe ? 20 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 20),
        ),
        boxShadow: isMe ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
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
                  color: const Color(0xFFA855F7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (attachmentUrl != null) 
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: attachmentUrl.toLowerCase().endsWith('.jpg') || 
                       attachmentUrl.toLowerCase().endsWith('.jpeg') || 
                       attachmentUrl.toLowerCase().endsWith('.png') 
                    ? Image.network(attachmentUrl.startsWith('http') ? attachmentUrl : AuthService.baseUrl.replaceAll('/api', '') + attachmentUrl)
                    : Row(
                        children: [
                          Icon(Icons.insert_drive_file, color: isMe ? Colors.white : Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Fichier joint', style: TextStyle(color: isMe ? Colors.white : Colors.black))),
                        ],
                      )
              ),
            ),
          if (audioUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _AudioPlayerWidget(
                url: audioUrl.startsWith('http') ? audioUrl : AuthService.baseUrl.replaceAll('/api', '') + audioUrl, 
                isMe: isMe
              ),
            ),
          if (text.isNotEmpty)
            Text(
              text,
              style: GoogleFonts.inter(
                color: isMe 
                    ? Colors.white 
                    : (isDark ? Colors.white : const Color(0xFF374151)),
                fontSize: 15,
                height: 1.4,
              ),
            ),
          const SizedBox(height: 4),
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
                    color: isMe ? Colors.white70 : (isDark ? Colors.white54 : Colors.black54),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  if (msg['tick_status'] == 'sent')
                    const Icon(Icons.check, size: 14, color: Colors.white70)
                  else if (msg['tick_status'] == 'delivered')
                    const Icon(Icons.done_all, size: 14, color: Colors.white70)
                  else if (msg['tick_status'] == 'read')
                    const Icon(Icons.done_all, size: 14, color: Colors.blue)
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
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B).withOpacity(0.8) : Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: isDark ? Colors.white12 : Colors.white),
              ),
              child: _isRecording ? _buildRecordingView(isDark) : _buildNormalInput(isDark),
            ),
          ),
          const SizedBox(width: 8),
          if (_isRecording)
            GestureDetector(
              onTap: () => _stopRecording(cancel: false),
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFA855F7),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.send_rounded, color: Colors.white, size: 24),
                ),
              ),
            )
          else if (hasContent)
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFA855F7),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.send_rounded, color: Colors.white, size: 24),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _startRecording,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.8) : Colors.white.withOpacity(0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? Colors.white12 : Colors.white),
                ),
                child: Center(
                  child: Icon(
                    Icons.mic_none_rounded, 
                    color: isDark ? Colors.white70 : Colors.black54, 
                    size: 24
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNormalInput(bool isDark) {
    return Row(
      children: [
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(Icons.attach_file_rounded, color: isDark ? Colors.white54 : Colors.black54, size: 22),
          onPressed: _pickAttachment,
        ),
        Expanded(
          child: TextField(
            controller: _messageController,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendMessage(),
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Type your message...',
              hintStyle: GoogleFonts.inter(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 14,
              ),
              border: InputBorder.none,
            ),
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
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
        TextButton.icon(
          onPressed: () => _stopRecording(cancel: true),
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
          label: Text('Annuler', style: GoogleFonts.inter(color: Colors.redAccent)),
        ),
        const SizedBox(width: 8),
      ],
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
    
    // Initialiser la source
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
          // Workaround for WebM duration bug on Web (often 0 or Infinity until fully loaded)
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
    return Container(
      width: 220,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: widget.isMe ? Colors.white : const Color(0xFF6366F1),
              size: 36,
            ),
            onPressed: () async {
              if (_isPlaying) {
                await _audioPlayer.pause();
              } else {
                await _audioPlayer.play(UrlSource(widget.url));
              }
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: widget.isMe ? Colors.white : const Color(0xFF6366F1),
                    inactiveTrackColor: widget.isMe ? Colors.white38 : const Color(0xFF6366F1).withOpacity(0.3),
                    thumbColor: widget.isMe ? Colors.white : const Color(0xFF6366F1),
                  ),
                  child: Slider(
                    min: 0,
                    max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                    value: _position.inMilliseconds > 0 && _duration.inMilliseconds > 0
                        ? _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble())
                        : 0.0,
                    onChanged: (val) {
                      _audioPlayer.seek(Duration(milliseconds: val.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(color: widget.isMe ? Colors.white70 : Colors.black54, fontSize: 11),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(color: widget.isMe ? Colors.white70 : Colors.black54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
