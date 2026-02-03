import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/tutorial_manager.dart';

/// A soul collectible that gives the player an extra life
/// Rarer than coins, ghostly ethereal appearance
class Soul extends PositionComponent with HasGameRef<PlayItForwardGame> {
  Soul({required Vector2 position})
      : super(
          position: position,
          size: Vector2(30, 35),
          anchor: Anchor.center,
        );

  bool _collected = false;
  double _floatTime = 0;
  double _glowPulse = 0;
  double _rotationAngle = 0;
  final Random _random = Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add collision hitbox
    add(CircleHitbox(radius: 12, position: Vector2(3, 5)));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_collected) return;
    if (gameRef.gameState != GameState.playing) return;

    // Move with game speed
    position.x -= gameRef.effectiveGameSpeed * dt;

    // Floating animation
    _floatTime += dt * 2;
    position.y += sin(_floatTime) * 0.5;

    // Glow pulse
    _glowPulse += dt * 3;

    // Slow rotation
    _rotationAngle += dt * 0.5;

    // Tutorial hint when soul is visible
    if (position.x < gameRef.size.x * 0.8) {
      TutorialManager.instance.tryShowHint(TutorialManager.hintSoul);
    }

    // Remove when off screen
    if (position.x < -50) {
      removeFromParent();
    }
  }

  void collect() {
    if (_collected) return;
    _collected = true;
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_collected) return;

    final center = Offset(size.x / 2, size.y / 2);
    final glowIntensity = 0.3 + sin(_glowPulse) * 0.2;

    // Outer glow (pulsing)
    final outerGlowPaint = Paint()
      ..color = const Color(0xFF00FFFF).withValues(alpha: glowIntensity * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, 20, outerGlowPaint);

    // Middle glow
    final midGlowPaint = Paint()
      ..color = const Color(0xFF80FFFF).withValues(alpha: glowIntensity * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, 14, midGlowPaint);

    // Save for rotation
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_rotationAngle);
    canvas.translate(-center.dx, -center.dy);

    // Ghost body (teardrop/ghost shape)
    final ghostPath = Path();
    ghostPath.moveTo(center.dx, center.dy - 12); // Top
    ghostPath.quadraticBezierTo(
      center.dx + 12, center.dy - 8,
      center.dx + 10, center.dy + 5,
    );
    // Wavy bottom
    ghostPath.quadraticBezierTo(
      center.dx + 8, center.dy + 12,
      center.dx + 4, center.dy + 10,
    );
    ghostPath.quadraticBezierTo(
      center.dx + 2, center.dy + 14,
      center.dx, center.dy + 12,
    );
    ghostPath.quadraticBezierTo(
      center.dx - 2, center.dy + 14,
      center.dx - 4, center.dy + 10,
    );
    ghostPath.quadraticBezierTo(
      center.dx - 8, center.dy + 12,
      center.dx - 10, center.dy + 5,
    );
    ghostPath.quadraticBezierTo(
      center.dx - 12, center.dy - 8,
      center.dx, center.dy - 12,
    );
    ghostPath.close();

    // Ghost gradient fill
    final ghostGradient = RadialGradient(
      center: const Alignment(0, -0.3),
      radius: 1.0,
      colors: [
        Colors.white.withValues(alpha: 0.95),
        const Color(0xFFE0FFFF).withValues(alpha: 0.85),
        const Color(0xFF80FFFF).withValues(alpha: 0.6),
      ],
    );
    final ghostRect = Rect.fromCircle(center: center, radius: 15);
    canvas.drawPath(
      ghostPath,
      Paint()..shader = ghostGradient.createShader(ghostRect),
    );

    // Ghost outline
    canvas.drawPath(
      ghostPath,
      Paint()
        ..color = const Color(0xFF00FFFF).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.restore();

    // Eyes (cute dot eyes)
    final eyePaint = Paint()..color = const Color(0xFF006666);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - 4, center.dy - 4),
        width: 4,
        height: 5,
      ),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + 4, center.dy - 4),
        width: 4,
        height: 5,
      ),
      eyePaint,
    );

    // Eye shine
    final shinePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(center.dx - 5, center.dy - 5), 1.5, shinePaint);
    canvas.drawCircle(Offset(center.dx + 3, center.dy - 5), 1.5, shinePaint);

    // Small smile
    final smilePaint = Paint()
      ..color = const Color(0xFF006666)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final smilePath = Path();
    smilePath.moveTo(center.dx - 3, center.dy + 2);
    smilePath.quadraticBezierTo(center.dx, center.dy + 5, center.dx + 3, center.dy + 2);
    canvas.drawPath(smilePath, smilePaint);

    // Sparkles around the soul
    _drawSparkles(canvas, center, glowIntensity);
  }

  void _drawSparkles(Canvas canvas, Offset center, double intensity) {
    final sparklePaint = Paint()..color = Colors.white.withValues(alpha: intensity);

    // Draw 4 sparkles at cardinal points
    for (int i = 0; i < 4; i++) {
      final angle = _rotationAngle * 2 + (i * pi / 2);
      final distance = 18 + sin(_glowPulse + i) * 3;
      final x = center.dx + cos(angle) * distance;
      final y = center.dy + sin(angle) * distance;

      // Star sparkle shape
      final sparkleSize = 2 + sin(_glowPulse * 2 + i) * 1;
      canvas.drawCircle(Offset(x, y), sparkleSize, sparklePaint);
    }
  }
}
