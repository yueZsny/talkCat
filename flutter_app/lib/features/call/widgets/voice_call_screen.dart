import 'dart:async';
import 'dart:io' show File;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/api/api_client.dart';
import '../../../core/audio/audio_service.dart';

/// 通话连接状态
enum VoiceCallState {
  connecting,
  speaking,
  thinking,
  responding,
  error,
}

/// 实时语音通话界面 — 像打电话一样和宠物对话
class VoiceCallScreen extends StatefulWidget {
  final String contactName;

  const VoiceCallScreen({
    super.key,
    this.contactName = '小暖',
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with SingleTickerProviderStateMixin {
  final AudioService _audio = AudioService();
  final ApiClient _api = ApiClient();
  VoiceCallState _callState = VoiceCallState.connecting;
  String _lastReply = '';
  int _round = 0;
  int _duration = 0;
  Timer? _timer;
  StreamSubscription<double>? _amplitudeSub;
  double _amplitude = 0.0;
  bool _isSpeaking = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCall());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeSub?.cancel();
    _audio.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _startCall() async {
    setState(() => _callState = VoiceCallState.connecting);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    setState(() {
      _callState = VoiceCallState.thinking;
      _duration = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _duration++);
    });

    // AI 先打招呼
    await _aiTalk('你好呀！我是小暖～今天想聊点什么呢？😊');
    _startListening();
  }

  Future<void> _startListening() async {
    if (kIsWeb) return;
    final started = await _audio.startRecording(maxDurationSec: 10);
    if (!started || !mounted) return;

    setState(() {
      _callState = VoiceCallState.speaking;
      _isSpeaking = false;
    });
    _pulseCtrl.repeat(reverse: true);

    _amplitudeSub = _audio.getAmplitudeStream().listen((amp) {
      if (!mounted) return;
      setState(() => _amplitude = amp);
      _isSpeaking = amp > 0.03;
    });

    // 3秒后处理（简化的VAD）
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _handleUserSpeech();
    });
  }

  Future<void> _handleUserSpeech() async {
    if (_callState == VoiceCallState.thinking) return;
    _amplitudeSub?.cancel();
    _pulseCtrl.stop();
    _pulseCtrl.reset();

    setState(() => _callState = VoiceCallState.thinking);
    _round++;

    final audioPath = await _audio.stopRecording();
    String reply;

    try {
      if (audioPath != null && !kIsWeb) {
        final file = File(audioPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          if (bytes.length > 1000) {
            final resp = await _api.uploadBytes(
              '/voice/chat',
              bytes: bytes,
              fieldName: 'file',
              filename: 'voice.wav',
            );
            final data = resp.data as Map<String, dynamic>;
            reply = data['reply'] as String? ?? '';
          } else {
            reply = _getFallback();
          }
        } else {
          reply = _getFallback();
        }
      } else {
        reply = _getFallback();
      }
    } catch (e) {
      print('[VoiceCall] 错误: $e');
      reply = _getFallback();
    }

    await _aiTalk(reply);

    if (mounted && _round < 8) {
      _startListening();
    } else if (mounted) {
      await _aiTalk('和你聊天好开心！下次再聊哦～拜拜！👋');
      _endCall();
    }
  }

  String _getFallback() {
    final msgs = [
      '嗯嗯～我在听呢！你说～👂',
      '原来是这样呀！然后呢？😊',
      '哈哈，好有意思！🥰',
      '真的吗？好棒呀！✨',
      '我懂我懂～继续说～💕',
    ];
    return msgs[_round % msgs.length];
  }

  Future<void> _aiTalk(String text) async {
    if (!mounted) return;
    setState(() {
      _lastReply = text;
      _callState = VoiceCallState.responding;
    });

    if (!kIsWeb) {
      try {
        final resp = await _api.post('/voice/tts', data: {'text': text});
        if (resp.statusCode == 200 && mounted) {
          final data = resp.data;
          List<int> audioData;
          if (data is List<int>) {
            audioData = data;
          } else if (data is List) {
            audioData = data.cast<int>();
          } else {
            audioData = [];
          }
          if (audioData.isNotEmpty) {
            _pulseCtrl.repeat(reverse: true);
            await _audio.playBytes(audioData);
            _pulseCtrl.stop();
            _pulseCtrl.reset();
          }
        }
      } catch (_) {}
    }

    // 模拟说话耗时
    await Future.delayed(Duration(milliseconds: text.length * 30));
    if (mounted) {
      setState(() => _callState = VoiceCallState.speaking);
    }
  }

  void _endCall() {
    _timer?.cancel();
    _amplitudeSub?.cancel();
    _audio.stopRecording();
    _audio.stopPlayback();
    if (mounted) setState(() => _callState = VoiceCallState.connecting);
  }

  String get _durationStr {
    final m = (_duration ~/ 60).toString().padLeft(2, '0');
    final s = (_duration % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _statusText {
    switch (_callState) {
      case VoiceCallState.connecting:
        return '正在连接...';
      case VoiceCallState.speaking:
        return _isSpeaking ? '👂 听到你了...' : '🎤 说吧，我在听';
      case VoiceCallState.thinking:
        return '💭 小暖思考中...';
      case VoiceCallState.responding:
        return '🗣️ 小暖说话中...';
      case VoiceCallState.error:
        return '❌ 连接异常';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Text(_durationStr,
                      style: const TextStyle(color: Colors.white38, fontSize: 14)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white38),
                    onPressed: () {
                      _endCall();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                final scale = (_callState == VoiceCallState.speaking ||
                        _callState == VoiceCallState.responding)
                    ? _pulseAnim.value
                    : 1.0;
                return Transform.scale(scale: scale, child: _buildAvatar());
              },
            ),
            const SizedBox(height: 20),
            Text(widget.contactName,
                style: const TextStyle(
                    color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _statusText,
              style: TextStyle(
                color: _callState == VoiceCallState.speaking
                    ? Colors.green[300]
                    : Colors.grey[400],
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            if (_callState == VoiceCallState.speaking) _buildWaveform(),
            if (_lastReply.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _lastReply,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                _endCall();
                Navigator.pop(context);
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.call_end, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C94), Color(0xFFFF6B81)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C94).withValues(alpha: 0.4),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text('🐱', style: TextStyle(fontSize: 40 + (_amplitude * 10))),
      ),
    );
  }

  Widget _buildWaveform() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: CustomPaint(
        painter: _WaveformPainter(amplitude: _amplitude),
        size: const Size(double.infinity, 40),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double amplitude;
  _WaveformPainter({this.amplitude = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF8C94).withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final barCount = 20;
    final barWidth = size.width / barCount;
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final barHeight = max(
        4.0,
        size.height * 0.8 * amplitude * (0.3 + 0.7 * sin(i * 0.5 + DateTime.now().millisecondsSinceEpoch * 0.01)),
      );
      final x = i * barWidth + barWidth / 2;
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) => old.amplitude != amplitude;
}

