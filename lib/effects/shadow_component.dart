import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A drop shadow component that renders an oval shadow beneath objects
class ShadowComponent extends PositionComponent {
  final double baseWidth;
  final double baseHeight;
  final double maxOpacity;

  double _currentOpacity;
  late Paint _paint;

  ShadowComponent({
    required this.baseWidth,
    this.baseHeight = 8,
    this.maxOpacity = 0.3,
    Vector2? position,
  }) : _currentOpacity = maxOpacity,
       super(position: position ?? Vector2.zero(), size: Vector2(baseWidth, baseHeight));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _updatePaint();
  }

  void _updatePaint() {
    _paint = Paint()
      ..color = Colors.black.withValues(alpha: _currentOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  }

  /// Update shadow based on object's height from ground
  /// Higher objects have smaller, more transparent shadows
  void updateForHeight(double heightFromGround) {
    final normalizedHeight = (heightFromGround / 150).clamp(0.0, 1.0);

    // Shadow gets smaller and more transparent as object rises
    final scaleFactor = 1.0 - (normalizedHeight * 0.5);
    size = Vector2(baseWidth * scaleFactor, baseHeight * scaleFactor);

    _currentOpacity = maxOpacity * (1.0 - normalizedHeight * 0.7);
    _updatePaint();
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: size.x,
      height: size.y,
    );
    canvas.drawOval(rect, _paint);
  }
}

/// A simple static shadow for ground-level objects
class GroundShadow extends PositionComponent {
  final double width;
  final double height;
  final double opacity;

  late Paint _paint;

  GroundShadow({
    required this.width,
    this.height = 6,
    this.opacity = 0.25,
    Vector2? position,
  }) : super(position: position ?? Vector2.zero(), size: Vector2(width, height));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _paint = Paint()
      ..color = Colors.black.withValues(alpha: opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawOval(rect, _paint);
  }
}
