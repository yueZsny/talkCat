import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../voice/widgets/voice_recorder.dart';
import '../../../core/api/api_client.dart';
import '../../../core/audio/audio_service.dart';

/// 聊天输入组件 — 支持文字和语音两种输入模式
class ChatInput extends StatefulWidget {
  final void Function(String text) onSend;
  final void Function(String reply, String emotion) onVoiceReply;
  final bool isLoading;

  const ChatInput({
    super.key,
    required this.onSend,
    required this.onVoiceReply,
    this.isLoading = false,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isVoiceMode = false;
  final AudioService _audioService = AudioService();

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isLoading) return;
    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  Future<void> _handleVoiceRecorded(String audioPath) async {
    if (kIsWeb) return;
    try {
      final file = File(audioPath);
      if (!await file.exists()) return;
      final bytes = await file.readAsBytes();
      if (bytes.length < 100) return;

      final api = ApiClient();
      final response = await api.uploadBytes(
        '/voice/chat',
        bytes: bytes,
        fieldName: 'file',
        filename: 'voice.wav',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final reply = data['reply'] as String? ?? '';
        final emotion = data['emotion'] as String? ?? 'idle';
        final audioB64 = data['audio'] as String?;

        if (audioB64 != null && audioB64.isNotEmpty) {
          final audioBytes = base64Decode(audioB64);
          await _audioService.playBytes(audioBytes);
        }

        widget.onVoiceReply(reply, emotion);
      }
    } catch (e) {
      print('[Voice] 语音对话失败: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 8, 8, 16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          _ModeToggleButton(
            isVoice: _isVoiceMode,
            onToggle: () {
              setState(() => _isVoiceMode = !_isVoiceMode);
              if (!_isVoiceMode) _focusNode.requestFocus();
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _isVoiceMode
                ? _buildVoiceInput(context)
                : _buildTextInput(context),
          ),
          const SizedBox(width: 8),
          if (_isVoiceMode)
            _buildVoiceSendHint()
          else
            _buildSendButton(context),
        ],
      ),
    );
  }

  Widget _buildTextInput(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => _handleSend(),
      decoration: InputDecoration(
        hintText: widget.isLoading ? '小暖正在思考...' : '输入想说的话...',
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        isDense: true,
      ),
      style: TextStyle(fontSize: 15, color: Colors.grey[800]),
      maxLines: 3,
      minLines: 1,
    );
  }

  Widget _buildVoiceInput(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          widget.isLoading ? '小暖正在回复...' : '按住麦克风说话',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildSendButton(BuildContext context) {
    return Material(
      color: widget.isLoading
          ? Colors.grey[200]
          : Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: widget.isLoading ? null : _handleSend,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: widget.isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey[400],
                  ),
                )
              : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildVoiceSendHint() {
    if (kIsWeb) {
      return Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFFFF8C94),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.mic_off, color: Colors.white, size: 20),
      );
    }
    return VoiceRecorderButton(
      onSendAudio: _handleVoiceRecorded,
      isProcessing: widget.isLoading,
    );
  }
}

/// 语音/文字模式切换按钮
class _ModeToggleButton extends StatelessWidget {
  final bool isVoice;
  final VoidCallback onToggle;

  const _ModeToggleButton({
    required this.isVoice,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isVoice ? const Color(0xFFFF8C94) : Colors.grey[50],
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onToggle,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(
            isVoice ? Icons.keyboard : Icons.mic_none,
            color: isVoice ? Colors.white : Colors.grey[600],
            size: 20,
          ),
        ),
      ),
    );
  }
}
