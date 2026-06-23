import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'wake_word_service.dart';

/// 唤醒词管理 Provider
///
/// 使用纯 Dart VAD 方案，无需注册、无需联网、完全免费
class WakeWordNotifier extends StateNotifier<WakeWordState> {
  WakeWordService? _service;
  StreamSubscription<WakeWordState>? _sub;

  /// 检测到唤醒词时导航到聊天
  void Function()? onWakeWordDetected;

  WakeWordNotifier() : super(WakeWordState.idle);

  /// 启动监听 — 通过 VAD 检测人声唤醒
  Future<bool> startListening() async {
    if (_service != null) return true;

    _service = WakeWordService(
      onWakeWordDetected: _handleDetection,
      threshold: 0.06,  // 灵敏度：正常说话即可唤醒
      requiredHits: 3,   // 连续检测3次触发，防误触
    );

    _sub = _service!.stateStream.listen(
      (s) => state = s,
      onError: (e) => state = WakeWordState.error,
    );

    final success = await _service!.start();
    if (!success) {
      state = WakeWordState.error;
    }
    return success;
  }

  /// 停止监听
  Future<void> stopListening() async {
    await _service?.dispose();
    _service = null;
    state = WakeWordState.idle;
  }

  void _handleDetection() {
    state = WakeWordState.detected;
    onWakeWordDetected?.call();
  }

  /// 切换监听状态
  Future<void> toggle() async {
    if (state == WakeWordState.listening) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  /// 调整灵敏度 (0~1)
  void setSensitivity(double level) {
    _service?.setSensitivity(level);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service?.dispose();
    super.dispose();
  }
}

final wakeWordProvider =
    StateNotifierProvider<WakeWordNotifier, WakeWordState>((ref) {
  return WakeWordNotifier();
});
