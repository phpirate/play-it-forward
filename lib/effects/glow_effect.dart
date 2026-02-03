import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A pulsing glow effect component
class GlowEffect extends PositionComponent {
  final Color color;
  final double baseRadius;
  final double pulseAmount;
  final double pulseSpeed;

  double _pulseTimer = 0;
  double _currentRadius;

  GlowEffect({
    required this.color,
    required this.baseRadius,
    this.pulseAmount = 0.2,
    this.pulseSpeed = 3.0,
    Vector2? position,
  }) : _currentRadius = baseRadius,
       super(position: position ?? Vector2.zero());

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt * pulseSpeed;
    _currentRadius = baseRadius * (1 + sin(_pulseTimer) * pulseAmount);
  }

  @override
  void render(Canvas canvas) {
    final center = Offset.zero;

    // Draw multiple layers for glow effect
    for (int i = 3; i >= 0; i--) {
      final layerRadius = _currentRadius * (1 + i * 0.3);
      final layerOpacity = 0.15 / (i + 1);

      final paint = Paint()
        ..color = color.withValues(alpha: layerOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, layerRadius * 0.3);

      canvas.drawCircle(center, layerRadius, paint);
    }
  }
}

/// A ring-shaped glow that pulses outward
class GlowRing extends PositionComponent {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double pulseSpeed;

  double _pulseTimer = 0;

  GlowRing({
    required this.color,
    required this.radius,
    this.strokeWidth = 3,
    this.pulseSpeed = 2.0,
    Vector2? position,
  }) : super(position: position ?? Vector2.zero());

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt * pulseSpeed;
  }

  @override
  void render(Canvas canvas) {
    final pulseScale = 1 + sin(_pulseTimer) * 0.1;
    final currentRadius = radius * pulseScale;
    final opacity = 0.5 + sin(_pulseTimer) * 0.3;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity.clamp(0.2, 0.8))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(Offset.zero, currentRadius, paint);
  }
}

/// Gradient background glow for power-ups
class RadialGlow extends PositionComponent {
  final Color innerColor;
  final Color outerColor;
  final double radius;

  RadialGlow({
    required this.innerColor,
    Color? outerColor,
    required this.radius,
    Vector2? position,
  }) : outerColor = outerColor ?? innerColor.withValues(alpha: 0),
       super(position: position ?? Vector2.zero(), size: Vector2.all(radius * 2));

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
    final gradient = RadialGradient(
      colors: [innerColor, outerColor],
      stops: const [0.0, 1.0],
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawCircle(Offset.zero, radius, paint);
  }
}
