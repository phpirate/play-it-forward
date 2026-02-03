import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/effects_manager.dart';

/// Ambient floating particles (dust, pollen, fireflies)
class AmbientParticles extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final Random _random = Random();
  final List<_AmbientParticle> _particles = [];
  final List<_Firefly> _fireflies = [];
  final List<_Butterfly> _butterflies = [];

  // Dynamic limits based on performance settings
  int get maxDustParticles => (20 * EffectsManager.instance.maxParticleMultiplier).round(); // Reduced from 40
  int get maxFireflies => (8 * EffectsManager.instance.maxParticleMultiplier).round(); // Reduced from 15
  int get maxButterflies => (4 * EffectsManager.instance.maxParticleMultiplier).round(); // Reduced from 8

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
    priority = 50;

    // Pre-spawn some particles (fewer on web)
    final preSpawnCount = EffectsManager.instance.reducedEffects ? 5 : maxDustParticles ~/ 2;
    for (int i = 0; i < preSpawnCount; i++) {
      _spawnDustParticle(randomY: true);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    final isNight = gameRef.dayNightCycle.isNightTime;
    final gameSpeed = gameRef.effectiveGameSpeed;

    // Reduced spawn rates on web
    final spawnMultiplier = EffectsManager.instance.reducedEffects ? 0.3 : 1.0;

    // Spawn dust particles
    if (_particles.length < maxDustParticles && _random.nextDouble() < 0.03 * spawnMultiplier) {
      _spawnDustParticle();
    }

    // Spawn fireflies at night
    if (isNight && _fireflies.length < maxFireflies && _random.nextDouble() < 0.015 * spawnMultiplier) {
      _spawnFirefly();
    }

    // Spawn butterflies during day
    if (!isNight && _butterflies.length < maxButterflies && _random.nextDouble() < 0.008 * spawnMultiplier) {
      _spawnButterfly();
    }

    // Update dust particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.update(dt, gameSpeed);
      if (p.position.x < -20 || p.position.y < -20 || p.position.y > gameRef.size.y + 20) {
        _particles.removeAt(i);
      }
    }

    // Update fireflies
    for (int i = _fireflies.length - 1; i >= 0; i--) {
      final f = _fireflies[i];
      f.update(dt, gameSpeed);
      if (f.position.x < -30 || !isNight) {
        _fireflies.removeAt(i);
      }
    }

    // Update butterflies
    for (int i = _butterflies.length - 1; i >= 0; i--) {
      final b = _butterflies[i];
      b.update(dt, gameSpeed);
      if (b.position.x < -40 || isNight) {
        _butterflies.removeAt(i);
      }
    }
  }

  void _spawnDustParticle({bool randomY = false}) {
    _particles.add(_AmbientParticle(
      position: Vector2(
        gameRef.size.x + 20,
        randomY ? _random.nextDouble() * gameRef.size.y : _random.nextDouble() * gameRef.size.y,
      ),
      size: 1 + _random.nextDouble() * 2,
      driftSpeed: Vector2(
        -10 - _random.nextDouble() * 20,
        _random.nextDouble() * 20 - 10,
      ),
      wobbleSpeed: 1 + _random.nextDouble() * 2,
      wobbleAmount: 10 + _random.nextDouble() * 20,
    ));
  }

  void _spawnFirefly() {
    _fireflies.add(_Firefly(
      position: Vector2(
        gameRef.size.x + 30,
        50 + _random.nextDouble() * (gameRef.size.y - 150),
      ),
      glowSpeed: 2 + _random.nextDouble() * 3,
      glowOffset: _random.nextDouble() * pi * 2,
    ));
  }

  void _spawnButterfly() {
    _butterflies.add(_Butterfly(
      position: Vector2(
        gameRef.size.x + 40,
        30 + _random.nextDouble() * (gameRef.size.y - 200),
      ),
      color: [
        const Color(0xFFFF69B4), // Pink
        const Color(0xFF87CEEB), // Sky blue
        const Color(0xFFFFD700), // Gold
        const Color(0xFFFF6347), // Tomato
        const Color(0xFF9370DB), // Purple
      ][_random.nextInt(5)],
      flapSpeed: 8 + _random.nextDouble() * 4,
    ));
  }

  @override
  void render(Canvas canvas) {
    // Render dust
    for (final p in _particles) {
      p.render(canvas);
    }

    // Render fireflies
    for (final f in _fireflies) {
      f.render(canvas);
    }

    // Render butterflies
    for (final b in _butterflies) {
      b.render(canvas);
    }
  }

  void reset() {
    _particles.clear();
    _fireflies.clear();
    _butterflies.clear();
  }
}

