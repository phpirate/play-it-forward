import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/tutorial_manager.dart';
import '../models/level.dart';

class Obstacle extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final ObstacleType type;

  Obstacle({required this.type, required Vector2 position})
      : super(position: position, anchor: Anchor.bottomCenter);

  // Animation state for dynamic obstacles
  double _animationTime = 0;
  double _rollingAngle = 0;
  double _swingAngle = 0;
  bool _fireActive = false;
  double _fireTimer = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    switch (type) {
      case ObstacleType.crate:
        _buildCrate();
        break;
      case ObstacleType.spike:
        _buildSpike();
        break;
      case ObstacleType.tallCrate:
        _buildTallCrate();
        break;
      case ObstacleType.rollingLog:
        _buildRollingLog();
        break;
      case ObstacleType.gap:
        _buildGap();
        break;
      case ObstacleType.swingingRope:
        _buildSwingingRope();
        break;
      case ObstacleType.mudPuddle:
        _buildMudPuddle();
        break;
      case ObstacleType.fireJet:
        _buildFireJet();
        break;
    }
  }

  void _buildCrate() {
    size = Vector2(40, 40);

    // Drop shadow
    add(CustomPainterComponent(
      painter: _ShadowPainter(width: 36, height: 8),
      position: Vector2(2, 40),
      size: Vector2(36, 8),
    ));

    // Main crate with wood texture
    add(CustomPainterComponent(
      painter: _CratePainter(),
      size: size,
    ));

    add(RectangleHitbox());
  }

  void _buildSpike() {
    size = Vector2(30, 40);

    // Drop shadow
    add(CustomPainterComponent(
      painter: _ShadowPainter(width: 26, height: 6),
      position: Vector2(2, 40),
      size: Vector2(26, 6),
    ));

    // Enhanced spike
    add(CustomPainterComponent(
      painter: _SpikePainter(),
      size: size,
    ));

    add(PolygonHitbox([
      Vector2(15, 0),
      Vector2(30, 40),
      Vector2(0, 40),
    ]));
  }

  void _buildTallCrate() {
    size = Vector2(40, 70);

    // Drop shadow
    add(CustomPainterComponent(
      painter: _ShadowPainter(width: 36, height: 8),
      position: Vector2(2, 70),
      size: Vector2(36, 8),
    ));

    // Main tall crate with wood texture
    add(CustomPainterComponent(
      painter: _TallCratePainter(),
      size: size,
    ));

    add(RectangleHitbox());
  }

  void _buildRollingLog() {
    size = Vector2(50, 50);

    // Shadow
    add(CustomPainterComponent(
      painter: _ShadowPainter(width: 46, height: 10),
      position: Vector2(2, 50),
      size: Vector2(46, 10),
    ));

    // Rolling log visual
    add(CustomPainterComponent(
      painter: _RollingLogPainter(this),
      size: size,
    ));

    add(CircleHitbox());
  }

  void _buildGap() {
    size = Vector2(80, 100);

    // Gap is a hole in the ground - deadly fall
    add(CustomPainterComponent(
      painter: _GapPainter(),
      size: size,
    ));

    // Hitbox at the bottom of the gap (fall zone)
    add(RectangleHitbox(
      size: Vector2(60, 20),
      position: Vector2(10, 80),
    ));
  }

  void _buildSwingingRope() {
    size = Vector2(30, 120);

    // Swinging rope with weight at bottom
    add(CustomPainterComponent(
      painter: _SwingingRopePainter(this),
      size: size,
    ));

    // Hitbox for the swinging weight
    add(CircleHitbox(
      radius: 15,
      position: Vector2(0, 90),
    ));
  }

  void _buildMudPuddle() {
    size = Vector2(100, 20);

    // Brown mud puddle
    add(CustomPainterComponent(
      painter: _MudPuddlePainter(),
      size: size,
    ));

    // No hitbox - doesn't kill, just slows
  }

  void _buildFireJet() {
    size = Vector2(40, 80);

    // Fire jet from ground
    add(CustomPainterComponent(
      painter: _FireJetPainter(this),
      size: size,
    ));

    // Hitbox only active when fire is on (checked dynamically)
    add(RectangleHitbox(
      size: Vector2(30, 60),
      position: Vector2(5, 10),
    ));
  }

  // Getters for painters to access animation state
  double get rollingAngle => _rollingAngle;
  double get swingAngle => _swingAngle;
  bool get fireActive => _fireActive;
  double get animationTime => _animationTime;

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    // Update animation time
    _animationTime += dt;

    // Special behavior for different obstacle types
    switch (type) {
      case ObstacleType.rollingLog:
        // Roll toward player (faster than normal scroll)
        position.x -= (gameRef.effectiveGameSpeed + 80) * dt;
        _rollingAngle += dt * 8; // Rotate as it rolls
        break;
      case ObstacleType.swingingRope:
        // Swing back and forth
        _swingAngle = sin(_animationTime * 3) * 0.6;
        position.x -= gameRef.effectiveGameSpeed * dt;
        break;
      case ObstacleType.fireJet:
        // Toggle fire on/off periodically
        _fireTimer += dt;
        if (_fireTimer > 1.5) {
          _fireActive = !_fireActive;
          _fireTimer = 0;
        }
        position.x -= gameRef.effectiveGameSpeed * dt;
        break;
      case ObstacleType.mudPuddle:
        // Check if player is in mud
        _checkMudEffect();
        position.x -= gameRef.effectiveGameSpeed * dt;
        break;
      default:
        position.x -= gameRef.effectiveGameSpeed * dt;
    }

    // Gap doesn't follow ground (it IS the ground)
    if (type != ObstacleType.gap) {
      position.y = gameRef.ground.getGroundYAt(position.x);
    }

    // Tutorial hint for slide when obstacle is visible
    if (position.x < gameRef.size.x * 0.8) {
      TutorialManager.instance.tryShowHint(TutorialManager.hintSlide);
    }

    gameRef.player.checkNearMiss(this);

    if (position.x < -100) {
      removeFromParent();
    }
  }

  void _checkMudEffect() {
    final playerBounds = gameRef.player.toRect();
    final mudBounds = toRect();
    if (playerBounds.overlaps(mudBounds) && gameRef.player.isOnGround) {
      // Slow down player temporarily (handled in player)
      gameRef.player.applyMudSlow();
    }
  }
}

