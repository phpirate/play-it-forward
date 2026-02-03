import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';

/// A tall vertical wall that the player can wall-jump off of
class Wall extends PositionComponent with HasGameRef<PlayItForwardGame> {
  Wall({required Vector2 position})
      : super(
          position: position,
          size: Vector2(20, 120),
          anchor: Anchor.bottomCenter,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add hitbox for collision
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    // Move with game speed
    position.x -= gameRef.effectiveGameSpeed * dt;
    position.y = gameRef.ground.getGroundYAt(position.x);

    // Remove when off screen
    if (position.x < -50) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Main wall body with brick gradient
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // Stone/brick gradient
    final gradient = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFF5D6D7E), // Dark slate
        Color(0xFF85929E), // Lighter slate
        Color(0xFF5D6D7E), // Dark slate
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Brick lines
    final brickPaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..strokeWidth = 1;

    // Horizontal mortar lines
    for (double y = 15; y < size.y; y += 15) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), brickPaint);
    }

    // Vertical mortar lines (offset every other row)
    for (double y = 0; y < size.y; y += 30) {
      // Full width bricks
      canvas.drawLine(
        Offset(size.x / 2, y),
        Offset(size.x / 2, y + 15),
        brickPaint,
      );
    }
    for (double y = 15; y < size.y; y += 30) {
      // Offset bricks
      canvas.drawLine(
        Offset(size.x / 4, y),
        Offset(size.x / 4, y + 15),
        brickPaint,
      );
      canvas.drawLine(
        Offset(size.x * 3 / 4, y),
        Offset(size.x * 3 / 4, y + 15),
        brickPaint,
      );
    }

    // Top cap
    final capPaint = Paint()..color = const Color(0xFF34495E);
    canvas.drawRect(Rect.fromLTWH(-2, -5, size.x + 4, 8), capPaint);

    // Highlight edge
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(1, 0), Offset(1, size.y), highlightPaint);

    // Shadow edge
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(size.x - 1, 0),
      Offset(size.x - 1, size.y),
      shadowPaint,
    );

    // Drop shadow
    final dropShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y + 3),
        width: size.x + 4,
        height: 8,
      ),
      dropShadowPaint,
    );
  }
}
