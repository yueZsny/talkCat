import 'dart:async';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/audio/audio_service.dart';

/// 语音录制按钮 — 按住录音，松开发送
class VoiceRecorderButton extends StatefulWidget {
  final void Function(String path) onSendAudio;
  final bool isProcessing;

  const VoiceRecorderButton({
    super.key,
    required this.onSendAudio,
    this.isProcessing = false,
  });

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton>
    with SingleTickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  StreamSubscription<double>? _amplitudeSub;
  double _amplitude = 0.0;
  bool _isRecording = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _amplitudeSub?.cancel();
    _audioService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final success = await _audioService.startRecording();
    if (!success || !mounted) return;

    setState(() => _isRecording = true);
    _pulseController.repeat(reverse: true);

    _amplitudeSub = _audioService.getAmplitudeStream().listen((amp) {
      if (mounted) setState(() => _amplitude = amp);
    });
  }

  Future<void> _stopRecording() async {
    _pulseController.stop();
    _pulseController.reset();
    _amplitudeSub?.cancel();

    final path = await _audioService.stopRecording();

    if (mounted) {
      setState(() {
        _isRecording = false;
        _amplitude = 0.0;
      });
    }

    if (!kIsWeb && path != null) {
      final file = File(path);
      if (file.lengthSync() > 1000) {
        widget.onSendAudio(path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      onLongPressCancel: () async => await _stopRecording(),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isRecording ? _pulseAnimation.value : 1.0,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getMicColor(),
                shape: BoxShape.circle,
                boxShadow: _isRecording
                    ? [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: _amplitude * 0.5),
                          blurRadius: 12 + _amplitude * 20,
                          spreadRadius: _amplitude * 8,
                        ),
                      ]
                    : null,
              ),
              child: _buildMicIcon(),
            ),
          );
        },
      ),
    );
  }

  Color _getMicColor() {
    if (widget.isProcessing) return Colors.grey[300]!;
    if (_isRecording) return Colors.red.withValues(alpha: 0.8);
    return const Color(0xFFFF8C94);
  }

  Widget _buildMicIcon() {
    if (widget.isProcessing) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.grey[400],
        ),
      );
    }
    if (_isRecording) {
      return const Icon(Icons.mic, color: Colors.white, size: 20);
    }
    return const Icon(Icons.mic_none, color: Colors.white, size: 20);
  }
}