class _ShadowPainter extends CustomPainter {
  final double width;
  final double height;

  _ShadowPainter({required this.width, required this.height});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawOval(
      Rect.fromLTWH(0, 0, width, height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CratePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Main wood body with warm orange-brown gradient
    final bodyGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFDEB887), // Burlywood (light)
        Color(0xFFC19A6B), // Camel
        Color(0xFF8B7355), // Dark tan
      ],
      stops: [0.0, 0.5, 1.0],
    );
    final bodyPaint = Paint()..shader = bodyGradient.createShader(rect);
    canvas.drawRect(rect, bodyPaint);

    // Wood plank lines (horizontal)
    final plankPaint = Paint()
      ..color = const Color(0xFF6B5344)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, size.height * 0.33), Offset(size.width, size.height * 0.33), plankPaint);
    canvas.drawLine(Offset(0, size.height * 0.66), Offset(size.width, size.height * 0.66), plankPaint);

    // Darker border/outline
    final borderPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(rect.deflate(1), borderPaint);

    // Corner nails
    final nailPaint = Paint()..color = const Color(0xFF424242);
    canvas.drawCircle(const Offset(6, 6), 3, nailPaint);
    canvas.drawCircle(Offset(size.width - 6, 6), 3, nailPaint);
    canvas.drawCircle(Offset(6, size.height - 6), 3, nailPaint);
    canvas.drawCircle(Offset(size.width - 6, size.height - 6), 3, nailPaint);

    // Nail highlights
    final nailHighlight = Paint()..color = const Color(0xFF757575);
    canvas.drawCircle(const Offset(5, 5), 1, nailHighlight);
    canvas.drawCircle(Offset(size.width - 7, 5), 1, nailHighlight);

    // Highlight edge (top and left)
    final highlightPaint = Paint()
      ..color = const Color(0xFFE8D4B8).withValues(alpha: 0.6)
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(2, 2), Offset(size.width - 2, 2), highlightPaint);
    canvas.drawLine(const Offset(2, 2), Offset(2, size.height - 2), highlightPaint);

    // "FRAGILE" or crate marking - simple X
    final markPaint = Paint()
      ..color = const Color(0xFF8B4513).withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.4),
      Offset(size.width * 0.7, size.height * 0.6),
      markPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, size.height * 0.4),
      Offset(size.width * 0.3, size.height * 0.6),
      markPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TallCratePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Industrial green metal barrel gradient
    final bodyGradient = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFF2E7D32), // Dark green edge
        Color(0xFF4CAF50), // Medium green
        Color(0xFF81C784), // Light green (highlight)
        Color(0xFF4CAF50), // Medium green
        Color(0xFF1B5E20), // Dark green edge
      ],
      stops: [0.0, 0.2, 0.5, 0.8, 1.0],
    );
    final bodyPaint = Paint()..shader = bodyGradient.createShader(rect);

    // Draw rounded barrel shape
    final barrelRect = RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(4));
    canvas.drawRRect(barrelRect, bodyPaint);

    // Metal bands (top, middle, bottom)
    final bandPaint = Paint()..color = const Color(0xFF37474F);
    final bandHighlight = Paint()..color = const Color(0xFF78909C);

    // Top band
    canvas.drawRect(Rect.fromLTWH(0, 4, size.width, 6), bandPaint);
    canvas.drawRect(Rect.fromLTWH(0, 4, size.width, 2), bandHighlight);

    // Middle band
    canvas.drawRect(Rect.fromLTWH(0, size.height / 2 - 3, size.width, 6), bandPaint);
    canvas.drawRect(Rect.fromLTWH(0, size.height / 2 - 3, size.width, 2), bandHighlight);

    // Bottom band
    canvas.drawRect(Rect.fromLTWH(0, size.height - 10, size.width, 6), bandPaint);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 10, size.width, 2), bandHighlight);

    // Rivets on bands
    final rivetPaint = Paint()..color = const Color(0xFF263238);
    final rivetHighlight = Paint()..color = const Color(0xFF546E7A);
    for (double x = 6; x < size.width; x += 12) {
      // Top band rivets
      canvas.drawCircle(Offset(x, 7), 2.5, rivetPaint);
      canvas.drawCircle(Offset(x - 0.5, 6.5), 1, rivetHighlight);

      // Middle band rivets
      canvas.drawCircle(Offset(x, size.height / 2), 2.5, rivetPaint);
      canvas.drawCircle(Offset(x - 0.5, size.height / 2 - 0.5), 1, rivetHighlight);

      // Bottom band rivets
      canvas.drawCircle(Offset(x, size.height - 7), 2.5, rivetPaint);
      canvas.drawCircle(Offset(x - 0.5, size.height - 7.5), 1, rivetHighlight);
    }

    // Hazard symbol or label area
    final labelRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.35),
      width: 20,
      height: 16,
    );
    final labelPaint = Paint()..color = const Color(0xFFFFEB3B);
    canvas.drawRect(labelRect, labelPaint);

    // Hazard stripes on label
    final hazardPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3;
    canvas.save();
    canvas.clipRect(labelRect);
    for (double x = labelRect.left - 20; x < labelRect.right + 5; x += 6) {
      canvas.drawLine(
        Offset(x, labelRect.top),
        Offset(x + 16, labelRect.bottom),
        hazardPaint,
      );
    }
    canvas.restore();

    // Border outline
    final borderPaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(barrelRect, borderPaint);

    // Wear/rust spots
    final rustPaint = Paint()..color = const Color(0xFF795548).withValues(alpha: 0.3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.7, size.height * 0.6), width: 8, height: 12),
      rustPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.25, size.height * 0.75), width: 6, height: 8),
      rustPaint,
    );

    // Highlight edge (left side shine)
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(3, 12),
      Offset(3, size.height - 12),
      shinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SpikePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Warning red base
    final basePaint = Paint()..color = const Color(0xFFB71C1C);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 10, size.width, 10),
      basePaint,
    );

    // Warning stripes on base
    final stripePaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = 3;
    for (double x = -5; x < size.width + 5; x += 8) {
      canvas.drawLine(
        Offset(x, size.height - 10),
        Offset(x + 10, size.height),
        stripePaint,
      );
    }

    // Clip stripes to base area
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, size.height - 10, size.width, 10));
    canvas.restore();

    // Deadly red-to-silver gradient for spike
    final spikeGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFFFFFFF), // Bright white tip (sharp!)
        const Color(0xFFE0E0E0), // Light silver
        const Color(0xFFD32F2F), // Red tint near base
        const Color(0xFF8B0000), // Dark red at base
      ],
      stops: const [0.0, 0.15, 0.6, 1.0],
    );

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width - 2, size.height - 10)
      ..lineTo(2, size.height - 10)
      ..close();

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..shader = spikeGradient.createShader(rect);
    canvas.drawPath(path, paint);

    // Dark edge outline
    final outlinePaint = Paint()
      ..color = const Color(0xFF4A0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, outlinePaint);

    // Multiple shine highlights (makes it look sharper)
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    // Left shine
    canvas.drawLine(
      Offset(size.width / 2 - 2, 4),
      Offset(size.width / 2 - 6, 18),
      shinePaint,
    );
    // Right edge highlight
    final edgeShine = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width / 2 + 1, 3),
      Offset(size.width - 4, size.height - 12),
      edgeShine,
    );

    // Blood drip effect (subtle)
    final dripPaint = Paint()
      ..color = const Color(0xFF8B0000).withValues(alpha: 0.6);
    canvas.drawCircle(
      Offset(size.width / 2 - 3, size.height * 0.4),
      2,
      dripPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2 - 3, size.height * 0.5),
        width: 3,
        height: 6,
      ),
      dripPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Rolling Log Painter
