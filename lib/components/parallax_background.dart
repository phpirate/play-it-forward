import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/level_manager.dart';

class ParallaxBackground extends PositionComponent with HasGameRef<PlayItForwardGame> {
  late _GradientSkyLayer _skyLayer;
  late _HillLayer _hillsLayer;
  late _TreeLayer _treesLayer;
  late _StarLayer _starLayer;
  late _CelestialBody _celestialBody;
  late _FlowerLayer _flowerLayer;
  late _RainbowLayer _rainbowLayer;
  late _SkyBirdLayer _skyBirdLayer;
  late _VillageLayer _villageLayer;
  late _CelebrationLayer _celebrationLayer;

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

    // Rainbow (appears in later levels)
    _rainbowLayer = _RainbowLayer(gameRef: gameRef);
    add(_rainbowLayer);

    // Sun/Moon
    _celestialBody = _CelestialBody(gameRef: gameRef);
    add(_celestialBody);

    // Clouds
    add(_CloudLayer(gameRef: gameRef));

    // Decorative birds in sky (appears in later levels)
    _skyBirdLayer = _SkyBirdLayer(gameRef: gameRef);
    add(_skyBirdLayer);

    // Distant hills with curved tops
    _hillsLayer = _HillLayer(
      y: gameRef.size.y - 250,
      height: 150,
      parallaxFactor: 0.2,
      gameRef: gameRef,
    );
    add(_hillsLayer);

    // Village layer (appears in later levels)
    _villageLayer = _VillageLayer(
      y: gameRef.size.y - 200,
      parallaxFactor: 0.35,
      gameRef: gameRef,
    );
    add(_villageLayer);

    // Closer trees (actual tree shapes)
    _treesLayer = _TreeLayer(
      y: gameRef.size.y - 180,
      parallaxFactor: 0.5,
      gameRef: gameRef,
    );
    add(_treesLayer);

    // Flowers layer (appears as world becomes colorful)
    _flowerLayer = _FlowerLayer(
      y: gameRef.size.y - 130,
      parallaxFactor: 0.6,
      gameRef: gameRef,
    );
    add(_flowerLayer);

