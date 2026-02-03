import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/power_up_manager.dart';
import '../managers/character_manager.dart';
import '../models/character.dart';
import '../effects/particle_factory.dart';

class Coin extends PositionComponent with HasGameRef<PlayItForwardGame> {
  Coin({required Vector2 position})
      : super(position: position, size: Vector2(30, 30), anchor: Anchor.center);

  bool isCollected = false;
  double _bobTime = 0;
  double _startY = 0;
  final double bobAmount = 5;
  final double bobSpeed = 3;
  final double magnetRange = 200;
  final double magnetSpeed = 400;

  // Rotation animation
  double _rotationTime = 0;
  final double rotationSpeed = 4;

  // Glow animation
  double _glowTime = 0;
  final double glowSpeed = 2;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _startY = position.y;
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing || isCollected) return;

    // Update animations
    _rotationTime += dt * rotationSpeed;
    _glowTime += dt * glowSpeed;

    // Check for magnet power-up or Wizard's magnet aura ability
    final magnetActive = gameRef.powerUpManager.isActive(PowerUpType.magnet);
    final hasWizardAura = CharacterManager.instance.selectedCharacter.ability == CharacterAbility.magnetAura;

    // Wizard aura provides a smaller passive magnet effect
    final effectiveRange = magnetActive ? magnetRange : (hasWizardAura ? magnetRange * 0.6 : 0.0);
    final effectiveSpeed = magnetActive ? magnetSpeed : (hasWizardAura ? magnetSpeed * 0.7 : 0.0);

    if (effectiveRange > 0) {
      final playerPos = gameRef.player.position;
      final distance = position.distanceTo(playerPos);

      if (distance < effectiveRange) {
        final direction = (playerPos - position).normalized();
        position += direction * effectiveSpeed * dt;
        _startY = position.y;
      } else {
        position.x -= gameRef.effectiveGameSpeed * dt;
      }
    } else {
      position.x -= gameRef.effectiveGameSpeed * dt;
    }

    // Bob up and down
    if (!magnetActive ||
        position.distanceTo(gameRef.player.position) >= magnetRange) {
      _bobTime += dt * bobSpeed;
      position.y = _startY + sin(_bobTime * pi * 2) * bobAmount;
    }

    if (position.x < -50) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);

    // Calculate rotation scale (simulates 3D rotation)
    final rotationScale = cos(_rotationTime).abs().clamp(0.3, 1.0);

    // Glow effect (pulsing)
    final glowOpacity = 0.2 + sin(_glowTime) * 0.1;
    final glowRadius = 18 + sin(_glowTime) * 3;

    // Draw glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: glowOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, glowRadius, glowPaint);

    // Coin shadow (underneath)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 12),
        width: 20 * rotationScale,
        height: 6,
      ),
      shadowPaint,
    );

    // Main coin body (scaled for rotation effect)
    final coinRect = Rect.fromCenter(
      center: center,
      width: 26 * rotationScale,
      height: 26,
    );

    // Outer coin (gold)
    final outerGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFFFE082), // Light gold
        const Color(0xFFFFD700), // Gold
        const Color(0xFFFFA000), // Darker gold
      ],
    );
    final outerPaint = Paint()
      ..shader = outerGradient.createShader(coinRect);
    canvas.drawOval(coinRect, outerPaint);

    // Inner coin detail (lighter)
    final innerRect = Rect.fromCenter(
      center: center,
      width: 18 * rotationScale,
      height: 18,
    );
    final innerGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFFFECB3), // Very light gold
        const Color(0xFFFFE082), // Light gold
      ],
    );
    final innerPaint = Paint()
      ..shader = innerGradient.createShader(innerRect);
    canvas.drawOval(innerRect, innerPaint);

    // Star symbol in center (only visible when facing forward)
    if (rotationScale > 0.5) {
      _drawStar(canvas, center, 6 * rotationScale, const Color(0xFFFFA000));
    }

    // Edge highlight (simulates 3D edge)
    if (rotationScale < 0.8) {
      final edgeX = center.dx + (13 * rotationScale);
      final edgePaint = Paint()
        ..color = const Color(0xFFB8860B)
        ..strokeWidth = 2 * (1 - rotationScale);
      canvas.drawLine(
        Offset(edgeX, center.dy - 12),
        Offset(edgeX, center.dy + 12),
        edgePaint,
      );
    }

    // Shine highlight (top-left)
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawCircle(
      Offset(center.dx - 5 * rotationScale, center.dy - 5),
      4,
      shinePaint,
    );
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    final paint = Paint()..color = color;

    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * pi / 180;
      final innerAngle = ((i * 72) + 36 - 90) * pi / 180;

      final outerX = center.dx + cos(outerAngle) * radius;
      final outerY = center.dy + sin(outerAngle) * radius;
      final innerX = center.dx + cos(innerAngle) * radius * 0.4;
      final innerY = center.dy + sin(innerAngle) * radius * 0.4;

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  void collect() {
    if (!isCollected) {
      isCollected = true;

      final sparkle = ParticleFactory.createCoinSparkle(position);
      if (sparkle != null) {
        gameRef.add(sparkle);
      }

      removeFromParent();
    }
  }
}
