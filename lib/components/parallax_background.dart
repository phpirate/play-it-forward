import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';

class ParallaxBackground extends PositionComponent with HasGameRef<PlayItForwardGame> {
  late _GradientSkyLayer _skyLayer;
  late _HillLayer _hillsLayer;
  late _TreeLayer _treesLayer;
  late _StarLayer _starLayer;
  late _CelestialBody _celestialBody;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    size = gameRef.size;

    // Gradient sky (with day/night colors)
    _skyLayer = _GradientSkyLayer(gameRef: gameRef);
    add(_skyLayer);

    // Stars (visible at night)
    _starLayer = _StarLayer(gameRef: gameRef);
    add(_starLayer);

    // Sun/Moon
    _celestialBody = _CelestialBody(gameRef: gameRef);
    add(_celestialBody);

    // Clouds
    add(_CloudLayer(gameRef: gameRef));

    // Distant hills with curved tops
    _hillsLayer = _HillLayer(
      y: gameRef.size.y - 250,
      height: 150,
      parallaxFactor: 0.2,
      gameRef: gameRef,
    );
    add(_hillsLayer);

    // Closer trees (actual tree shapes)
    _treesLayer = _TreeLayer(
      y: gameRef.size.y - 180,
      parallaxFactor: 0.5,
      gameRef: gameRef,
    );
    add(_treesLayer);
  }
}

class _GradientSkyLayer extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final PlayItForwardGame gameRef;

  _GradientSkyLayer({required this.gameRef});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
  }

  @override
  void render(Canvas canvas) {
    final skyColor = gameRef.dayNightCycle.getCurrentSkyColor();

    // Create a vertical gradient from lighter at top to sky color at horizon
    final lighterColor = Color.lerp(skyColor, Colors.white, 0.3) ?? skyColor;
    final darkerColor = Color.lerp(skyColor, const Color(0xFF1a1a2e), 0.2) ?? skyColor;

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [lighterColor, skyColor, darkerColor],
      stops: const [0.0, 0.5, 1.0],
    );

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }
}

class _StarLayer extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final PlayItForwardGame gameRef;
  final List<_Star> _stars = [];
  final Random _random = Random();
  double _twinkleTimer = 0;

  _StarLayer({required this.gameRef});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Create 30 stars at random positions
    for (int i = 0; i < 30; i++) {
      final star = _Star(
        position: Vector2(
          _random.nextDouble() * gameRef.size.x,
          _random.nextDouble() * (gameRef.size.y * 0.5),
        ),
        radius: 1 + _random.nextDouble() * 1.5,
        twinkleOffset: _random.nextDouble() * 2 * pi,
      );
      _stars.add(star);
      add(star);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _twinkleTimer += dt * 3;

    final isNight = gameRef.dayNightCycle.isNightTime;
    final nightProgress = gameRef.dayNightCycle.nightProgress;

    for (final star in _stars) {
      if (isNight) {
        // Fade in stars during night
        final baseOpacity = nightProgress.clamp(0.0, 1.0);
        final twinkle = 0.3 + 0.7 * ((sin(_twinkleTimer + star.twinkleOffset) + 1) / 2);
        star.opacity = baseOpacity * twinkle;
      } else {
        star.opacity = 0;
      }
    }
  }
}

class _Star extends CircleComponent {
  final double twinkleOffset;
  double _opacity = 0;

  _Star({
    required Vector2 position,
    required double radius,
    required this.twinkleOffset,
  }) : super(
          position: position,
          radius: radius,
          paint: Paint()..color = Colors.white,
        );

  set opacity(double value) {
    _opacity = value;
    paint.color = Colors.white.withValues(alpha: _opacity);
  }
}