class _AmbientParticle {
  Vector2 position;
  final double size;
  final Vector2 driftSpeed;
  final double wobbleSpeed;
  final double wobbleAmount;
  double _time = 0;

  _AmbientParticle({
    required this.position,
    required this.size,
    required this.driftSpeed,
    required this.wobbleSpeed,
    required this.wobbleAmount,
  });

  void update(double dt, double gameSpeed) {
    _time += dt;
    position.x += (driftSpeed.x - gameSpeed * 0.02) * dt;
    position.y += driftSpeed.y * dt + sin(_time * wobbleSpeed) * wobbleAmount * dt;
  }

  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3);
    canvas.drawCircle(Offset(position.x, position.y), size, paint);
  }
}

class _Firefly {
  Vector2 position;
  final double glowSpeed;
  final double glowOffset;
  double _time = 0;
  double _moveTime = 0;
  late Vector2 _targetOffset;
  final Random _random = Random();

  _Firefly({
    required this.position,
    required this.glowSpeed,
    required this.glowOffset,
  }) {
    _targetOffset = Vector2.zero();
  }

  void update(double dt, double gameSpeed) {
    _time += dt;
    _moveTime += dt;

    // Random wandering
    if (_moveTime > 1) {
      _moveTime = 0;
      _targetOffset = Vector2(
        _random.nextDouble() * 40 - 20,
        _random.nextDouble() * 40 - 20,
      );
    }

    position.x += (-gameSpeed * 0.05 + _targetOffset.x * 0.5) * dt;
    position.y += _targetOffset.y * 0.5 * dt;
  }

  void render(Canvas canvas) {
    // Pulsing glow
    final glowIntensity = 0.3 + (sin(_time * glowSpeed + glowOffset) + 1) * 0.35;

    // Outer glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFFF00).withValues(alpha: glowIntensity * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(position.x, position.y), 10, glowPaint);

    // Inner glow
    final innerGlow = Paint()
      ..color = const Color(0xFFFFFF66).withValues(alpha: glowIntensity * 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(position.x, position.y), 5, innerGlow);

    // Core
    final corePaint = Paint()
      ..color = const Color(0xFFFFFFAA).withValues(alpha: glowIntensity);
    canvas.drawCircle(Offset(position.x, position.y), 2, corePaint);
  }
}

class _Butterfly {
  Vector2 position;
  final Color color;
  final double flapSpeed;
  double _time = 0;
  double _verticalTime = 0;

  _Butterfly({
    required this.position,
    required this.color,
    required this.flapSpeed,
  });

  void update(double dt, double gameSpeed) {
    _time += dt;
    _verticalTime += dt;

    // Gentle floating motion
    position.x += (-gameSpeed * 0.08 + sin(_time * 0.8) * 15) * dt;
    position.y += sin(_verticalTime * 1.2) * 30 * dt;
  }

  void render(Canvas canvas) {
    final wingAngle = sin(_time * flapSpeed) * 0.8;

    canvas.save();
    canvas.translate(position.x, position.y);

    // Body
    final bodyPaint = Paint()..color = Colors.black;
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 3, height: 10),
      bodyPaint,
    );

    // Left wing
    canvas.save();
    canvas.rotate(-wingAngle);
    _drawWing(canvas, -1, color);
    canvas.restore();

    // Right wing
    canvas.save();
    canvas.rotate(wingAngle);
    _drawWing(canvas, 1, color);
    canvas.restore();

    canvas.restore();
  }

  void _drawWing(Canvas canvas, double side, Color color) {
    final wingPath = Path();
    wingPath.moveTo(0, -2);
    wingPath.quadraticBezierTo(side * 12, -8, side * 10, 0);
    wingPath.quadraticBezierTo(side * 12, 6, side * 6, 8);
    wingPath.quadraticBezierTo(side * 2, 6, 0, 2);
    wingPath.close();

    final wingPaint = Paint()..color = color.withValues(alpha: 0.8);
    canvas.drawPath(wingPath, wingPaint);

    // Wing pattern
    final patternPaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    canvas.drawCircle(Offset(side * 6, -2), 2, patternPaint);
    canvas.drawCircle(Offset(side * 8, 3), 1.5, patternPaint);
  }
}