    // Celebration effects (confetti for final level)
    _celebrationLayer = _CelebrationLayer(gameRef: gameRef);
    add(_celebrationLayer);
  }

  /// Get the world saturation based on campaign progress
  static double getWorldSaturation() {
    if (LevelManager.instance.isPlayingCampaign) {
      return LevelManager.instance.worldSaturation;
    }
    return 1.0; // Full color in endless mode
  }

  /// Apply saturation to a color based on campaign progress
  static Color applySaturation(Color color) {
    final saturation = getWorldSaturation();
    if (saturation >= 1.0) return color;

    // Convert to grayscale then lerp based on saturation
    final gray = (color.red * 0.299 + color.green * 0.587 + color.blue * 0.114).toInt();
    final grayColor = Color.fromARGB(color.alpha, gray, gray, gray);

    return Color.lerp(grayColor, color, saturation) ?? color;
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
    var skyColor = gameRef.dayNightCycle.getCurrentSkyColor();

    // Apply saturation based on campaign progress
    skyColor = ParallaxBackground.applySaturation(skyColor);

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
    var color = gameRef.dayNightCycle.getHillColor();
    // Apply saturation based on campaign progress
    color = ParallaxBackground.applySaturation(color);
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
    var treeColor = gameRef.dayNightCycle.getTreeColor();
    // Apply saturation based on campaign progress
    treeColor = ParallaxBackground.applySaturation(treeColor);
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

/// Flower layer that appears as the world becomes more colorful
class _FlowerLayer extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final double parallaxFactor;
  final PlayItForwardGame gameRef;
  final List<_FlowerCluster> _clusters = [];
  final double clusterWidth = 120;
  final Random _random = Random(456);

  _FlowerLayer({
    required double y,
    required this.parallaxFactor,
    required this.gameRef,
  }) : super(position: Vector2(0, y));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(gameRef.size.x, 50);

    final numClusters = (gameRef.size.x / clusterWidth).ceil() + 2;
    for (int i = 0; i < numClusters; i++) {
      _createCluster(i * clusterWidth);
    }
  }

  void _createCluster(double x) {
    final cluster = _FlowerCluster(
      position: Vector2(x, 0),
      clusterWidth: clusterWidth,
      seed: _random.nextInt(1000),
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

class _FlowerCluster extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final double clusterWidth;
  final int seed;
  final PlayItForwardGame gameRef;
  late Random _random;
  double _swayTime = 0;

  _FlowerCluster({
    required Vector2 position,
    required this.clusterWidth,
    required this.seed,
    required this.gameRef,
  }) : super(position: position, size: Vector2(clusterWidth, 50)) {
    _random = Random(seed);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _swayTime += dt * 2;
  }

  @override
  void render(Canvas canvas) {
    // Only show flowers based on world saturation (campaign progress)
    final saturation = ParallaxBackground.getWorldSaturation();
    if (saturation < 0.1) return; // No flowers when world is grayscale

    final worldTransform = LevelManager.instance.currentWorldTransform;
    if (!worldTransform.hasFlowers && LevelManager.instance.isPlayingCampaign) return;

    _random = Random(seed);

    // Number of flowers based on saturation
    final flowerCount = (3 + saturation * 4).toInt();

    for (int i = 0; i < flowerCount; i++) {
      final x = _random.nextDouble() * (clusterWidth - 20) + 10;
      final flowerType = _random.nextInt(3);
      final sway = sin(_swayTime + i * 0.5) * 2;

      _drawFlower(canvas, x, sway, flowerType, saturation);
    }
  }

  void _drawFlower(Canvas canvas, double x, double sway, int type, double saturation) {
    final stemHeight = 15 + _random.nextDouble() * 10;

    // Stem with sway
    final stemPaint = Paint()
      ..color = ParallaxBackground.applySaturation(const Color(0xFF228B22))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(x, size.y),
      Offset(x + sway, size.y - stemHeight),
      stemPaint,
    );

    // Flower head
    final flowerY = size.y - stemHeight;
    final flowerX = x + sway;

    final colors = [
      const Color(0xFFFF6B6B), // Red
      const Color(0xFFFFE066), // Yellow
      const Color(0xFFFF69B4), // Pink
      const Color(0xFF87CEEB), // Light blue
      const Color(0xFFDDA0DD), // Plum
    ];

    final flowerColor = ParallaxBackground.applySaturation(
      colors[_random.nextInt(colors.length)],
    );

    switch (type) {
      case 0:
        // Daisy-like flower
        final petalPaint = Paint()..color = flowerColor;
        for (int p = 0; p < 5; p++) {
          final angle = (p / 5) * 2 * pi;
          final petalX = flowerX + cos(angle) * 4;
          final petalY = flowerY + sin(angle) * 4;
          canvas.drawCircle(Offset(petalX, petalY), 3, petalPaint);
        }
        // Center
        canvas.drawCircle(
          Offset(flowerX, flowerY),
          2,
          Paint()..color = ParallaxBackground.applySaturation(const Color(0xFFFFD700)),
        );
        break;
      case 1:
        // Tulip-like flower
        final tulipPaint = Paint()..color = flowerColor;
        final path = Path();
        path.moveTo(flowerX - 4, flowerY);
        path.quadraticBezierTo(flowerX - 5, flowerY - 6, flowerX, flowerY - 8);
        path.quadraticBezierTo(flowerX + 5, flowerY - 6, flowerX + 4, flowerY);
        path.close();
        canvas.drawPath(path, tulipPaint);
        break;
      case 2:
        // Simple round flower
        canvas.drawCircle(Offset(flowerX, flowerY), 4, Paint()..color = flowerColor);
        canvas.drawCircle(
          Offset(flowerX, flowerY),
          2,
          Paint()..color = ParallaxBackground.applySaturation(Colors.white),
        );
        break;
    }
  }
}

