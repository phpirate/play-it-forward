import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/audio_manager.dart';
import '../effects/score_popup.dart';
import 'obstacle.dart';
import 'bird.dart';

/// A stone projectile thrown by the player while riding a bird
class Stone extends PositionComponent
    with HasGameRef<PlayItForwardGame>, CollisionCallbacks {

  final Vector2 velocity;
  double _rotation = 0;
  double _lifetime = 0;
  static const double maxLifetime = 3.0;

  // Reward for destroying obstacles
  static const int obstacleCoins = 5;
  static const int birdCoins = 3;

  Stone({
    required Vector2 position,
    required this.velocity,
  }) : super(
          position: position,
          size: Vector2(16, 16),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add collision hitbox
    add(CircleHitbox(radius: 8));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    // Move stone
    position += velocity * dt;

    // Add slight gravity
    velocity.y += 200 * dt;

    // Rotate while flying
    _rotation += dt * 10;

    // Track lifetime
    _lifetime += dt;
    if (_lifetime >= maxLifetime) {
      removeFromParent();
      return;
    }

    // Remove if off screen
    if (position.x > gameRef.size.x + 50 ||
        position.x < -50 ||
        position.y > gameRef.size.y + 50) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Obstacle) {
      _destroyObstacle(other);
    } else if (other is Bird && !other.isStomped) {
      _destroyBird(other);
    }
  }

  void _destroyObstacle(Obstacle obstacle) {
    // Award coins
    gameRef.coins += obstacleCoins;

    // Show popup
    gameRef.add(ScorePopup(
      position: obstacle.position + Vector2(0, -20),
      text: '+${obstacleCoins * 10}',
      color: Colors.green,
      fontSize: 18,
    ));

    // Spawn destruction particles
    _spawnDestructionEffect(obstacle.position + obstacle.size / 2);

    // Play sound
    AudioManager.instance.playSfx('coin.mp3');

    // Remove obstacle and stone
    obstacle.removeFromParent();
    removeFromParent();
  }

  void _destroyBird(Bird bird) {
    // Award coins
    gameRef.coins += birdCoins;

    // Show popup
    gameRef.add(ScorePopup(
      position: bird.position + Vector2(0, -20),
      text: '+${birdCoins * 10}',
      color: Colors.orange,
      fontSize: 18,
    ));

    // Mark as stomped and remove
    bird.stomp();

    // Play sound
    AudioManager.instance.playSfx('coin.mp3');

    // Remove stone
    removeFromParent();
  }

  void _spawnDestructionEffect(Vector2 pos) {
    // Add rock debris particles
    final random = Random();
    for (int i = 0; i < 6; i++) {
      final debris = _Debris(
        position: pos.clone(),
        velocity: Vector2(
          random.nextDouble() * 200 - 100,
          random.nextDouble() * -200 - 50,
        ),
      );
      gameRef.add(debris);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(_rotation);
    canvas.translate(-size.x / 2, -size.y / 2);

    // Stone body (irregular rock shape)
    final stonePath = Path();
    stonePath.moveTo(8, 0);
    stonePath.lineTo(14, 3);
    stonePath.lineTo(16, 8);
    stonePath.lineTo(14, 14);
    stonePath.lineTo(8, 16);
    stonePath.lineTo(2, 13);
    stonePath.lineTo(0, 7);
    stonePath.lineTo(3, 2);
    stonePath.close();

    // Stone gradient
    final stoneGradient = const RadialGradient(
      center: Alignment(-0.3, -0.3),
      colors: [
        Color(0xFF9E9E9E), // Light gray
        Color(0xFF616161), // Dark gray
      ],
    );
    final stoneRect = Rect.fromLTWH(0, 0, 16, 16);
    final stonePaint = Paint()
      ..shader = stoneGradient.createShader(stoneRect);
    canvas.drawPath(stonePath, stonePaint);

    // Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4);
    canvas.drawCircle(const Offset(5, 5), 3, highlightPaint);

    // Motion blur trail
    final trailPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-5, 8), width: 12, height: 6),
      trailPaint,
    );

    canvas.restore();
  }
}

/// Debris particle from destroyed obstacle
class _Debris extends PositionComponent {
  final Vector2 velocity;
  double _life = 1.0;
  final double _size;
  final Color _color;

  _Debris({
    required Vector2 position,
    required this.velocity,
  })  : _size = 4 + Random().nextDouble() * 6,
        _color = [
          const Color(0xFF8B4513),
          const Color(0xFF5D4037),
          const Color(0xFF795548),
          const Color(0xFF6D4C41),
        ][Random().nextInt(4)],
        super(position: position);

  @override
  void update(double dt) {
    super.update(dt);

    // Move
    position += velocity * dt;
    velocity.y += 400 * dt; // Gravity

    // Fade out
    _life -= dt * 1.5;
    if (_life <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = _color.withValues(alpha: _life);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: _size,
        height: _size,
      ),
      paint,
    );
  }
}
