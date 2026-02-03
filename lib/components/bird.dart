import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../effects/particle_factory.dart';

class Bird extends PositionComponent with HasGameRef<PlayItForwardGame>, CollisionCallbacks {
  Bird() : super(size: Vector2(55, 35), anchor: Anchor.centerLeft);

  double _wingTimer = 0;
  double _wingAngle = 0;
  final double wingFlapSpeed = 12;
  bool isStomped = false;

  // Birds fly towards player (opposite to game scroll direction)
  final double birdSpeed = 150; // Additional speed towards player

  /// Called when player stomps on the bird
  void stomp() {
    if (isStomped) return;
    isStomped = true;

    // Spawn feather burst particles
    final burstPos = Vector2(position.x + size.x / 2, position.y + size.y / 2);
    final featherBurst = ParticleFactory.createFeatherBurst(burstPos);
    if (featherBurst != null) {
      gameRef.add(featherBurst);
    }

    // Remove bird
    removeFromParent();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add collision hitbox
    add(RectangleHitbox(
      size: Vector2(45, 20),
      position: Vector2(5, 8),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    // Move left faster than world scroll (flying towards player)
    position.x -= (gameRef.effectiveGameSpeed + birdSpeed) * dt;

    // Follow terrain at flying height (45 pixels above ground)
    final groundY = gameRef.ground.getGroundYAt(position.x);
    position.y = groundY - 45;

    // Check for near-miss with player
    gameRef.player.checkNearMiss(this);

    // Animate wing flapping (smooth sine wave)
    _wingTimer += dt * wingFlapSpeed;
    _wingAngle = sin(_wingTimer) * 0.5;

    // Remove when off screen
    if (position.x < -size.x) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Flip horizontally so bird faces left (direction of flight)
    canvas.save();
    canvas.translate(size.x, 0);
    canvas.scale(-1, 1);

    // Colors
    const bodyColor = Color(0xFF8B4513); // Brown
    const bodyDarkColor = Color(0xFF5D4037); // Dark brown
    const bodyLightColor = Color(0xFFA0522D); // Sienna
    const beakColor = Color(0xFFFF8C00); // Orange
    const wingColor = Color(0xFFA0522D); // Sienna
    const wingDarkColor = Color(0xFF6D4C41); // Darker wing

    final bodyCenter = Offset(25, 18);

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(bodyCenter.dx, size.y + 5), width: 35, height: 8),
      shadowPaint,
    );

    // Tail feathers (3 small triangles)
    final tailPaint = Paint()..color = bodyDarkColor;
    for (int i = 0; i < 3; i++) {
      final tailPath = Path();
      final yOffset = (i - 1) * 5.0;
      tailPath.moveTo(5, bodyCenter.dy + yOffset);
      tailPath.lineTo(-5, bodyCenter.dy + yOffset - 3);
      tailPath.lineTo(-5, bodyCenter.dy + yOffset + 3);
      tailPath.close();
      canvas.drawPath(tailPath, tailPaint);
    }

    // Body (oval shape with gradient)
    final bodyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [bodyLightColor, bodyColor, bodyDarkColor],
      stops: const [0.0, 0.5, 1.0],
    );
    final bodyRect = Rect.fromCenter(center: bodyCenter, width: 35, height: 22);
    final bodyPaint = Paint()..shader = bodyGradient.createShader(bodyRect);
    canvas.drawOval(bodyRect, bodyPaint);

    // Body highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bodyCenter.dx - 5, bodyCenter.dy - 4),
        width: 15,
        height: 8,
      ),
      highlightPaint,
    );

    // Wing (curved shape with rotation animation)
    _drawWing(canvas, bodyCenter, wingColor, wingDarkColor);

    // Head (slightly overlapping body)
    final headCenter = Offset(42, 14);
    final headGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [bodyLightColor, bodyColor],
    );
    final headRect = Rect.fromCenter(center: headCenter, width: 16, height: 14);
    final headPaint = Paint()..shader = headGradient.createShader(headRect);
    canvas.drawOval(headRect, headPaint);

    // Beak (triangle shape)
    final beakPath = Path();
    beakPath.moveTo(50, 14);
    beakPath.lineTo(58, 16);
    beakPath.lineTo(50, 18);
    beakPath.close();
    final beakGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [beakColor, const Color(0xFFE65100)],
    );
    final beakPaint = Paint()
      ..shader = beakGradient.createShader(Rect.fromLTWH(50, 14, 8, 4));
    canvas.drawPath(beakPath, beakPaint);

    // Eye (white with black pupil)
    final eyeCenter = Offset(44, 12);
    // Eye white
    canvas.drawCircle(eyeCenter, 4, Paint()..color = Colors.white);
    // Pupil
    canvas.drawCircle(Offset(eyeCenter.dx + 1, eyeCenter.dy), 2, Paint()..color = Colors.black);
    // Eye highlight
    canvas.drawCircle(
      Offset(eyeCenter.dx - 1, eyeCenter.dy - 1),
      1,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );

    canvas.restore(); // Restore from horizontal flip
  }

  void _drawWing(Canvas canvas, Offset bodyCenter, Color wingColor, Color wingDarkColor) {
    canvas.save();
    canvas.translate(bodyCenter.dx - 5, bodyCenter.dy - 5);
    canvas.rotate(_wingAngle);

    // Wing shape (curved, more realistic)
    final wingPath = Path();
    wingPath.moveTo(0, 5);
    wingPath.quadraticBezierTo(-5, -10, 5, -15);
    wingPath.quadraticBezierTo(15, -12, 20, -5);
    wingPath.quadraticBezierTo(15, 0, 5, 5);
    wingPath.close();

    // Wing gradient
    final wingGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [wingColor, wingDarkColor],
    );
    final wingRect = Rect.fromLTWH(-5, -15, 25, 20);
    final wingPaint = Paint()..shader = wingGradient.createShader(wingRect);
    canvas.drawPath(wingPath, wingPaint);

    // Wing feather details
    final featherPaint = Paint()
      ..color = wingDarkColor.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(0, 0), const Offset(8, -10), featherPaint);
    canvas.drawLine(const Offset(5, 2), const Offset(12, -8), featherPaint);
    canvas.drawLine(const Offset(10, 3), const Offset(16, -5), featherPaint);

    canvas.restore();
  }
}
