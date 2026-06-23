import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/character_provider.dart';
import '../models/character_state.dart';

/// 宠物角色渲染 Widget（当前为 CustomPainter 实现，后续可替换为 Live2D）
class CharacterWidget extends ConsumerWidget {
  const CharacterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(characterProvider);
    return GestureDetector(
      onTap: () => ref.read(characterProvider.notifier).greet(),
      child: Container(
        width: 280,
        height: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: CustomPaint(
            painter: _PetPainter(state),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

/// 宠物角色绘制器 — 绘制 Q 版猫/狗脸
class _PetPainter extends CustomPainter {
  final CharacterState state;
  _PetPainter(this.state);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = min(size.width, size.height) / 320;

    _drawBody(canvas, center, scale);
    _drawEars(canvas, center, scale);
    _drawEyes(canvas, center, scale);
    _drawMouth(canvas, center, scale);
    _drawBlush(canvas, center, scale);
  }

  void _drawBody(Canvas canvas, Offset center, double s) {
    final paint = Paint()
      ..color = const Color(0xFFFFF0E6) // 浅肤色
      ..style = PaintingStyle.fill;

    // 圆润的身体
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 200 * s, height: 240 * s),
      paint,
    );
  }

  void _drawEars(Canvas canvas, Offset center, double s) {
    final paint = Paint()
      ..color = const Color(0xFFFFF0E6)
      ..style = PaintingStyle.fill;

    // 左耳
    final leftEarPath = Path()
      ..moveTo(center.dx - 80 * s, center.dy - 80 * s)
      ..lineTo(center.dx - 100 * s, center.dy - 140 * s)
      ..lineTo(center.dx - 50 * s, center.dy - 90 * s)
      ..close();
    canvas.drawPath(leftEarPath, paint);

    // 右耳
    final rightEarPath = Path()
      ..moveTo(center.dx + 80 * s, center.dy - 80 * s)
      ..lineTo(center.dx + 100 * s, center.dy - 140 * s)
      ..lineTo(center.dx + 50 * s, center.dy - 90 * s)
      ..close();
    canvas.drawPath(rightEarPath, paint);

    // 耳朵内粉色
    final innerPaint = Paint()
      ..color = const Color(0xFFFFB5B5)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(center.dx - 72 * s, center.dy - 100 * s), 12 * s, innerPaint);
    canvas.drawCircle(Offset(center.dx + 72 * s, center.dy - 100 * s), 12 * s, innerPaint);
  }

  void _drawEyes(Canvas canvas, Offset center, double s) {
    final isHappy = state.emotion == PetEmotion.happy;
    final isSleepy = state.emotion == PetEmotion.sleepy;
    final isSurprised = state.emotion == PetEmotion.surprised;

    final eyeOpen = isSleepy ? 0.3 : (isSurprised ? 1.4 : 1.0);
    final eyeOffsetY = isHappy ? -4 * s : 0.0;

    // 眼睛颜色
    final eyeWhitePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = const Color(0xFF5D4037);

    // 左眼
    final leftEyeRect = Rect.fromCenter(
      center: Offset(center.dx - 35 * s, center.dy - 20 * s + eyeOffsetY),
      width: 36 * s,
      height: 28 * s * eyeOpen,
    );
    canvas.drawOval(leftEyeRect, eyeWhitePaint);

    if (!isHappy && !isSleepy) {
      canvas.drawCircle(
        Offset(center.dx - 32 * s, center.dy - 18 * s + eyeOffsetY),
        7 * s,
        pupilPaint,
      );
      // 高光
      canvas.drawCircle(
        Offset(center.dx - 35 * s, center.dy - 23 * s + eyeOffsetY),
        3 * s,
        Paint()..color = Colors.white,
      );
    } else if (isHappy) {
      // 笑眼 (弯弯的线)
      final happyEyePaint = Paint()
        ..color = const Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * s
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(center.dx - 35 * s, center.dy - 16 * s),
          width: 30 * s,
          height: 20 * s,
        ),
        pi * 1.2,
        pi * 0.6,
        false,
        happyEyePaint,
      );
    }

    // 右眼
    final rightEyeRect = Rect.fromCenter(
      center: Offset(center.dx + 35 * s, center.dy - 20 * s + eyeOffsetY),
      width: 36 * s,
      height: 28 * s * eyeOpen,
    );
    canvas.drawOval(rightEyeRect, eyeWhitePaint);

    if (!isHappy && !isSleepy) {
      canvas.drawCircle(
        Offset(center.dx + 38 * s, center.dy - 18 * s + eyeOffsetY),
        7 * s,
        pupilPaint,
      );
      canvas.drawCircle(
        Offset(center.dx + 35 * s, center.dy - 23 * s + eyeOffsetY),
        3 * s,
        Paint()..color = Colors.white,
      );
    } else if (isHappy) {
      final happyEyePaint = Paint()
        ..color = const Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * s
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(center.dx + 35 * s, center.dy - 16 * s),
          width: 30 * s,
          height: 20 * s,
        ),
        pi * 0.2,
        pi * 0.6,
        false,
        happyEyePaint,
      );
    }
  }

  void _drawMouth(Canvas canvas, Offset center, double s) {
    final isHappy = state.emotion == PetEmotion.happy;
    final isSad = state.emotion == PetEmotion.sad;
    final isSurprised = state.emotion == PetEmotion.surprised;
    final isTalking = state.emotion == PetEmotion.talking;

    final mouthPaint = Paint()
      ..color = const Color(0xFFE57373)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * s
      ..strokeCap = StrokeCap.round;

    if (isHappy) {
      // 大笑
      mouthPaint.style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + 45 * s),
          width: 32 * s,
          height: 20 * s,
        ),
        mouthPaint,
      );
      // 牙齿
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + 39 * s),
          width: 14 * s,
          height: 6 * s,
        ),
        Paint()..color = Colors.white,
      );
    } else if (isSurprised) {
      // O 型嘴
      mouthPaint.style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + 45 * s),
          width: 20 * s,
          height: 22 * s,
        ),
        mouthPaint,
      );
    } else if (isTalking) {
      // 说话中的嘴巴（根据 mouthOpenY 变化）
      mouthPaint.style = PaintingStyle.fill;
      final mouthH = 8 * s + 14 * s * state.mouthOpenY;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + 45 * s),
          width: 20 * s,
          height: mouthH,
        ),
        mouthPaint,
      );
    } else if (isSad) {
      // 难过（倒着的弧线）
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + 50 * s),
          width: 24 * s,
          height: 16 * s,
        ),
        pi * 1.2,
        pi * 0.8,
        false,
        mouthPaint,
      );
    } else {
      // 平静 (微笑弧线)
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + 42 * s),
          width: 28 * s,
          height: 16 * s,
        ),
        pi * 0.15,
        pi * 0.7,
        false,
        mouthPaint,
      );
    }
  }

  void _drawBlush(Canvas canvas, Offset center, double s) {
    final blushPaint = Paint()
      ..color = const Color(0x30FF8A80)
      ..style = PaintingStyle.fill;

    if (state.emotion == PetEmotion.happy) {
      canvas.drawCircle(Offset(center.dx - 55 * s, center.dy + 20 * s), 14 * s, blushPaint);
      canvas.drawCircle(Offset(center.dx + 55 * s, center.dy + 20 * s), 14 * s, blushPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PetPainter old) => old.state != state;
}
