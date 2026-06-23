/// 宠物情绪状态枚举
enum PetEmotion {
  idle,
  happy,
  sad,
  surprised,
  sleepy,
  talking,
  thinking,
  greeting;

  String get label {
    switch (this) {
      case PetEmotion.idle:
        return '平静';
      case PetEmotion.happy:
        return '开心';
      case PetEmotion.sad:
        return '难过';
      case PetEmotion.surprised:
        return '惊讶';
      case PetEmotion.sleepy:
        return '困倦';
      case PetEmotion.talking:
        return '说话';
      case PetEmotion.thinking:
        return '思考';
      case PetEmotion.greeting:
        return '打招呼';
    }
  }
}

/// 宠物角色状态
class CharacterState {
  final PetEmotion emotion;
  final bool isIdle;
  final double mouthOpenY; // 0.0 ~ 1.0, 用于口型同步
  final double eyeOpenX;   // 眼睛状态

  const CharacterState({
    this.emotion = PetEmotion.idle,
    this.isIdle = true,
    this.mouthOpenY = 0.0,
    this.eyeOpenX = 1.0,
  });

  CharacterState copyWith({
    PetEmotion? emotion,
    bool? isIdle,
    double? mouthOpenY,
    double? eyeOpenX,
  }) {
    return CharacterState(
      emotion: emotion ?? this.emotion,
      isIdle: isIdle ?? this.isIdle,
      mouthOpenY: mouthOpenY ?? this.mouthOpenY,
      eyeOpenX: eyeOpenX ?? this.eyeOpenX,
    );
  }
}
