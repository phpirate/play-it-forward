import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';

class TerrainSegment {
  double x;
  double height;
  final PositionComponent visual;
  final List<_GrassBlade> grassBlades;
  final List<Component> decorations;

  TerrainSegment({
    required this.x,
    required this.height,
    required this.visual,
    required this.grassBlades,
    required this.decorations,
  });
}

class Ground extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final List<TerrainSegment> _segments = [];
  final double segmentWidth = 60;
  final double baseGroundY = 100;
  final Random _random = Random();

  double _nextHeight = 0;
  double _heightChangeTimer = 0;
  double _targetHeight = 0;
  bool _isTransitioning = false;
  double _windTimer = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    position = Vector2.zero();
    size = gameRef.size;

    // Create enough segments for the largest possible screen dimension (landscape)
    // Use max of width/height * 1.5 to ensure coverage during rotation
    final maxDimension = max(gameRef.size.x, gameRef.size.y) * 1.5;
    final numSegments = (maxDimension / segmentWidth).ceil() + 6;

    for (int i = 0; i < numSegments; i++) {
      _createSegment(i * segmentWidth, 0);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;

    // Check if we need more segments for the new screen size
    _ensureEnoughSegments();

    // Update existing segment positions for new screen height
    for (final segment in _segments) {
      final baseY = size.y - baseGroundY;
      segment.visual.position.y = baseY + segment.height;
      segment.visual.size = Vector2(segmentWidth + 2, baseGroundY + 50 - segment.height);
    }
  }

  void _ensureEnoughSegments() {
    if (_segments.isEmpty) return;

    // Find the rightmost segment
    double maxX = 0;
    for (final s in _segments) {
      if (s.x > maxX) maxX = s.x;
    }

    // Add more segments if needed to cover the screen width plus buffer
    final requiredWidth = gameRef.size.x + segmentWidth * 6;
    while (maxX < requiredWidth) {
      maxX += segmentWidth;
      _createSegment(maxX, _nextHeight);
    }
  }

  void _createSegment(double x, double height) {
    final baseY = gameRef.size.y - baseGroundY;

    // Main container for segment
    final visual = PositionComponent(
      position: Vector2(x, baseY + height),
      size: Vector2(segmentWidth + 2, baseGroundY + 50 - height),
    );

    // Dirt layer with gradient effect (darker at bottom)
    visual.add(CustomPainterComponent(
      painter: _DirtPainter(),
      size: Vector2(segmentWidth + 2, baseGroundY + 50 - height),
    ));

    // Grass base layer (darker green underneath)
    visual.add(RectangleComponent(
      size: Vector2(segmentWidth + 2, 12),
      position: Vector2(0, 0),
      paint: Paint()..color = const Color(0xFF1B5E20),
    ));

    // Grass blades
    final grassBlades = <_GrassBlade>[];
    for (int i = 0; i < 8; i++) {
      final blade = _GrassBlade(
        position: Vector2(i * 7.5 + _random.nextDouble() * 5, 0),
        height: 8 + _random.nextDouble() * 6,
        width: 3 + _random.nextDouble() * 2,
        phaseOffset: _random.nextDouble() * pi * 2,
      );
      grassBlades.add(blade);
      visual.add(blade);
    }

    // Decorations
    final decorations = <Component>[];

    // Random flowers
    if (_random.nextDouble() > 0.7) {
      final flower = _Flower(
        position: Vector2(10 + _random.nextDouble() * 40, -2),
        color: [
          const Color(0xFFFF6B6B), // Pink
          const Color(0xFFFFE066), // Yellow
          const Color(0xFFFFFFFF), // White
          const Color(0xFFFF69B4), // Hot pink
        ][_random.nextInt(4)],
      );
      decorations.add(flower);
      visual.add(flower);
    }

    // Random rocks
    if (_random.nextDouble() > 0.6) {
      final rock = _Rock(
        position: Vector2(5 + _random.nextDouble() * 45, 8),
        size: Vector2(6 + _random.nextDouble() * 6, 4 + _random.nextDouble() * 4),
      );
      decorations.add(rock);
      visual.add(rock);
    }

    // Small dirt patches
    if (_random.nextDouble() > 0.5) {
      visual.add(RectangleComponent(
        size: Vector2(8, 8),
        position: Vector2(15 + _random.nextDouble() * 25, 20 + _random.nextDouble() * 25),
        paint: Paint()..color = const Color(0xFF5D4037),
      ));
    }

    // Water puddles (rare)
    if (_random.nextDouble() > 0.85) {
      final puddle = _Puddle(
        position: Vector2(10 + _random.nextDouble() * 35, 10),
        puddleSize: Vector2(15 + _random.nextDouble() * 15, 6 + _random.nextDouble() * 4),
      );
      decorations.add(puddle);
      visual.add(puddle);
    }

    add(visual);

    _segments.add(TerrainSegment(
      x: x,
      height: height,
      visual: visual,
      grassBlades: grassBlades,
      decorations: decorations,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    // Update wind for grass animation
    _windTimer += dt;

    // Update all grass blades
    for (final segment in _segments) {
      for (final blade in segment.grassBlades) {
        blade.updateWind(_windTimer);
      }
    }

    // Update height transition
    _heightChangeTimer += dt;
    if (_heightChangeTimer >= 3.0) {
      _heightChangeTimer = 0;
      _generateNewTargetHeight();
    }

    if (_isTransitioning) {
      final diff = _targetHeight - _nextHeight;
      if (diff.abs() < 1) {
        _nextHeight = _targetHeight;
        _isTransitioning = false;
      } else {
        _nextHeight += diff * dt * 2;
      }
    }

    // Move and recycle segments
    for (final segment in _segments) {
      segment.x -= gameRef.effectiveGameSpeed * dt;
      segment.visual.position.x = segment.x;

      if (segment.x + segmentWidth < -10) {
        double maxX = 0;
        for (final s in _segments) {
          if (s.x > maxX) maxX = s.x;
        }

        segment.x = maxX + segmentWidth;
        segment.height = _nextHeight;

        final baseY = gameRef.size.y - baseGroundY;
        segment.visual.position = Vector2(segment.x, baseY + segment.height);
        segment.visual.size = Vector2(segmentWidth + 2, baseGroundY + 50 - segment.height);
      }
    }
  }

  void _generateNewTargetHeight() {
    final options = [-40.0, -25.0, 0.0, 0.0, 0.0, 15.0, 25.0];
    _targetHeight = options[_random.nextInt(options.length)];
    _isTransitioning = true;
  }

  double getGroundYAt(double x) {
    for (final segment in _segments) {
      if (x >= segment.x && x < segment.x + segmentWidth) {
        return gameRef.size.y - baseGroundY + segment.height;
      }
    }
    return gameRef.size.y - baseGroundY;
  }

  double getHeightAtPlayer() {
    return getGroundYAt(80);
  }

  void reset() {
    _nextHeight = 0;
    _targetHeight = 0;
    _heightChangeTimer = 0;
    _isTransitioning = false;
    _windTimer = 0;

    for (final segment in _segments) {
      segment.height = 0;
      final baseY = gameRef.size.y - baseGroundY;
      segment.visual.position.y = baseY;
      segment.visual.size = Vector2(segmentWidth + 2, baseGroundY + 50);
    }
  }
}

/// Custom painter for gradient dirt
class _DirtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF8B4513), // Saddle brown
        Color(0xFF5D4037), // Darker brown
        Color(0xFF3E2723), // Very dark brown
      ],
      stops: [0.0, 0.5, 1.0],
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Individual grass blade with wind animation
class _GrassBlade extends PositionComponent {
  final double bladeHeight;
  final double bladeWidth;
  final double phaseOffset;
  double _windOffset = 0;