class _RollingLogPainter extends CustomPainter {
  final Obstacle obstacle;
  _RollingLogPainter(this.obstacle);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(obstacle.rollingAngle);
    canvas.translate(-center.dx, -center.dy);

    // Main log body (brown circle)
    final logGradient = RadialGradient(
      colors: [
        const Color(0xFF8B4513), // Saddle brown
        const Color(0xFF5D3A1A), // Darker brown
        const Color(0xFF3E2512), // Very dark
      ],
    );
    final logPaint = Paint()
      ..shader = logGradient.createShader(Rect.fromCircle(center: center, radius: 25));
    canvas.drawCircle(center, 23, logPaint);

    // Wood rings
    final ringPaint = Paint()
      ..color = const Color(0xFF6B4423)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 18, ringPaint);
    canvas.drawCircle(center, 12, ringPaint);
    canvas.drawCircle(center, 6, ringPaint);

    // Center dot
    canvas.drawCircle(center, 3, Paint()..color = const Color(0xFF3E2512));

    // Bark texture lines
    final barkPaint = Paint()
      ..color = const Color(0xFF4A3520)
      ..strokeWidth = 1;
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      canvas.drawLine(
        Offset(center.dx + cos(angle) * 20, center.dy + sin(angle) * 20),
        Offset(center.dx + cos(angle) * 23, center.dy + sin(angle) * 23),
        barkPaint,
      );
    }

    canvas.restore();

    // Outline
    final outlinePaint = Paint()
      ..color = const Color(0xFF2D1810)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 24, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Gap Painter (hole in ground)
