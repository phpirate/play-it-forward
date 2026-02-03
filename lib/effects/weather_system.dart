import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/effects_manager.dart';

enum WeatherType { clear, rain, snow, leaves }

class WeatherSystem extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final Random _random = Random();
  final List<_WeatherParticle> _particles = [];

  WeatherType _currentWeather = WeatherType.clear;
  double _weatherTimer = 0;
  double _nextWeatherChange = 30; // Change weather every 30 seconds

  // Wind affects particle movement
  double _windStrength = 0;
  double _windTimer = 0;

  // Dynamic max particles based on performance settings
  int get maxParticles => (50 * EffectsManager.instance.maxParticleMultiplier).round(); // Reduced from 100

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
    priority = 100; // Render on top
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    // Update weather change timer
    _weatherTimer += dt;
    if (_weatherTimer >= _nextWeatherChange) {
      _weatherTimer = 0;
      _nextWeatherChange = 20 + _random.nextDouble() * 20;
      _changeWeather();
    }

    // Update wind
    _windTimer += dt;
    _windStrength = sin(_windTimer * 0.5) * 30 + sin(_windTimer * 1.3) * 20;

    // Spawn new particles (reduced spawn rate on web)
    final spawnChance = EffectsManager.instance.reducedEffects ? 0.3 : 1.0;
    if (_currentWeather != WeatherType.clear &&
        _particles.length < maxParticles &&
        _random.nextDouble() < spawnChance) {
      _spawnParticle();
    }

    // Update existing particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      final particle = _particles[i];
      particle.update(dt, _windStrength, gameRef.effectiveGameSpeed);

      // Remove particles that are off screen
      if (particle.position.y > gameRef.size.y + 20 ||
          particle.position.x < -50 ||
          particle.position.x > gameRef.size.x + 50) {
        _particles.removeAt(i);
      }
    }
  }

  void _changeWeather() {
    // 40% clear, 25% rain, 20% leaves, 15% snow
    final roll = _random.nextDouble();
    if (roll < 0.4) {
      _currentWeather = WeatherType.clear;
      _particles.clear();
    } else if (roll < 0.65) {
      _currentWeather = WeatherType.rain;
    } else if (roll < 0.85) {
      _currentWeather = WeatherType.leaves;
    } else {
      _currentWeather = WeatherType.snow;
    }
  }

  void _spawnParticle() {
    final x = _random.nextDouble() * (gameRef.size.x + 100) - 50;
    final y = -20.0;

    switch (_currentWeather) {
      case WeatherType.rain:
        _particles.add(_RainDrop(
          position: Vector2(x, y),
          speed: 400 + _random.nextDouble() * 200,
          length: 10 + _random.nextDouble() * 15,
        ));
        break;
      case WeatherType.snow:
        _particles.add(_Snowflake(
          position: Vector2(x, y),
          speed: 50 + _random.nextDouble() * 50,
          size: 2 + _random.nextDouble() * 4,
          wobbleOffset: _random.nextDouble() * pi * 2,
        ));
        break;
      case WeatherType.leaves:
        _particles.add(_Leaf(
          position: Vector2(x, y),
          speed: 80 + _random.nextDouble() * 60,
          size: 6 + _random.nextDouble() * 6,
          rotationSpeed: _random.nextDouble() * 4 - 2,
          color: [
            const Color(0xFFFF6B35), // Orange
            const Color(0xFFD4380D), // Red-orange
            const Color(0xFFFFC53D), // Yellow
            const Color(0xFF8B4513), // Brown
          ][_random.nextInt(4)],
        ));
        break;
      case WeatherType.clear:
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    for (final particle in _particles) {
      particle.render(canvas);
    }
  }

  void reset() {
    _particles.clear();
    _weatherTimer = 0;
    _currentWeather = WeatherType.clear;
  }

  WeatherType get currentWeather => _currentWeather;
}

abstract class _WeatherParticle {
  Vector2 position;
  double speed;

  _WeatherParticle({required this.position, required this.speed});

  void update(double dt, double wind, double gameSpeed);
  void render(Canvas canvas);
}

class _RainDrop extends _WeatherParticle {
  final double length;

  _RainDrop({
    required super.position,
    required super.speed,
    required this.length,
  });

  @override
  void update(double dt, double wind, double gameSpeed) {
    position.y += speed * dt;
    position.x += (wind - gameSpeed * 0.1) * dt;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF87CEEB).withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(position.x, position.y),
      Offset(position.x - 2, position.y + length),
      paint,
    );
  }
}

class _Snowflake extends _WeatherParticle {
  final double size;
  final double wobbleOffset;
  double _time = 0;

  _Snowflake({
    required super.position,
    required super.speed,
    required this.size,
    required this.wobbleOffset,
  });

  @override
  void update(double dt, double wind, double gameSpeed) {
    _time += dt;
    position.y += speed * dt;
    position.x += (wind + sin(_time * 2 + wobbleOffset) * 30 - gameSpeed * 0.05) * dt;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8);

    canvas.drawCircle(Offset(position.x, position.y), size, paint);

    // Add a subtle glow
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(position.x, position.y), size * 1.5, glowPaint);
  }
}

class _Leaf extends _WeatherParticle {
  final double size;
  final double rotationSpeed;
  final Color color;
  double _rotation = 0;
  double _time = 0;

  _Leaf({
    required super.position,
    required super.speed,
    required this.size,
    required this.rotationSpeed,
    required this.color,
  });

  @override
  void update(double dt, double wind, double gameSpeed) {
    _time += dt;
    _rotation += rotationSpeed * dt;
    position.y += speed * dt;
    position.x += (wind * 1.5 + sin(_time * 1.5) * 40 - gameSpeed * 0.1) * dt;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(position.x, position.y);
    canvas.rotate(_rotation);

    // Leaf shape
    final path = Path();
    path.moveTo(0, -size);
    path.quadraticBezierTo(size * 0.8, -size * 0.3, 0, size);
    path.quadraticBezierTo(-size * 0.8, -size * 0.3, 0, -size);

    final paint = Paint()..color = color;
    canvas.drawPath(path, paint);

    // Leaf vein
    final veinPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(0, -size * 0.8), Offset(0, size * 0.8), veinPaint);

    canvas.restore();
  }
}