/// Rainbow layer that appears in later levels
class _RainbowLayer extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final PlayItForwardGame gameRef;
  double _opacity = 0;

  _RainbowLayer({required this.gameRef});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Only show rainbow when world transform allows it
    final worldTransform = LevelManager.instance.currentWorldTransform;
    final targetOpacity = (worldTransform.hasRainbow && !gameRef.dayNightCycle.isNightTime) ? 0.4 : 0.0;

    // Smooth fade in/out
    _opacity += (targetOpacity - _opacity) * dt * 2;
  }

  @override
  void render(Canvas canvas) {
    if (_opacity < 0.01) return;

    final centerX = gameRef.size.x * 0.7;
    final centerY = gameRef.size.y * 0.4;
    final radius = gameRef.size.x * 0.5;

    // Rainbow colors (ROYGBIV)
    final colors = [
      const Color(0xFFFF0000), // Red
      const Color(0xFFFF7F00), // Orange
      const Color(0xFFFFFF00), // Yellow
      const Color(0xFF00FF00), // Green
      const Color(0xFF0000FF), // Blue
      const Color(0xFF4B0082), // Indigo
      const Color(0xFF9400D3), // Violet
    ];

    // Draw arc bands
    for (int i = 0; i < colors.length; i++) {
      final bandRadius = radius - (i * 12);
      final paint = Paint()
        ..color = ParallaxBackground.applySaturation(colors[i]).withValues(alpha: _opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: bandRadius),
        pi,
        pi,
        false,
        paint,
      );
    }
  }
}

/// Decorative birds flying in the sky
class _SkyBirdLayer extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final PlayItForwardGame gameRef;
  final List<_SkyBird> _birds = [];
  final Random _random = Random();

  _SkyBirdLayer({required this.gameRef});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;

    // Create several birds at random positions
    for (int i = 0; i < 5; i++) {
      final bird = _SkyBird(
        position: Vector2(
          _random.nextDouble() * gameRef.size.x,
          50 + _random.nextDouble() * 100,
        ),
        speed: 30 + _random.nextDouble() * 40,
        wingSpeed: 3 + _random.nextDouble() * 2,
        gameRef: gameRef,
      );
      _birds.add(bird);
      add(bird);
    }
  }
}

class _SkyBird extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final PlayItForwardGame gameRef;
  final double speed;
  final double wingSpeed;
  double _wingPhase = 0;
  double _verticalOffset = 0;
  final Random _random = Random();

  _SkyBird({
    required Vector2 position,
    required this.speed,
    required this.wingSpeed,
    required this.gameRef,
  }) : super(position: position, size: Vector2(20, 10));

  @override
  void update(double dt) {
    super.update(dt);

    // Only show birds when world transform allows it
    final worldTransform = LevelManager.instance.currentWorldTransform;
    if (!worldTransform.hasBirdsInSky) return;

    // Move bird
    position.x -= (speed + gameRef.effectiveGameSpeed * 0.05) * dt;

    // Gentle vertical bobbing
    _wingPhase += dt * wingSpeed;
    _verticalOffset = sin(_wingPhase * 0.5) * 5;

    // Wrap around screen
    if (position.x < -size.x) {
      position.x = gameRef.size.x + 20;
      position.y = 50 + _random.nextDouble() * 100;
    }
  }

  @override
  void render(Canvas canvas) {
    // Only show birds when world transform allows it
    final worldTransform = LevelManager.instance.currentWorldTransform;
    if (!worldTransform.hasBirdsInSky) return;

    final saturation = ParallaxBackground.getWorldSaturation();
    final birdColor = ParallaxBackground.applySaturation(const Color(0xFF2C3E50));

    final centerX = size.x / 2;
    final centerY = size.y / 2 + _verticalOffset;

    // Simple bird shape (V shape with body)
    final wingFlap = sin(_wingPhase) * 4;

    final paint = Paint()
      ..color = birdColor.withValues(alpha: saturation.clamp(0.3, 1.0))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Left wing
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(centerX - 8, centerY - 3 + wingFlap),
      paint,
    );

    // Right wing
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(centerX + 8, centerY - 3 + wingFlap),
      paint,
    );

    // Body
    canvas.drawCircle(Offset(centerX, centerY), 2, Paint()..color = birdColor);
  }
}

