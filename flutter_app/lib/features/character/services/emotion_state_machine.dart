import 'dart:math';
import 'dart:async';
import '../models/character_state.dart';

/// 情绪状态机 — 管理宠物情绪切换与待机行为
class EmotionStateMachine {
  PetEmotion _current = PetEmotion.idle;
  Timer? _idleTimer;
  final Random _random = Random();

  /// 当前情绪
  PetEmotion get current => _current;

  /// 从文字内容推断情绪
  PetEmotion inferFromText(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('开心') || lower.contains('哈哈') || lower.contains('😊') ||
        lower.contains('高兴') || lower.contains('喜欢') || lower.contains('love')) {
      return PetEmotion.happy;
    }
    if (lower.contains('难过') || lower.contains('伤心') || lower.contains('😢') ||
        lower.contains('哭') || lower.contains('sad')) {
      return PetEmotion.sad;
    }
    if (lower.contains('惊讶') || lower.contains('真的吗') || lower.contains('😮') ||
        lower.contains('wow') || lower.contains('真的假的')) {
      return PetEmotion.surprised;
    }
    if (lower.contains('困') || lower.contains('晚安') || lower.contains('sleep') ||
        lower.contains('累')) {
      return PetEmotion.sleepy;
    }
    return PetEmotion.idle;
  }

  /// 根据对话上下文设置情绪
  void setEmotion(PetEmotion emotion, {Duration? duration}) {
    _current = emotion;
    _cancelIdleTimer();

    // 如果不是 idle，一段时间后自动切回 idle
    if (emotion != PetEmotion.idle && duration != null) {
      _idleTimer = Timer(duration, () {
        _current = PetEmotion.idle;
      });
    }
  }

  /// 开始随机待机行为（眨眼、转头等）
  void startIdleBehavior(void Function(PetEmotion) onIdleAction) {
    _idleTimer?.cancel();
    _scheduleNextIdle(onIdleAction);
  }

  void _scheduleNextIdle(void Function(PetEmotion) onIdleAction) {
    final delay = Duration(seconds: _random.nextInt(8) + 3);
    _idleTimer = Timer(delay, () {
      if (_current == PetEmotion.idle) {
        // 随机触发一个动作
        final actions = [PetEmotion.happy, PetEmotion.sleepy, PetEmotion.surprised];
        final action = actions[_random.nextInt(actions.length)];
        onIdleAction(action);

        // 短暂显示后回到 idle
        Future.delayed(const Duration(seconds: 2), () {
          _current = PetEmotion.idle;
        });
      }
      _scheduleNextIdle(onIdleAction);
    });
  }

  void stop() {
    _idleTimer?.cancel();
  }

  void _cancelIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  void dispose() {
    stop();
  }
}
