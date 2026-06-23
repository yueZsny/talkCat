import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';

/// 像素猫猫状态
enum PixelCatState {
  idle, walk, happy, sad, surprised, sleep,
}

/// 像素猫猫 — 用精灵图实现 RPG 风格的像素宠物
///
/// 精灵图规格: assets/sprites/cat/cat_sheet.png
/// 每帧 32x32, 6行(动作)×4列(帧)
class PixelCat extends SpriteAnimationComponent {
  final double _tileSize;
  PixelCatState _currentState = PixelCatState.idle;

  PixelCat({
    required double tileSize,
    Vector2? position,
  }) : _tileSize = tileSize,
        super(size: Vector2.all(tileSize * 2), position: position ?? Vector2.zero());

  PixelCatState get currentState => _currentState;

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    try {
      final image = await Flame.images.load('sprites/cat/cat_sheet.png');
      final sheet = SpriteSheet(image: image, srcSize: Vector2.all(_tileSize));
      animation = sheet.createAnimation(row: 0, stepTime: 0.6, from: 0, to: 4);
      print('[PixelCat] 精灵图加载成功');
    } catch (_) {
      print('[PixelCat] 未找到精灵图，等待你画好后放入 assets/sprites/cat/');
      // 无精灵图时，使用一个空的 animation 占位
      // 实际显示的是 SpriteAnimationComponent 的空状态
    }
  }

  /// 切换到新状态
  void setState(PixelCatState state) {
    if (state == _currentState) return;
    _currentState = state;
    animationTicker?.reset();
  }
}

/// 像素猫猫游戏场景
class PixelCatGame extends FlameGame {
  late PixelCat cat;

  PixelCatGame({double tileSize = 32});

  @override
  Future<void> onLoad() async {
    cat = PixelCat(tileSize: 32, position: size / 2);
    await add(cat);
  }
}
