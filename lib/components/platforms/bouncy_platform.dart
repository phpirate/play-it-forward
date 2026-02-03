import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../game/play_it_forward_game.dart';
import '../../managers/audio_manager.dart';
import '../../effects/particle_factory.dart';

/// A bouncy trampoline platform that launches the player high
class BouncyPlatform extends PositionComponent with HasGameRef<PlayItForwardGame> {
  BouncyPlatform({required Vector2 position})
      : super(
          position: position,
          size: Vector2(60, 20),
          anchor: Anchor.bottomCenter,
        );

  final double bounceForce = -700; // Strong upward force
  double _squashAmount = 0;
  double _squashVelocity = 0;
  bool _justBounced = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add hitbox - only top part is collidable
    add(RectangleHitbox(
      size: Vector2(size.x - 8, 10),
      position: Vector2(4, 0),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    // Move with game speed
    position.x -= gameRef.effectiveGameSpeed * dt;
    position.y = gameRef.ground.getGroundYAt(position.x);

    // Animate squash recovery
    if (_squashAmount != 0) {
      _squashVelocity += (0 - _squashAmount) * 30 * dt;
      _squashVelocity *= 0.85; // Damping
      _squashAmount += _squashVelocity;

      if (_squashAmount.abs() < 0.01 && _squashVelocity.abs() < 0.1) {
        _squashAmount = 0;
        _squashVelocity = 0;
      }
    }

    // Reset bounce flag
    _justBounced = false;

    // Remove when off screen
    if (position.x < -80) {
      removeFromParent();
    }

    // Check for player collision
    _checkPlayerBounce();
  }

  void _checkPlayerBounce() {
    final player = gameRef.player;

    // Check if player is above and falling onto platform
    if (player.velocityY > 0 && !_justBounced) {
      final playerBottom = player.position.y;
      final playerX = player.position.x;
      final platformTop = position.y - size.y;

      // Check horizontal overlap
      if (playerX > position.x - size.x / 2 - 20 &&
          playerX < position.x + size.x / 2 + 20) {
        // Check if player just landed on platform
        if (playerBottom >= platformTop - 5 && playerBottom <= platformTop + 15) {
          _bounce();
        }
      }
    }
  }

  void _bounce() {
    _justBounced = true;
    _squashAmount = 0.5; // Squash the platform
    _squashVelocity = -2;

    // Launch the player
    gameRef.player.velocityY = bounceForce;
    gameRef.player.isOnGround = false;

    // Play sound
    AudioManager.instance.playSfx('jump.mp3');

    // Spawn bounce particles
    final particles = ParticleFactory.createDoubleJumpRing(
      Vector2(position.x, position.y - size.y),
    );
    if (particles != null) {
      gameRef.add(particles);
    }

    // Screen shake
    gameRef.triggerScreenShake(5, 0.1);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Apply squash transformation
    canvas.save();
    canvas.translate(size.x / 2, size.y);
    canvas.scale(1 + _squashAmount * 0.3, 1 - _squashAmount);
    canvas.translate(-size.x / 2, -size.y);

    // Platform base (dark)
    final basePaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, size.y - 8, size.x - 8, 8),
        const Radius.circular(3),
      ),
      basePaint,
    );

    // Springs on sides
    _drawSpring(canvas, 8, size.y - 8);
    _drawSpring(canvas, size.x - 14, size.y - 8);

    // Bouncy top surface
    final surfaceGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFE91E63), // Pink
        Color(0xFFC2185B), // Darker pink
      ],
    );
    final surfaceRect = Rect.fromLTWH(0, 0, size.x, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(surfaceRect, const Radius.circular(5)),
      Paint()..shader = surfaceGradient.createShader(surfaceRect),
    );

    // Highlight on top
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 1, size.x - 8, 3),
        const Radius.circular(2),
      ),
      highlightPaint,
    );

    // Bounce lines (chevrons)
    final chevronPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final chevronPath = Path();
    chevronPath.moveTo(size.x / 2 - 10, 6);
    chevronPath.lineTo(size.x / 2, 3);
    chevronPath.lineTo(size.x / 2 + 10, 6);
    canvas.drawPath(chevronPath, chevronPaint);

    canvas.restore();

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y + 2),
        width: size.x - 10,
        height: 6,
      ),
      shadowPaint,
    );
  }

  void _drawSpring(Canvas canvas, double x, double y) {
    final springPaint = Paint()
      ..color = const Color(0xFF757575)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final springPath = Path();
    springPath.moveTo(x, y);
    for (int i = 0; i < 3; i++) {
      springPath.lineTo(x + 6, y - 2 - i * 3);
      springPath.lineTo(x, y - 4 - i * 3);
    }
    canvas.drawPath(springPath, springPaint);
  }
}