  _GrassBlade({
    required Vector2 position,
    required double height,
    required double width,
    required this.phaseOffset,
  }) : bladeHeight = height,
       bladeWidth = width,
       super(position: position, size: Vector2(width, height));

  void updateWind(double windTimer) {
    _windOffset = sin(windTimer * 2 + phaseOffset) * 3;
  }

  @override
  void render(Canvas canvas) {
    final path = Path();

    // Grass blade shape (triangle that leans with wind)
    path.moveTo(bladeWidth / 2, bladeHeight); // Base center
    path.lineTo(0, bladeHeight); // Base left
    path.lineTo(bladeWidth / 2 + _windOffset, 0); // Tip (with wind)
    path.lineTo(bladeWidth, bladeHeight); // Base right
    path.close();

    // Gradient green
    final gradient = const LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        Color(0xFF2E7D32), // Dark green at base
        Color(0xFF4CAF50), // Lighter green at tip
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, bladeWidth, bladeHeight));

    canvas.drawPath(path, paint);
  }
}

/// Small flower decoration
class _Flower extends PositionComponent {
  final Color color;

  _Flower({required Vector2 position, required this.color})
      : super(position: position, size: Vector2(8, 8));

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);

    // Stem
    final stemPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(center.dx, size.y),
      Offset(center.dx, center.dy + 2),
      stemPaint,
    );

    // Petals (4 small circles around center)
    final petalPaint = Paint()..color = color;
    const petalRadius = 2.5;
    canvas.drawCircle(Offset(center.dx - 2, center.dy), petalRadius, petalPaint);
    canvas.drawCircle(Offset(center.dx + 2, center.dy), petalRadius, petalPaint);
    canvas.drawCircle(Offset(center.dx, center.dy - 2), petalRadius, petalPaint);
    canvas.drawCircle(Offset(center.dx, center.dy + 2), petalRadius, petalPaint);

    // Center (yellow)
    final centerPaint = Paint()..color = const Color(0xFFFFEB3B);
    canvas.drawCircle(center, 2, centerPaint);
  }
}

/// Small rock decoration
class _Rock extends PositionComponent {
  _Rock({required Vector2 position, required Vector2 size})
      : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // Main rock (gray oval)
    final rockPaint = Paint()..color = const Color(0xFF757575);
    canvas.drawOval(rect, rockPaint);

    // Highlight (lighter top)
    final highlightPaint = Paint()..color = const Color(0xFF9E9E9E);
    final highlightRect = Rect.fromLTWH(1, 1, size.x - 2, size.y / 2);
    canvas.drawOval(highlightRect, highlightPaint);
  }
}

/// Water puddle with reflection effect
class _Puddle extends PositionComponent {
  final Vector2 puddleSize;
  double _time = 0;

  _Puddle({required Vector2 position, required this.puddleSize})
      : super(position: position, size: puddleSize);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // Puddle base (dark water)
    final waterGradient = RadialGradient(
      center: Alignment.center,
      colors: [
        const Color(0xFF4A90D9).withValues(alpha: 0.6),
        const Color(0xFF2C5282).withValues(alpha: 0.8),
      ],
    );
    final waterPaint = Paint()..shader = waterGradient.createShader(rect);
    canvas.drawOval(rect, waterPaint);

    // Reflection shimmer (animated)
    final shimmerOffset = sin(_time * 2) * 2;
    final shimmerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3 + sin(_time * 3) * 0.1);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.3 + shimmerOffset, size.y * 0.4),
        width: size.x * 0.4,
        height: size.y * 0.3,
      ),
      shimmerPaint,
    );

    // Edge highlight
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawOval(rect.deflate(1), edgePaint);
  }
}
