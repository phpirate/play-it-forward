import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/tutorial_manager.dart';

enum ObstacleType { crate, spike, tallCrate }

class Obstacle extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final ObstacleType type;

  Obstacle({required this.type, required Vector2 position})
      : super(position: position, anchor: Anchor.bottomCenter);

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

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    position.x -= gameRef.effectiveGameSpeed * dt;
    position.y = gameRef.ground.getGroundYAt(position.x);

    // Tutorial hint for slide when obstacle is visible
    if (position.x < gameRef.size.x * 0.8) {
      TutorialManager.instance.tryShowHint(TutorialManager.hintSlide);
    }

    gameRef.player.checkNearMiss(this);

    if (position.x < -100) {
      removeFromParent();
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
