import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/effects_manager.dart';

/// Speed lines that appear at high velocities
class SpeedLines extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final Random _random = Random();
  final List<_SpeedLine> _lines = [];

  double _spawnTimer = 0;
  static const double speedThreshold = 400; // Speed at which lines start appearing
  int get maxLines => (15 * EffectsManager.instance.maxParticleMultiplier).round(); // Reduced from 30

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
    priority = 5; // Behind UI but in front of background
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    final speed = gameRef.effectiveGameSpeed;

    // Only show lines at high speeds
    if (speed > speedThreshold) {
      _spawnTimer += dt;

      // Spawn rate increases with speed (reduced on web)
      final baseSpawnRate = 0.04 + (speed - speedThreshold) / 2000; // Increased interval
      final spawnRate = EffectsManager.instance.reducedEffects ? baseSpawnRate * 2 : baseSpawnRate;
      if (_spawnTimer >= spawnRate && _lines.length < maxLines) {
        _spawnTimer = 0;
        _spawnLine(speed);
      }
    }

    // Update existing lines
    for (int i = _lines.length - 1; i >= 0; i--) {
      final line = _lines[i];
      line.update(dt, speed);

      if (line.isDead) {
        _lines.removeAt(i);
      }
    }
  }

  void _spawnLine(double speed) {
    // Lines appear on the sides of the screen
    final side = _random.nextBool();
    final x = side ? gameRef.size.x + 10 : gameRef.size.x * 0.7 + _random.nextDouble() * gameRef.size.x * 0.3;
    final y = _random.nextDouble() * gameRef.size.y;

    // Length based on speed
    final length = 30 + (speed - speedThreshold) / 10 + _random.nextDouble() * 40;

    // Opacity based on speed
    final opacity = ((speed - speedThreshold) / 400).clamp(0.1, 0.5);

    _lines.add(_SpeedLine(
      position: Vector2(x, y),
      length: length,
      opacity: opacity,
      thickness: 1 + _random.nextDouble() * 2,
    ));
  }

  @override
  void render(Canvas canvas) {
    for (final line in _lines) {
      line.render(canvas);
    }
  }

  void reset() {
    _lines.clear();
    _spawnTimer = 0;
  }
}

class _SpeedLine {
  Vector2 position;
  final double length;
  final double opacity;
  final double thickness;
  double life = 0;
  static const double maxLife = 0.3;

  _SpeedLine({
    required this.position,
    required this.length,
    required this.opacity,
    required this.thickness,
  });

  void update(double dt, double speed) {
    life += dt;
    position.x -= speed * dt * 1.5;
  }

  bool get isDead => life >= maxLife || position.x < -length;

  void render(Canvas canvas) {
    final progress = life / maxLife;
    final alpha = opacity * (1 - progress);

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    // Gradient fade on the line
    final gradient = LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: alpha),
        Colors.white.withValues(alpha: alpha * 0.5),
      ],
      stops: const [0.0, 0.3, 1.0],
    );

    final rect = Rect.fromLTWH(position.x - length, position.y, length, thickness);
    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(position.x - length, position.y),
      Offset(position.x, position.y),
      gradientPaint,
    );
  }
}
