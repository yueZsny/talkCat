import 'dart:async';
import 'package:flutter/services.dart';
import 'package:porcupine_flutter/porcupine.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:porcupine_flutter/porcupine_error.dart';

/// 唤醒词状态
enum WakeWordState {
  idle,
  listening,
  detected,
  error,
}

/// 唤醒词服务 — 监听"小猫小猫"唤醒宠物
class WakeWordService {
  PorcupineManager? _manager;
  WakeWordState _state = WakeWordState.idle;
  final StreamController<WakeWordState> _stateController =
      StreamController<WakeWordState>.broadcast();

  Stream<WakeWordState> get stateStream => _stateController.stream;
  WakeWordState get currentState => _state;
  bool get isListening => _state == WakeWordState.listening;

  VoidCallback? onWakeWordDetected;

  final String _accessKey;
  final String? _customKeywordPath;

  WakeWordService({
    required String accessKey,
    String? customKeywordPath,
    this.onWakeWordDetected,
  })  : _accessKey = accessKey,
        _customKeywordPath = customKeywordPath;

  /// 初始化并开始监听
  Future<bool> start() async {
    if (_state == WakeWordState.listening) return true;

    try {
      if (_customKeywordPath != null) {
        // 使用自定义唤醒词 "小猫小猫" (.ppn 文件放在 assets/wake_word/)
        _manager = await PorcupineManager.fromKeywordPaths(
          _accessKey,
          [_customKeywordPath],
          _onDetection,
          sensitivities: [0.5],
          errorCallback: _onError,
        );
      } else {
        // 开发模式：使用内置 "Porcupine" 关键词测试
        // 后续配置 .ppn 文件后会切换为 "小猫小猫"
        _manager = await PorcupineManager.fromBuiltInKeywords(
          _accessKey,
          [BuiltInKeyword.PORCUPINE],
          _onDetection,
          sensitivities: [0.5],
          errorCallback: _onError,
        );
      }

      await _manager!.start();
      _updateState(WakeWordState.listening);
      return true;
    } on PorcupineException catch (e) {
      print('[WakeWord] 启动失败: ${e.message}');
      _updateState(WakeWordState.error);
      return false;
    } catch (e) {
      print('[WakeWord] 启动异常: $e');
      _updateState(WakeWordState.error);
      return false;
    }
  }

  /// 停止监听
  Future<void> stop() async {
    try {
      await _manager?.stop();
      _updateState(WakeWordState.idle);
    } catch (e) {
      print('[WakeWord] 停止失败: $e');
    }
  }

  void _onDetection(int keywordIndex) {
    print('[WakeWord] 🐱 小猫小猫! 唤醒成功!');
    _updateState(WakeWordState.detected);
    onWakeWordDetected?.call();

    // 3秒后恢复监听
    Future.delayed(const Duration(seconds: 3), () {
      if (_state == WakeWordState.detected) {
        _updateState(WakeWordState.listening);
      }
    });
  }

  void _onError(PorcupineException error) {
    print('[WakeWord] 错误: ${error.message}');
    _updateState(WakeWordState.error);
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
    await _manager?.delete();
    await _stateController.close();
  }
}