/// Sun and Moon component
class _CelestialBody extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final PlayItForwardGame gameRef;
  double _sunRayRotation = 0;

  _CelestialBody({required this.gameRef});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(60, 60);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _sunRayRotation += dt * 0.5;

    // Position based on day/night cycle
    final progress = gameRef.dayNightCycle.cycleProgress;
    final isDay = !gameRef.dayNightCycle.isNightTime;

    // Arc path across the sky
    final arcProgress = isDay ? progress : (progress - 0.5) * 2;
    final x = gameRef.size.x * 0.1 + gameRef.size.x * 0.8 * arcProgress.clamp(0.0, 1.0);
    final y = gameRef.size.y * 0.15 + sin(arcProgress.clamp(0.0, 1.0) * pi) * -50;

    position = Vector2(x, y);
  }

  @override
  void render(Canvas canvas) {
    final isNight = gameRef.dayNightCycle.isNightTime;
    final center = Offset(size.x / 2, size.y / 2);

    if (isNight) {
      _drawMoon(canvas, center);
    } else {
      _drawSun(canvas, center);
    }
  }

  void _drawSun(Canvas canvas, Offset center) {
    // Sun glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, 35, glowPaint);

    // Sun rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final angle = _sunRayRotation + (i * pi / 4);
      final innerRadius = 22.0;
      final outerRadius = 32.0;
      final startX = center.dx + cos(angle) * innerRadius;
      final startY = center.dy + sin(angle) * innerRadius;
      final endX = center.dx + cos(angle) * outerRadius;
      final endY = center.dy + sin(angle) * outerRadius;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), rayPaint);
    }

    // Sun body gradient
    final sunGradient = RadialGradient(
      colors: [
        const Color(0xFFFFEB3B), // Bright yellow center
        const Color(0xFFFFD700), // Gold
        const Color(0xFFFFA500), // Orange edge
      ],
      stops: const [0.0, 0.6, 1.0],
    );
    final sunRect = Rect.fromCircle(center: center, radius: 20);
    final sunPaint = Paint()..shader = sunGradient.createShader(sunRect);
    canvas.drawCircle(center, 20, sunPaint);

    // Sun highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawCircle(Offset(center.dx - 6, center.dy - 6), 6, highlightPaint);
  }

  void _drawMoon(Canvas canvas, Offset center) {
    // Moon glow
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, 28, glowPaint);

    // Moon body gradient
    final moonGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        const Color(0xFFF5F5F5), // Bright white
        const Color(0xFFE0E0E0), // Light gray
        const Color(0xFFBDBDBD), // Medium gray edge
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    final moonRect = Rect.fromCircle(center: center, radius: 18);
    final moonPaint = Paint()..shader = moonGradient.createShader(moonRect);
    canvas.drawCircle(center, 18, moonPaint);

    // Moon craters
    final craterPaint = Paint()..color = const Color(0xFFBDBDBD);
    canvas.drawCircle(Offset(center.dx - 5, center.dy - 3), 4, craterPaint);
    canvas.drawCircle(Offset(center.dx + 6, center.dy + 5), 3, craterPaint);
    canvas.drawCircle(Offset(center.dx - 2, center.dy + 8), 2, craterPaint);

    // Moon highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4);
    canvas.drawCircle(Offset(center.dx - 6, center.dy - 6), 5, highlightPaint);
  }
}

/// Hill layer with curved tops
class _HillLayer extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final double parallaxFactor;
  final PlayItForwardGame gameRef;
  final List<_HillSegment> _segments = [];
  final double segmentWidth = 200;
  final Random _random = Random(42); // Fixed seed for consistent hills

  _HillLayer({
    required double y,
    required double height,
    required this.parallaxFactor,
    required this.gameRef,
  }) : super(position: Vector2(0, y), size: Vector2(0, height));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size.x = gameRef.size.x;

    final numSegments = (gameRef.size.x / segmentWidth).ceil() + 2;
    for (int i = 0; i < numSegments; i++) {
      _createSegment(i * segmentWidth);
    }
  }

  void _createSegment(double x) {
    final segment = _HillSegment(
      position: Vector2(x, 0),
      hillWidth: segmentWidth,
      hillHeight: size.y,
      peakOffset: _random.nextDouble() * 40 - 20,
      gameRef: gameRef,
    );
    _segments.add(segment);
    add(segment);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing || parallaxFactor == 0) return;

    for (final segment in _segments) {
      segment.position.x -= gameRef.effectiveGameSpeed * parallaxFactor * dt;

      if (segment.position.x + segmentWidth < 0) {
        double maxX = 0;
        for (final s in _segments) {
          if (s.position.x > maxX) maxX = s.position.x;
        }
        segment.position.x = maxX + segmentWidth;
      }
    }
  }
}

