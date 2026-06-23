import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character_state.dart';
import '../services/emotion_state_machine.dart';

/// 角色状态 Provider — 管理宠物情绪与动画
class CharacterNotifier extends StateNotifier<CharacterState> {
  final EmotionStateMachine _machine = EmotionStateMachine();

  CharacterNotifier() : super(const CharacterState()) {
    _startIdleBehavior();
  }

  /// 设置情绪
  void setEmotion(PetEmotion emotion, {Duration? duration}) {
    _machine.setEmotion(emotion, duration: duration);
    state = state.copyWith(emotion: emotion, isIdle: emotion == PetEmotion.idle);
  }

  /// 从文字推断情绪
  void inferEmotionFromText(String text) {
    final emotion = _machine.inferFromText(text);
    setEmotion(emotion, duration: const Duration(seconds: 5));
  }

  /// 开始说话 (口型动画)
  void startTalking() {
    state = state.copyWith(
      emotion: PetEmotion.talking,
      isIdle: false,
      mouthOpenY: 0.5,
    );
  }

  /// 停止说话
  void stopTalking() {
    state = state.copyWith(
      mouthOpenY: 0.0,
    );
    setEmotion(PetEmotion.idle);
  }

  /// 打招呼
  void greet() {
    setEmotion(PetEmotion.greeting, duration: const Duration(seconds: 3));
  }

  void _startIdleBehavior() {
    _machine.startIdleBehavior((emotion) {
      if (mounted) {
        state = state.copyWith(emotion: emotion);
      }
    });
  }

  @override
  void dispose() {
    _machine.dispose();
    super.dispose();
  }
}

final characterProvider = StateNotifierProvider<CharacterNotifier, CharacterState>((ref) {
  return CharacterNotifier();
});

/// 宠物名称
final petNameProvider = Provider<String>((ref) => '小暖');

/// 是否为活跃对话中
final isPetActiveProvider = StateProvider<bool>((ref) => false);