class _GapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Dark hole
    final holePaint = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawRect(Rect.fromLTWH(10, 0, 60, size.height), holePaint);

    // Depth gradient
    final depthGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF2D2D2D),
        const Color(0xFF0D0D0D),
        Colors.black,
      ],
    );
    final depthPaint = Paint()
      ..shader = depthGradient.createShader(Rect.fromLTWH(10, 0, 60, size.height));
    canvas.drawRect(Rect.fromLTWH(15, 10, 50, size.height - 10), depthPaint);

    // Edge highlights (crumbling dirt)
    final dirtPaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRect(Rect.fromLTWH(5, 0, 10, 15), dirtPaint);
    canvas.drawRect(Rect.fromLTWH(65, 0, 10, 15), dirtPaint);

    // Warning sign
    final warnPaint = Paint()..color = const Color(0xFFFF5722);
    canvas.drawCircle(const Offset(40, -10), 8, warnPaint);
    final exclaim = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(40, -14), const Offset(40, -8), exclaim);
    canvas.drawCircle(const Offset(40, -5), 1.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Swinging Rope Painter
class _SwingingRopePainter extends CustomPainter {
  final Obstacle obstacle;
  _SwingingRopePainter(this.obstacle);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Pivot point at top
    final pivotX = size.width / 2;
    canvas.translate(pivotX, 0);
    canvas.rotate(obstacle.swingAngle);
    canvas.translate(-pivotX, 0);

    // Rope
    final ropePaint = Paint()
      ..color = const Color(0xFF8B7355)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, 95),
      ropePaint,
    );

    // Rope texture
    final texturePaint = Paint()
      ..color = const Color(0xFF6B5344)
      ..strokeWidth = 1;
    for (double y = 5; y < 95; y += 8) {
      canvas.drawLine(
        Offset(size.width / 2 - 2, y),
        Offset(size.width / 2 + 2, y + 3),
        texturePaint,
      );
    }

    // Weight at bottom (spiked ball)
    final weightCenter = Offset(size.width / 2, 105);
    final ballPaint = Paint()..color = const Color(0xFF424242);
    canvas.drawCircle(weightCenter, 15, ballPaint);

    // Spikes on ball
    final spikePaint = Paint()..color = const Color(0xFF212121);
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final startX = weightCenter.dx + cos(angle) * 12;
      final startY = weightCenter.dy + sin(angle) * 12;
      final endX = weightCenter.dx + cos(angle) * 20;
      final endY = weightCenter.dy + sin(angle) * 20;

      final spikePath = Path()
        ..moveTo(startX - cos(angle + pi/2) * 3, startY - sin(angle + pi/2) * 3)
        ..lineTo(endX, endY)
        ..lineTo(startX + cos(angle + pi/2) * 3, startY + sin(angle + pi/2) * 3)
        ..close();
      canvas.drawPath(spikePath, spikePaint);
    }

    // Highlight
    canvas.drawCircle(
      Offset(weightCenter.dx - 4, weightCenter.dy - 4),
      4,
      Paint()..color = const Color(0xFF757575),
    );

    canvas.restore();

    // Pivot mount at top
    final mountPaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 8, -5, 16, 10), mountPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Mud Puddle Painter
