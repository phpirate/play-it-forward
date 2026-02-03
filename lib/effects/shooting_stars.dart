import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';

/// Shooting stars that appear at night
class ShootingStars extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final Random _random = Random();
  final List<_ShootingStar> _stars = [];

  double _spawnTimer = 0;
  double _nextSpawnTime = 5;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
    priority = 2; // Behind most elements
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    final isNight = gameRef.dayNightCycle.isNightTime;

    // Only spawn at night
    if (isNight) {
      _spawnTimer += dt;
      if (_spawnTimer >= _nextSpawnTime) {
        _spawnTimer = 0;
        _nextSpawnTime = 3 + _random.nextDouble() * 8; // 3-11 seconds
        _spawnStar();
      }
    }

    // Update existing stars
    for (int i = _stars.length - 1; i >= 0; i--) {
      final star = _stars[i];
      star.update(dt);
      if (star.isDead) {
        _stars.removeAt(i);
      }
    }
  }

  void _spawnStar() {
    // Start from top-right area, move towards bottom-left
    final startX = gameRef.size.x * 0.3 + _random.nextDouble() * gameRef.size.x * 0.7;
    final startY = _random.nextDouble() * gameRef.size.y * 0.4;

    // Random angle (mostly diagonal)
    final angle = pi * 0.6 + _random.nextDouble() * pi * 0.3;

    _stars.add(_ShootingStar(
      position: Vector2(startX, startY),
      angle: angle,
      speed: 400 + _random.nextDouble() * 300,
      length: 40 + _random.nextDouble() * 60,
      life: 0.5 + _random.nextDouble() * 0.5,
    ));
  }

  @override
  void render(Canvas canvas) {
    for (final star in _stars) {
      star.render(canvas);
    }
  }

  void reset() {
    _stars.clear();
    _spawnTimer = 0;
  }
}

class _ShootingStar {
  Vector2 position;
  final double angle;
  final double speed;
  final double length;
  final double maxLife;
  double life = 0;

  _ShootingStar({
    required this.position,
    required this.angle,
    required this.speed,
    required this.length,
    required double life,
  }) : maxLife = life;

  void update(double dt) {
    life += dt;
    position.x -= cos(angle) * speed * dt;
    position.y += sin(angle) * speed * dt;
  }

  bool get isDead => life >= maxLife;

  void render(Canvas canvas) {
    final progress = life / maxLife;
    final alpha = (1 - progress).clamp(0.0, 1.0);

    // Calculate tail end position
    final tailX = position.x + cos(angle) * length;
    final tailY = position.y - sin(angle) * length;

    // Gradient from bright head to faded tail
    final gradient = LinearGradient(
      colors: [
        Colors.white.withValues(alpha: alpha),
        Colors.white.withValues(alpha: alpha * 0.5),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 1.0],
    );

    final rect = Rect.fromPoints(
      Offset(position.x, position.y),
      Offset(tailX, tailY),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(position.x, position.y),
      Offset(tailX, tailY),
      paint,
    );

    // Bright head
    final headPaint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(position.x, position.y), 3, headPaint);
  }
}
