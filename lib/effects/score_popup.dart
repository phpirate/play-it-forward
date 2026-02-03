import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';

/// Floating score popup that appears when collecting items
class ScorePopup extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final String text;
  final Color color;
  final double fontSize;

  double _life = 0;
  static const double maxLife = 1.0;
  double _floatOffset = 0;

  ScorePopup({
    required Vector2 position,
    required this.text,
    this.color = const Color(0xFFFFD700),
    this.fontSize = 16,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);

    _life += dt;
    _floatOffset += dt * 60; // Float upward

    if (_life >= maxLife) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = _life / maxLife;
    final alpha = (1 - progress).clamp(0.0, 1.0);
    final scale = 1.0 + progress * 0.3; // Grow slightly

    // Text style
    final textStyle = TextStyle(
      color: color.withValues(alpha: alpha),
      fontSize: fontSize * scale,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: alpha * 0.5),
          offset: const Offset(1, 1),
          blurRadius: 2,
        ),
      ],
    );

    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Draw at floating position
    final offset = Offset(
      -textPainter.width / 2,
      -textPainter.height / 2 - _floatOffset,
    );
    textPainter.paint(canvas, offset);
  }
}

/// Combo popup with extra flair
class ComboPopup extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final int comboCount;

  double _life = 0;
  static const double maxLife = 1.5;
  double _floatOffset = 0;

  ComboPopup({
    required Vector2 position,
    required this.comboCount,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);

    _life += dt;
    _floatOffset += dt * 50;

    if (_life >= maxLife) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = _life / maxLife;
    final alpha = (1 - progress * 0.8).clamp(0.0, 1.0);

    // Bounce scale effect
    final bounceProgress = progress * 4;
    double scale;
    if (bounceProgress < 1) {
      scale = 0.5 + bounceProgress * 0.8; // Grow
    } else if (bounceProgress < 2) {
      scale = 1.3 - (bounceProgress - 1) * 0.2; // Shrink slightly
    } else {
      scale = 1.1;
    }

    // Combo color based on count
    Color comboColor;
    if (comboCount >= 10) {
      comboColor = const Color(0xFFFF1493); // Deep pink
    } else if (comboCount >= 7) {
      comboColor = const Color(0xFFFF4500); // Orange red
    } else if (comboCount >= 5) {
      comboColor = const Color(0xFFFFD700); // Gold
    } else if (comboCount >= 3) {
      comboColor = const Color(0xFF00FF00); // Green
    } else {
      comboColor = const Color(0xFFFFFFFF); // White
    }

    final text = '${comboCount}x COMBO!';

    // Glow effect for high combos
    if (comboCount >= 5) {
      final glowPaint = Paint()
        ..color = comboColor.withValues(alpha: alpha * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      final glowStyle = TextStyle(
        color: comboColor.withValues(alpha: alpha * 0.5),
        fontSize: 20 * scale,
        fontWeight: FontWeight.bold,
      );
      final glowSpan = TextSpan(text: text, style: glowStyle);
      final glowPainter = TextPainter(
        text: glowSpan,
        textDirection: TextDirection.ltr,
      );
      glowPainter.layout();
      glowPainter.paint(
        canvas,
        Offset(-glowPainter.width / 2, -glowPainter.height / 2 - _floatOffset),
      );
    }

    // Main text
    final textStyle = TextStyle(
      color: comboColor.withValues(alpha: alpha),
      fontSize: 18 * scale,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: alpha * 0.7),
          offset: const Offset(2, 2),
          blurRadius: 3,
        ),
      ],
    );

    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final offset = Offset(
      -textPainter.width / 2,
      -textPainter.height / 2 - _floatOffset,
    );
    textPainter.paint(canvas, offset);
  }
}