/// Village/building layer that appears in the background
class _VillageLayer extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final double parallaxFactor;
  final PlayItForwardGame gameRef;
  final List<_Building> _buildings = [];
  final double buildingGap = 200;
  final Random _random = Random(789);

  _VillageLayer({
    required double y,
    required this.parallaxFactor,
    required this.gameRef,
  }) : super(position: Vector2(0, y));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(gameRef.size.x, 100);

    final numBuildings = (gameRef.size.x / buildingGap).ceil() + 2;
    for (int i = 0; i < numBuildings; i++) {
      _createBuilding(i * buildingGap);
    }
  }

  void _createBuilding(double x) {
    final building = _Building(
      position: Vector2(x, 0),
      seed: _random.nextInt(1000),
      gameRef: gameRef,
    );
    _buildings.add(building);
    add(building);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing || parallaxFactor == 0) return;

    for (final building in _buildings) {
      building.position.x -= gameRef.effectiveGameSpeed * parallaxFactor * dt;

      if (building.position.x + buildingGap < 0) {
        double maxX = 0;
        for (final b in _buildings) {
          if (b.position.x > maxX) maxX = b.position.x;
        }
        building.position.x = maxX + buildingGap;
        building.regenerate();
      }
    }
  }
}

class _Building extends PositionComponent with HasGameRef<PlayItForwardGame> {
  int seed;
  final PlayItForwardGame gameRef;
  late Random _random;
  late double _width;
  late double _height;
  late int _buildingType;
  late Color _buildingColor;

  _Building({
    required Vector2 position,
    required this.seed,
    required this.gameRef,
  }) : super(position: position, size: Vector2(80, 100)) {
    _regenerateProperties();
  }

  void _regenerateProperties() {
    _random = Random(seed);
    _width = 30 + _random.nextDouble() * 40;
    _height = 40 + _random.nextDouble() * 50;
    _buildingType = _random.nextInt(3);

    final colors = [
      const Color(0xFFE8D5B7), // Beige
      const Color(0xFFD4A574), // Tan
      const Color(0xFFB8860B), // Dark goldenrod
      const Color(0xFF8B7355), // Burly wood
      const Color(0xFFCD853F), // Peru
    ];
    _buildingColor = colors[_random.nextInt(colors.length)];
  }

  void regenerate() {
    seed = Random().nextInt(1000);
    _regenerateProperties();
  }

  @override
  void render(Canvas canvas) {
    // Only show village when world transform allows it
    final worldTransform = LevelManager.instance.currentWorldTransform;
    if (!worldTransform.hasVillage) return;

    final saturation = ParallaxBackground.getWorldSaturation();
    if (saturation < 0.4) return; // Villages appear when world is more colorful

    final color = ParallaxBackground.applySaturation(_buildingColor);
    final roofColor = ParallaxBackground.applySaturation(const Color(0xFF8B4513));
    final windowColor = ParallaxBackground.applySaturation(const Color(0xFFFFE4B5));

    final buildingX = size.x / 2 - _width / 2;
    final buildingY = size.y - _height;

    // Building body
    canvas.drawRect(
      Rect.fromLTWH(buildingX, buildingY, _width, _height),
      Paint()..color = color.withValues(alpha: saturation.clamp(0.5, 1.0)),
    );

    // Roof based on building type
    switch (_buildingType) {
      case 0:
        // Peaked roof
        final roofPath = Path();
        roofPath.moveTo(buildingX - 5, buildingY);
        roofPath.lineTo(buildingX + _width / 2, buildingY - 20);
        roofPath.lineTo(buildingX + _width + 5, buildingY);
        roofPath.close();
        canvas.drawPath(roofPath, Paint()..color = roofColor.withValues(alpha: saturation));
        break;
      case 1:
        // Flat roof with chimney
        canvas.drawRect(
          Rect.fromLTWH(buildingX - 3, buildingY - 5, _width + 6, 5),
          Paint()..color = roofColor.withValues(alpha: saturation),
        );
        // Chimney
        canvas.drawRect(
          Rect.fromLTWH(buildingX + _width * 0.7, buildingY - 20, 8, 15),
          Paint()..color = roofColor.withValues(alpha: saturation),
        );
        break;
      case 2:
        // Round roof (dome-like)
        canvas.drawArc(
          Rect.fromLTWH(buildingX - 5, buildingY - 15, _width + 10, 30),
          pi,
          pi,
          true,
          Paint()..color = roofColor.withValues(alpha: saturation),
        );
        break;
    }

    // Windows
    final windowRows = (_height / 20).floor();
    final windowCols = (_width / 15).floor();
    for (int row = 0; row < windowRows; row++) {
      for (int col = 0; col < windowCols; col++) {
        final windowX = buildingX + 5 + col * (_width - 10) / windowCols;
        final windowY = buildingY + 8 + row * 18;
        canvas.drawRect(
          Rect.fromLTWH(windowX, windowY, 8, 10),
          Paint()..color = windowColor.withValues(alpha: saturation * 0.8),
        );
      }
    }

    // Door
    final doorWidth = _width * 0.3;
    canvas.drawRect(
      Rect.fromLTWH(buildingX + (_width - doorWidth) / 2, size.y - 20, doorWidth, 20),
      Paint()..color = roofColor.withValues(alpha: saturation),
    );
  }
}

