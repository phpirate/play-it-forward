import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/power_up_manager.dart';
import '../managers/tutorial_manager.dart';
import '../effects/particle_factory.dart';

class PowerUp extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final PowerUpType type;

  PowerUp({required this.type, required Vector2 position})
      : super(position: position, size: Vector2(40, 40), anchor: Anchor.center);

  bool isCollected = false;
  double _bobTime = 0;
  double _startY = 0;
  final double bobAmount = 6;
  final double bobSpeed = 2.5;

  // Animation timers
  double _glowTime = 0;
  double _iconAnimTime = 0;
  final double glowSpeed = 2.5;
  final double iconAnimSpeed = 3.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _startY = position.y;

    // Add collision hitbox
    add(CircleHitbox(radius: 18, position: Vector2(2, 2)));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing || isCollected) return;

    // Update animation timers
    _glowTime += dt * glowSpeed;
    _iconAnimTime += dt * iconAnimSpeed;

    // Move left with game (use effective speed for slow motion)
    position.x -= gameRef.effectiveGameSpeed * dt;

    // Bob up and down
    _bobTime += dt * bobSpeed;
    position.y = _startY + sin(_bobTime * pi * 2) * bobAmount;

    // Tutorial hint when power-up is visible
    if (position.x < gameRef.size.x * 0.8) {
      TutorialManager.instance.tryShowHint(TutorialManager.hintPowerUp);
    }

    // Remove when off screen
    if (position.x < -50) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);
    final baseColor = _getColorForType();

    // Draw outer glow ring (pulsing)
    _drawGlowRing(canvas, center, baseColor);

    // Draw shadow
    _drawShadow(canvas, center);

    // Draw base circle with gradient
    _drawBaseCircle(canvas, center, baseColor);

    // Draw icon based on type
    switch (type) {
      case PowerUpType.shield:
        _drawShieldIcon(canvas, center);
        break;
      case PowerUpType.magnet:
        _drawMagnetIcon(canvas, center);
        break;
      case PowerUpType.doubleScore:
        _drawDoubleScoreIcon(canvas, center);
        break;
      case PowerUpType.slowMotion:
        _drawClockIcon(canvas, center);
        break;
    }
  }

  void _drawGlowRing(Canvas canvas, Offset center, Color color) {
    final glowScale = 1.0 + sin(_glowTime) * 0.15;
    final glowOpacity = 0.3 + sin(_glowTime) * 0.15;

    // Outer glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: glowOpacity * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, 22 * glowScale, glowPaint);

    // Glow ring
    final ringPaint = Paint()
      ..color = color.withValues(alpha: glowOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 20 * glowScale, ringPaint);
  }

  void _drawShadow(Canvas canvas, Offset center) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 18), width: 28, height: 8),
      shadowPaint,
    );
  }

  void _drawBaseCircle(Canvas canvas, Offset center, Color baseColor) {
    final lighterColor = Color.lerp(baseColor, Colors.white, 0.3) ?? baseColor;
    final darkerColor = Color.lerp(baseColor, Colors.black, 0.3) ?? baseColor;

    // Gradient background
    final gradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [lighterColor, baseColor, darkerColor],
      stops: const [0.0, 0.5, 1.0],
    );
    final rect = Rect.fromCircle(center: center, radius: 16);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawCircle(center, 16, paint);

    // Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4);
    canvas.drawCircle(Offset(center.dx - 5, center.dy - 5), 5, highlightPaint);
  }

  void _drawShieldIcon(Canvas canvas, Offset center) {
    // Animated shine rotation
    final shineAngle = _iconAnimTime;

    // Shield shape
    final path = Path();
    path.moveTo(center.dx, center.dy - 10);
    path.lineTo(center.dx + 8, center.dy - 6);
    path.lineTo(center.dx + 8, center.dy + 2);
    path.quadraticBezierTo(center.dx + 6, center.dy + 8, center.dx, center.dy + 10);
    path.quadraticBezierTo(center.dx - 6, center.dy + 8, center.dx - 8, center.dy + 2);
    path.lineTo(center.dx - 8, center.dy - 6);
    path.close();

    final shieldPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawPath(path, shieldPaint);

    // Rotating shine line
    final shineX = center.dx + cos(shineAngle) * 4;
    final shinePaint = Paint()
      ..color = const Color(0xFF87CEEB).withValues(alpha: 0.8)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(shineX - 3, center.dy - 6),
      Offset(shineX + 1, center.dy + 4),
      shinePaint,
    );
  }

  void _drawMagnetIcon(Canvas canvas, Offset center) {
    // Pulsing poles
    final pulseScale = 1.0 + sin(_iconAnimTime * 2) * 0.1;

    // U-shape magnet
    final magnetPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(center.dx - 6, center.dy - 8);
    path.lineTo(center.dx - 6, center.dy + 2);
    path.quadraticBezierTo(center.dx - 6, center.dy + 8, center.dx, center.dy + 8);
    path.quadraticBezierTo(center.dx + 6, center.dy + 8, center.dx + 6, center.dy + 2);
    path.lineTo(center.dx + 6, center.dy - 8);
    canvas.drawPath(path, magnetPaint);

    // Pole caps (pulsing)
    final leftPolePaint = Paint()..color = const Color(0xFFFF4444);
    final rightPolePaint = Paint()..color = const Color(0xFF4444FF);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx - 6, center.dy - 10),
        width: 6 * pulseScale,
        height: 4,
      ),
      leftPolePaint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx + 6, center.dy - 10),
        width: 6 * pulseScale,
        height: 4,
      ),
      rightPolePaint,
    );
  }

  void _drawDoubleScoreIcon(Canvas canvas, Offset center) {
    // Bouncing 2x
    final bounceOffset = sin(_iconAnimTime * 2) * 2;

    // Draw "2x" text manually
    // "2"
    final twoPath = Path();
    twoPath.moveTo(center.dx - 8, center.dy - 6 + bounceOffset);
    twoPath.lineTo(center.dx - 2, center.dy - 6 + bounceOffset);
    twoPath.lineTo(center.dx - 2, center.dy - 2 + bounceOffset);
    twoPath.lineTo(center.dx - 8, center.dy - 2 + bounceOffset);
    twoPath.lineTo(center.dx - 8, center.dy + 2 + bounceOffset);
    twoPath.lineTo(center.dx - 2, center.dy + 2 + bounceOffset);
    twoPath.lineTo(center.dx - 2, center.dy + 6 + bounceOffset);
    twoPath.lineTo(center.dx - 8, center.dy + 6 + bounceOffset);

    canvas.drawPath(twoPath, Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);

    // "x"
    final xPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx + 2, center.dy - 4 + bounceOffset),
      Offset(center.dx + 8, center.dy + 4 + bounceOffset),
      xPaint,
    );
    canvas.drawLine(
      Offset(center.dx + 8, center.dy - 4 + bounceOffset),
      Offset(center.dx + 2, center.dy + 4 + bounceOffset),
      xPaint,
    );
  }

  void _drawClockIcon(Canvas canvas, Offset center) {
    // Rotating hands
    final handAngle = _iconAnimTime;

    // Clock face
    final facePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawCircle(center, 9, facePaint);

    // Clock outline
    final outlinePaint = Paint()
      ..color = const Color(0xFF4B0082)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 9, outlinePaint);

    // Hour hand (short, moves slowly)
    final hourPaint = Paint()
      ..color = const Color(0xFF4B0082)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + cos(handAngle * 0.5 - pi / 2) * 4,
        center.dy + sin(handAngle * 0.5 - pi / 2) * 4,
      ),
      hourPaint,
    );

    // Minute hand (long, moves faster)
    final minutePaint = Paint()
      ..color = const Color(0xFF4B0082)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + cos(handAngle - pi / 2) * 7,
        center.dy + sin(handAngle - pi / 2) * 7,
      ),
      minutePaint,
    );

    // Center dot
    canvas.drawCircle(center, 1.5, Paint()..color = const Color(0xFF4B0082));
  }

  void collect() {
    if (!isCollected) {
      isCollected = true;

      // Spawn colored burst particles based on power-up type
      final color = _getColorForType();
      final burst = ParticleFactory.createPowerUpBurst(position, color);
      if (burst != null) {
        gameRef.add(burst);
      }

      removeFromParent();
    }
  }

  Color _getColorForType() {
    switch (type) {
      case PowerUpType.shield:
        return const Color(0xFF4169E1); // Royal blue
      case PowerUpType.magnet:
        return const Color(0xFFDC143C); // Crimson
      case PowerUpType.doubleScore:
        return const Color(0xFFFFD700); // Gold
      case PowerUpType.slowMotion:
        return const Color(0xFF9370DB); // Medium purple
    }
  }
}
