import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'wake_word_service.dart';

/// 唤醒词管理 Provider
class WakeWordNotifier extends StateNotifier<WakeWordState> {
  WakeWordService? _service;
  StreamSubscription<WakeWordState>? _sub;

  // 回调 — 检测到唤醒词时导航到聊天
  void Function()? onWakeWordDetected;

  WakeWordNotifier() : super(WakeWordState.idle);

  /// Picovoice Access Key (免费, 替换为你的 key)
  /// 获取: https://console.picovoice.ai/
  static const String _accessKey = 'YOUR_ACCESS_KEY_HERE';

  /// 自定义 .ppn 文件路径
  /// 在 Picovoice Console 训练"小猫小猫"后替换此路径
  static const String? _customPpnPath = null; // 'assets/wake_word/xiaomao_xiaomao.ppn';

  /// 启动唤醒词监听
  Future<bool> startListening() async {
    if (_service != null) return true;

    _service = WakeWordService(
      accessKey: _accessKey,
      customKeywordPath: _customPpnPath,
      onWakeWordDetected: _handleDetection,
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