/// Celebration effects (confetti) for the final level
class _CelebrationLayer extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final PlayItForwardGame gameRef;
  final List<_ConfettiPiece> _confetti = [];
  final Random _random = Random();
  double _spawnTimer = 0;

  _CelebrationLayer({required this.gameRef});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Only show celebration when world transform allows it
    final worldTransform = LevelManager.instance.currentWorldTransform;
    if (!worldTransform.hasCelebration) {
      // Clear confetti when celebration ends
      for (final piece in _confetti) {
        piece.removeFromParent();
      }
      _confetti.clear();
      return;
    }

    // Spawn new confetti
    _spawnTimer += dt;
    if (_spawnTimer >= 0.1) {
      _spawnTimer = 0;
      _spawnConfetti();
    }

    // Remove off-screen confetti
    _confetti.removeWhere((piece) {
      if (piece.position.y > gameRef.size.y + 20) {
        piece.removeFromParent();
        return true;
      }
      return false;
    });
  }

  void _spawnConfetti() {
    final colors = [
      const Color(0xFFFF6B6B), // Red
      const Color(0xFFFFE066), // Yellow
      const Color(0xFF4ECDC4), // Teal
      const Color(0xFFFF69B4), // Pink
      const Color(0xFF45B7D1), // Blue
      const Color(0xFF96CEB4), // Green
      const Color(0xFFDDA0DD), // Plum
    ];

    final piece = _ConfettiPiece(
      position: Vector2(_random.nextDouble() * gameRef.size.x, -10),
      color: colors[_random.nextInt(colors.length)],
      rotationSpeed: 2 + _random.nextDouble() * 4,
      fallSpeed: 80 + _random.nextDouble() * 60,
      swayAmount: 20 + _random.nextDouble() * 30,
      swaySpeed: 2 + _random.nextDouble() * 2,
    );
    _confetti.add(piece);
    add(piece);
  }
}

class _ConfettiPiece extends PositionComponent {
  final Color color;
  final double rotationSpeed;
  final double fallSpeed;
  final double swayAmount;
  final double swaySpeed;
  double _rotation = 0;
  double _swayPhase = 0;
  final double _startX;

  _ConfettiPiece({
    required Vector2 position,
    required this.color,
    required this.rotationSpeed,
    required this.fallSpeed,
    required this.swayAmount,
    required this.swaySpeed,
  })  : _startX = position.x,
        super(position: position, size: Vector2(8, 6));

  @override
  void update(double dt) {
    super.update(dt);

    _rotation += rotationSpeed * dt;
    _swayPhase += swaySpeed * dt;

    position.y += fallSpeed * dt;
    position.x = _startX + sin(_swayPhase) * swayAmount;
  }

  @override
  void render(Canvas canvas) {
    final saturation = ParallaxBackground.getWorldSaturation();
    final paint = Paint()..color = ParallaxBackground.applySaturation(color).withValues(alpha: saturation);

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(_rotation);

    // Draw confetti as a small rectangle
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y),
      paint,
    );

    canvas.restore();
  }
}
