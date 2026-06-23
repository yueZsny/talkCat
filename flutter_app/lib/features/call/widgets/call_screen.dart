import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/call_models.dart';
import '../providers/call_provider.dart';

/// 通话界面 — 去电/来电/通话中的全屏界面
class CallScreen extends ConsumerStatefulWidget {
  final Contact? contact;
  final CallTriggerType triggerType;

  const CallScreen({
    super.key,
    this.contact,
    this.triggerType = CallTriggerType.userRequest,
  });

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // 自动发起通话
    if (widget.contact != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(callProvider.notifier).initiateCall(
          widget.contact!,
          type: widget.triggerType,
        );
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(callProvider);
    final call = state.activeCall;
    final contact = widget.contact;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // 头像
            _buildAvatar(call, contact),
            const SizedBox(height: 24),
            // 名字
            Text(
              contact?.name ?? call?.contactName ?? '未知',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // 通话状态
            _buildStatusText(call),
            const Spacer(flex: 1),
            // 通话操作按钮
            _buildCallActions(call, context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ActiveCall? call, Contact? contact) {
    final name = contact?.name ?? call?.contactName ?? '?';
    final size = 100.0;

    // 响铃时脉冲动画
    if (call?.status == CallStatus.ringing) {
      _pulseController.repeat(reverse: true);
      return AnimatedBuilder(
        listenable: _pulseController,
        builder: (context, child) {
          return Container(
            width: size + _pulseController.value * 20,
            height: size + _pulseController.value * 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.6 - _pulseController.value * 0.3),
                width: 3,
              ),
            ),
            child: _buildAvatarContent(name, size),
          );
        },
      );
    }

    return _buildAvatarContent(name, size);
  }

  Widget _buildAvatarContent(String name, double size) {
    return Container(
      width: size,
      height: size,
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
        child: Text(
          name[0],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusText(ActiveCall? call) {
    if (call == null) return const SizedBox.shrink();

    String text;
    Color color;
    switch (call.status) {
      case CallStatus.initiating:
        text = '正在呼叫...';
        color = Colors.grey;
        break;
      case CallStatus.ringing:
        text = '正在响铃...';
        color = Colors.green;
        _pulseController.repeat(reverse: true);
        break;
      case CallStatus.connected:
        text = _formatDuration(call.durationSeconds);
        color = Colors.white;
        _pulseController.stop();
        _pulseController.reset();
        break;
      case CallStatus.completed:
        text = '通话已结束';
        color = Colors.grey;
        break;
      case CallStatus.failed:
        text = '通话失败';
        color = Colors.red;
        break;
      default:
        text = '';
        color = Colors.grey;
    }

    return Text(
      text,
      style: TextStyle(color: color, fontSize: 16),
    );
  }

  Widget _buildCallActions(ActiveCall? call, BuildContext context) {
    final isConnected = call?.status == CallStatus.connected;

    return Column(
      children: [
        if (isConnected) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CallActionButton(
                icon: call?.isMuted == true ? Icons.mic_off : Icons.mic,
                label: call?.isMuted == true ? '静音' : '静音',
                color: call?.isMuted == true ? Colors.orange : Colors.white38,
                onTap: () => ref.read(callProvider.notifier).toggleMute(),
              ),
              const SizedBox(width: 48),
              _CallActionButton(
                icon: call?.isSpeakerOn == true ? Icons.volume_up : Icons.volume_down,
                label: call?.isSpeakerOn == true ? '扬声器' : '听筒',
                color: call?.isSpeakerOn == true ? Colors.orange : Colors.white38,
                onTap: () => ref.read(callProvider.notifier).toggleSpeaker(),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
        // 挂断按钮
        Material(
          color: Colors.red,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              ref.read(callProvider.notifier).hangup();
              Future.delayed(const Duration(milliseconds: 800), () {
                if (mounted) Navigator.pop(context);
              });
            },
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              child: const Icon(Icons.call_end, color: Colors.white, size: 32),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// 通话操作按钮
class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const _CallActionButton({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color ?? Colors.white38, size: 28),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color ?? Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}

/// 简易 AnimatedBuilder（复用 voice_recorder 中的同名类）
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => builder(context, null);
}