class _MudPuddlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Mud puddle (brown oval)
    final mudGradient = RadialGradient(
      colors: [
        const Color(0xFF5D4037),
        const Color(0xFF4E342E),
        const Color(0xFF3E2723),
      ],
    );
    final mudPaint = Paint()
      ..shader = mudGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..addOval(Rect.fromLTWH(0, 5, size.width, size.height - 5));
    canvas.drawPath(path, mudPaint);

    // Bubbles
    final bubblePaint = Paint()
      ..color = const Color(0xFF6D4C41)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.5), 4, bubblePaint);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.4), 3, bubblePaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.6), 2, bubblePaint);

    // Shine
    final shinePaint = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.5);
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.3, 20, 6),
      shinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Fire Jet Painter
class _FireJetPainter extends CustomPainter {
  final Obstacle obstacle;
  _FireJetPainter(this.obstacle);

  @override
  void paint(Canvas canvas, Size size) {
    // Base (metal grate)
    final basePaint = Paint()..color = const Color(0xFF424242);
    canvas.drawRect(Rect.fromLTWH(5, size.height - 15, 30, 15), basePaint);

    // Grate holes
    final holePaint = Paint()..color = const Color(0xFF212121);
    for (double x = 10; x < 35; x += 8) {
      canvas.drawCircle(Offset(x, size.height - 8), 2, holePaint);
    }

    // Fire (only when active)
    if (obstacle.fireActive) {
      final fireColors = [
        const Color(0xFFFFEB3B), // Yellow core
        const Color(0xFFFF9800), // Orange
        const Color(0xFFFF5722), // Red-orange
        const Color(0xFFE64A19), // Dark orange
      ];

      // Animated flame shape
      final time = obstacle.animationTime * 5;

      for (int i = 0; i < 3; i++) {
        final flameOffset = sin(time + i) * 3;
        final flameHeight = 55.0 + sin(time * 2 + i) * 8;

        final flamePath = Path()
          ..moveTo(8 + i * 8 + flameOffset, size.height - 15)
          ..quadraticBezierTo(
            5 + i * 8, size.height - 15 - flameHeight / 2,
            20 + flameOffset, size.height - 15 - flameHeight,
          )
          ..quadraticBezierTo(
            35 + i * 2, size.height - 15 - flameHeight / 2,
            32 - i * 8 + flameOffset, size.height - 15,
          )
          ..close();

        final flamePaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: fireColors,
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height - 15));

        canvas.drawPath(flamePath, flamePaint);
      }

      // Glow effect
      final glowPaint = Paint()
        ..color = const Color(0xFFFF9800).withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(20, size.height - 40), 25, glowPaint);
    } else {
      // Smoke when inactive
      final smokePaint = Paint()
        ..color = const Color(0xFF757575).withValues(alpha: 0.3);
      canvas.drawCircle(Offset(20, size.height - 25), 5, smokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