class _HillSegment extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final double hillWidth;
  final double hillHeight;
  final double peakOffset;
  final PlayItForwardGame gameRef;

  _HillSegment({
    required Vector2 position,
    required this.hillWidth,
    required this.hillHeight,
    required this.peakOffset,
    required this.gameRef,
  }) : super(position: position, size: Vector2(hillWidth, hillHeight));

  @override
  void render(Canvas canvas) {
    final color = gameRef.dayNightCycle.getHillColor();
    final darkerColor = Color.lerp(color, Colors.black, 0.2) ?? color;

    // Create curved hill path
    final path = Path();
    path.moveTo(0, size.y);
    path.lineTo(0, size.y * 0.4 + peakOffset);

    // Curved top using quadratic bezier
    path.quadraticBezierTo(
      size.x * 0.25,
      size.y * 0.1 + peakOffset,
      size.x * 0.5,
      size.y * 0.3,
    );
    path.quadraticBezierTo(
      size.x * 0.75,
      size.y * 0.5 - peakOffset * 0.5,
      size.x,
      size.y * 0.35 + peakOffset,
    );

    path.lineTo(size.x, size.y);
    path.close();

    // Gradient fill
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color, darkerColor],
    );
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawPath(path, paint);
  }
}

/// Tree layer with actual tree shapes
class _TreeLayer extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final double parallaxFactor;
  final PlayItForwardGame gameRef;
  final List<_TreeCluster> _clusters = [];
  final double clusterWidth = 150;
  final Random _random = Random(123); // Fixed seed for consistent trees

  _TreeLayer({
    required double y,
    required this.parallaxFactor,
    required this.gameRef,
  }) : super(position: Vector2(0, y));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(gameRef.size.x, 100);

    final numClusters = (gameRef.size.x / clusterWidth).ceil() + 2;
    for (int i = 0; i < numClusters; i++) {
      _createCluster(i * clusterWidth);
    }
  }

  void _createCluster(double x) {
    final cluster = _TreeCluster(
      position: Vector2(x, 0),
      clusterWidth: clusterWidth,
      treeSeed: _random.nextInt(1000),
      gameRef: gameRef,
    );
    _clusters.add(cluster);
    add(cluster);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing || parallaxFactor == 0) return;

    for (final cluster in _clusters) {
      cluster.position.x -= gameRef.effectiveGameSpeed * parallaxFactor * dt;

      if (cluster.position.x + clusterWidth < 0) {
        double maxX = 0;
        for (final c in _clusters) {
          if (c.position.x > maxX) maxX = c.position.x;
        }
        cluster.position.x = maxX + clusterWidth;
      }
    }
  }
}

