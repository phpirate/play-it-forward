import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../managers/effects_manager.dart';

/// Shockwave ring that expands outward on landing
class LandingShockwave extends PositionComponent {
  double _life = 0;
  static const double maxLife = 0.4;
  final double maxRadius;

  LandingShockwave({
    required Vector2 position,
    this.maxRadius = 40,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;

    if (_life >= maxLife) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = _life / maxLife;
    final radius = maxRadius * progress;
    final alpha = (1 - progress).clamp(0.0, 1.0);

    // Outer ring
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * (1 - progress);

    canvas.drawCircle(Offset.zero, radius, ringPaint);

    // Inner ring (slightly delayed)
    if (progress > 0.1) {
      final innerProgress = (progress - 0.1) / 0.9;
      final innerRadius = maxRadius * 0.7 * innerProgress;
      final innerAlpha = (1 - innerProgress).clamp(0.0, 1.0);

      final innerPaint = Paint()
        ..color = Colors.white.withValues(alpha: innerAlpha * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * (1 - innerProgress);

      canvas.drawCircle(Offset.zero, innerRadius, innerPaint);
    }
  }
}

/// Dust cloud that appears on hard landings
class LandingDust extends PositionComponent {
  final Random _random = Random();
  final List<_DustPuff> _puffs = [];

  LandingDust({
    required Vector2 position,
    int puffCount = 8,
  }) : super(position: position, anchor: Anchor.center) {
    // Create dust puffs (reduced count on web)
    final effectivePuffCount = (puffCount * EffectsManager.instance.particleMultiplier).round().clamp(2, puffCount);
    for (int i = 0; i < effectivePuffCount; i++) {
      final angle = (i / puffCount) * pi + _random.nextDouble() * 0.3;
      _puffs.add(_DustPuff(
        angle: angle,
        speed: 40 + _random.nextDouble() * 40,
        size: 8 + _random.nextDouble() * 8,
        fadeSpeed: 1.5 + _random.nextDouble() * 0.5,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    bool allDead = true;
    for (final puff in _puffs) {
      puff.update(dt);
      if (!puff.isDead) allDead = false;
    }

    if (allDead) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    for (final puff in _puffs) {
      puff.render(canvas);
    }
  }
}

class _DustPuff {
  final double angle;
  final double speed;
  final double size;
  final double fadeSpeed;

  double _life = 0;
  double _x = 0;
  double _y = 0;

  _DustPuff({
    required this.angle,
    required this.speed,
    required this.size,
    required this.fadeSpeed,
  });

  void update(double dt) {
    _life += dt * fadeSpeed;
    _x += cos(angle) * speed * dt;
    _y -= sin(angle) * speed * dt * 0.5; // Slight upward drift
  }

  bool get isDead => _life >= 1.0;

  void render(Canvas canvas) {
    final alpha = (1 - _life).clamp(0.0, 1.0);
    final currentSize = size * (1 + _life * 0.5);

    final paint = Paint()
      ..color = const Color(0xFFD2B48C).withValues(alpha: alpha * 0.5);

    canvas.drawCircle(Offset(_x, _y), currentSize, paint);
  }
}

/// Stomp effect - special impact for stomping on birds
class StompImpact extends PositionComponent {
  final Random _random = Random();
  double _life = 0;
  static const double maxLife = 0.5;

  final List<_ImpactStar> _stars = [];

  StompImpact({
    required Vector2 position,
  }) : super(position: position, anchor: Anchor.center) {
    // Create impact stars (reduced count on web)
    final starCount = (8 * EffectsManager.instance.particleMultiplier).round().clamp(4, 8);
    for (int i = 0; i < starCount; i++) {
      final angle = (i / 8) * pi * 2;
      _stars.add(_ImpactStar(
        angle: angle,
        speed: 80 + _random.nextDouble() * 40,
        size: 4 + _random.nextDouble() * 3,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;

    for (final star in _stars) {
      star.update(dt);
    }

    if (_life >= maxLife) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = _life / maxLife;

    // Central flash
    if (progress < 0.2) {
      final flashAlpha = (1 - progress / 0.2).clamp(0.0, 1.0);
      final flashPaint = Paint()
        ..color = Colors.white.withValues(alpha: flashAlpha * 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset.zero, 20 * (1 - progress / 0.2), flashPaint);
    }

    // Impact stars
    final starAlpha = (1 - progress).clamp(0.0, 1.0);
    for (final star in _stars) {
      star.render(canvas, starAlpha);
    }

    // Expanding ring
    final ringRadius = 30 * progress;
    final ringAlpha = (1 - progress).clamp(0.0, 1.0);
    final ringPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: ringAlpha * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset.zero, ringRadius, ringPaint);
  }
}

class _ImpactStar {
  final double angle;
  final double speed;
  final double size;

  double _x = 0;
  double _y = 0;

  _ImpactStar({
    required this.angle,
    required this.speed,
    required this.size,
  });

  void update(double dt) {
    _x += cos(angle) * speed * dt;
    _y += sin(angle) * speed * dt;
  }

  void render(Canvas canvas, double alpha) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: alpha);

    // Draw 4-pointed star
    final path = Path();
    path.moveTo(_x, _y - size);
    path.lineTo(_x + size * 0.3, _y);
    path.lineTo(_x + size, _y);
    path.lineTo(_x + size * 0.3, _y);
    path.lineTo(_x, _y + size);
    path.lineTo(_x - size * 0.3, _y);
    path.lineTo(_x - size, _y);
    path.lineTo(_x - size * 0.3, _y);
    path.close();

    canvas.drawPath(path, paint);
  }
}
