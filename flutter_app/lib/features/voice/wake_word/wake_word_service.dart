import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';  // VoidCallback
import 'package:record/record.dart';

/// 唤醒词状态
enum WakeWordState {
  idle,
  listening,
  detected,
  error,
}

/// VAD 唤醒服务 — 纯 Dart 实现，无需注册，无需联网
///
/// 原理：通过分析麦克风音频能量，检测到人声活动即触发唤醒
/// 阈值可调节，默认对正常说话音量敏感
class WakeWordService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<RecordState>? _stateSub;
  StreamSubscription<Amplitude>? _amplitudeSub;

  WakeWordState _state = WakeWordState.idle;
  final StreamController<WakeWordState> _stateController =
      StreamController<WakeWordState>.broadcast();

  Stream<WakeWordState> get stateStream => _stateController.stream;
  WakeWordState get currentState => _state;
  bool get isListening => _state == WakeWordState.listening;

  /// 检测到唤醒时的回调
  VoidCallback? onWakeWordDetected;

  /// VAD 阈值 (RMS 振幅，0.0~1.0)
  /// 数值越低越灵敏。正常说话约 0.05~0.2，安静环境约 0.01
  double _threshold = 0.06;

  /// 触发唤醒需要持续检测到的次数（防误触）
  int _requiredHits = 3;
  int _hitCount = 0;

  WakeWordService({
    this.onWakeWordDetected,
    double? threshold,
    int? requiredHits,
  }) {
    if (threshold != null) _threshold = threshold;
    if (requiredHits != null) _requiredHits = requiredHits;
  }

  /// 开始监听 — 启动音频流并分析能量
  Future<bool> start() async {
    if (_state == WakeWordState.listening) return true;

    try {
      // 请求麦克风权限
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        print('[WakeWord] 无麦克风权限');
        _updateState(WakeWordState.error);
        return false;
      }

      // 启动音频流 (16kHz, 单声道)
      await _recorder.startStream(const RecordConfig(
        sampleRate: 16000,
        numChannels: 1,
        encoder: AudioEncoder.pcm16bits,
      ));

      _hitCount = 0;

      // 监听振幅变化 (约每秒10次)
      _amplitudeSub = _recorder.onAmplitudeChanged(
        const Duration(milliseconds: 150),
      ).listen(
        (amplitude) {
          if (_state != WakeWordState.listening) return;
          _analyzeAmplitude(amplitude.current);
        },
        onError: (e) {
          print('[WakeWord] 振幅监听错误: $e');
          _updateState(WakeWordState.error);
        },
      );

      _updateState(WakeWordState.listening);
      return true;

    } catch (e) {
      print('[WakeWord] 启动失败: $e');
      _updateState(WakeWordState.error);
      return false;
    }
  }

  /// 分析音频振幅 — 判断是否有人声活动
  void _analyzeAmplitude(double amplitude) {
    // 归一化振幅，正常说话约 0.05~0.2
    if (amplitude > _threshold) {
      _hitCount++;
      // 连续检测到足够多次 → 触发唤醒
      if (_hitCount >= _requiredHits) {
        _onWakeDetected();
        _hitCount = 0;
      }
    } else {
      // 安静下来就重置计数（但保留连续判断）
      if (_hitCount > 0) {
        _hitCount = max(0, _hitCount - 1);
      }
    }
  }

  void _onWakeDetected() {
    print('[WakeWord] 检测到人声! 唤醒!');
    _updateState(WakeWordState.detected);
    onWakeWordDetected?.call();

    // 3秒冷却后恢复监听
    Future.delayed(const Duration(seconds: 3), () {
      if (_state == WakeWordState.detected) {
        _updateState(WakeWordState.listening);
      }
    });
  }

  /// 停止监听
  Future<void> stop() async {
    _hitCount = 0;
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;

    try {
      await _recorder.stop();
    } catch (_) {}

    _updateState(WakeWordState.idle);
  }

  /// 调整灵敏度
  /// sensitivity: 0.0 (最低, 需要很大声) ~ 1.0 (最高, 很轻的声音也触发)
  void setSensitivity(double sensitivity) {
    _threshold = 0.12 - sensitivity * 0.1;
    _threshold = _threshold.clamp(0.02, 0.12);
    _requiredHits = (4 - sensitivity * 2).round().clamp(2, 4);
  }

  void _updateState(WakeWordState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    await stop();
    _stateSub?.cancel();
    await _stateController.close();
    _recorder.dispose();
  }
}