class _TreeCluster extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final double clusterWidth;
  final int treeSeed;
  final PlayItForwardGame gameRef;
  late Random _random;

  _TreeCluster({
    required Vector2 position,
    required this.clusterWidth,
    required this.treeSeed,
    required this.gameRef,
  }) : super(position: position, size: Vector2(clusterWidth, 100)) {
    _random = Random(treeSeed);
  }

  @override
  void render(Canvas canvas) {
    final treeColor = gameRef.dayNightCycle.getTreeColor();
    final trunkColor = Color.lerp(treeColor, const Color(0xFF3E2723), 0.7) ?? const Color(0xFF5D4037);

    // Reset random for consistent rendering
    _random = Random(treeSeed);

    // Draw 2-3 trees per cluster
    final treeCount = 2 + _random.nextInt(2);
    for (int i = 0; i < treeCount; i++) {
      final treeX = _random.nextDouble() * (clusterWidth - 40) + 20;
      final treeHeight = 50 + _random.nextDouble() * 30;
      final treeWidth = 30 + _random.nextDouble() * 20;
      final isConifer = _random.nextBool();

      _drawTree(canvas, treeX, treeHeight, treeWidth, treeColor, trunkColor, isConifer);
    }
  }

  void _drawTree(Canvas canvas, double x, double height, double width,
      Color canopyColor, Color trunkColor, bool isConifer) {
    final trunkWidth = width * 0.2;
    final trunkHeight = height * 0.35;

    // Trunk
    final trunkPaint = Paint()..color = trunkColor;
    canvas.drawRect(
      Rect.fromLTWH(x - trunkWidth / 2, size.y - trunkHeight, trunkWidth, trunkHeight),
      trunkPaint,
    );

    // Canopy
    final canopyPaint = Paint()..color = canopyColor;
    final lighterCanopy = Paint()..color = Color.lerp(canopyColor, Colors.white, 0.2) ?? canopyColor;

    if (isConifer) {
      // Triangle/conifer tree
      final path = Path();
      path.moveTo(x, size.y - height);
      path.lineTo(x - width / 2, size.y - trunkHeight);
      path.lineTo(x + width / 2, size.y - trunkHeight);
      path.close();
      canvas.drawPath(path, canopyPaint);

      // Highlight on left side
      final highlightPath = Path();
      highlightPath.moveTo(x, size.y - height);
      highlightPath.lineTo(x - width / 4, size.y - height * 0.6);
      highlightPath.lineTo(x - width / 2, size.y - trunkHeight);
      highlightPath.close();
      canvas.drawPath(highlightPath, lighterCanopy);
    } else {
      // Round/deciduous tree
      final canopyY = size.y - trunkHeight - height * 0.4;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, canopyY),
          width: width,
          height: height * 0.7,
        ),
        canopyPaint,
      );

      // Highlight
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x - width * 0.15, canopyY - height * 0.1),
          width: width * 0.5,
          height: height * 0.35,
        ),
        lighterCanopy,
      );
    }
  }
}

class _CloudLayer extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final PlayItForwardGame gameRef;
  final List<_Cloud> _clouds = [];

  _CloudLayer({required this.gameRef});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add some clouds
    _clouds.add(_Cloud(position: Vector2(100, 80), gameRef: gameRef));
    _clouds.add(_Cloud(position: Vector2(300, 50), gameRef: gameRef));
    _clouds.add(_Cloud(position: Vector2(500, 100), gameRef: gameRef));

    for (final cloud in _clouds) {
      add(cloud);
    }
  }
}

class _Cloud extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final PlayItForwardGame gameRef;
  final List<CircleComponent> _circles = [];

  _Cloud({required Vector2 position, required this.gameRef})
      : super(position: position);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final paint = Paint()..color = Colors.white.withValues(alpha: 0.8);

    final c1 = CircleComponent(radius: 25, paint: paint, position: Vector2(0, 10));
    final c2 = CircleComponent(radius: 30, paint: paint, position: Vector2(20, 0));
    final c3 = CircleComponent(radius: 25, paint: paint, position: Vector2(45, 10));

    _circles.addAll([c1, c2, c3]);
    add(c1);
    add(c2);
    add(c3);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    // Adjust cloud opacity based on time of day
    final isNight = gameRef.dayNightCycle.isNightTime;
    final opacity = isNight ? 0.3 : 0.8;
    for (final circle in _circles) {
      circle.paint.color = Colors.white.withValues(alpha: opacity);
    }

    position.x -= gameRef.effectiveGameSpeed * 0.1 * dt;

    if (position.x < -100) {
      position.x = gameRef.size.x + 50;
    }
  }
}
