import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../models/level.dart';

/// A follower that runs behind the player (rescued NPC)
class Follower extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final NPCData data;
  final int index; // Position in follower chain (0 = closest to player)

  double _runCycleTime = 0;
  double _bobOffset = 0;
  final Random _random = Random();

  // Trail effect
  final List<Vector2> _trailPositions = [];
  static const int maxTrailLength = 5;

  Follower({
    required this.data,
    required this.index,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(50, 70), // Even larger to prevent clipping
          anchor: Anchor.bottomCenter,
        );

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    // Followers run together as a group behind the player (always on ground)
    // Spread horizontally with enough space to see each one
    final idealX = gameRef.player.position.x - 55 - (index * 45);
    final minX = size.x / 2 + 5;

    double targetX = idealX;

    // If bunched at edge, compress but keep visible with small offsets
    if (idealX < minX) {
      // Stack with small horizontal offset so each is partially visible
      targetX = minX + (index * 20);
    }

    // Follow player's Y position - jump together!
    final targetY = gameRef.player.position.y;

    // Smooth follow for both X and Y
    // Fast Y follow so they jump together (slight wave effect from index)
    final yFollowSpeed = 20.0 - (index * 2.0); // Very fast, slight delay per follower
    position.x += (targetX - position.x) * dt * 8;
    position.y += (targetY - position.y) * dt * yFollowSpeed.clamp(12.0, 20.0);

    // Hard clamp to keep on screen
    if (position.x < minX) {
      position.x = minX;
    }

    // Update animation
    _runCycleTime += dt * 10;
    _bobOffset = sin(_runCycleTime * 0.5) * 2;

    // Update trail
    _trailPositions.insert(0, position.clone());
    if (_trailPositions.length > maxTrailLength) {
      _trailPositions.removeLast();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw subtle trail
    _renderTrail(canvas);

    // Scale down followers further back for depth effect
    // First follower is 100%, each subsequent is 8% smaller (min 70%)
    final depthScale = (1.0 - (index * 0.08)).clamp(0.7, 1.0);

    canvas.save();
    // Scale from bottom center (where they stand)
    canvas.translate(size.x / 2, size.y);
    canvas.scale(depthScale, depthScale);
    canvas.translate(-size.x / 2, -size.y);

    // Draw follower based on type (smaller version of NPC)
    switch (data.spriteType) {
      case 'child':
        _renderChild(canvas);
        break;
      case 'elder':
        _renderElder(canvas);
        break;
      case 'bird':
        _renderBird(canvas);
        break;
      case 'traveler':
        _renderTraveler(canvas);
        break;
      case 'artist':
        _renderArtist(canvas);
        break;
      case 'musician':
        _renderMusician(canvas);
        break;
      case 'gardener':
        _renderGardener(canvas);
        break;
      case 'teacher':
        _renderTeacher(canvas);
        break;
      case 'doctor':
        _renderDoctor(canvas);
        break;
      case 'mayor':
        _renderMayor(canvas);
        break;
      default:
        _renderGeneric(canvas);
    }

    canvas.restore(); // Restore from depth scaling
  }

  void _renderTrail(Canvas canvas) {
    if (_trailPositions.length < 2) return;

    for (int i = 1; i < _trailPositions.length; i++) {
      final alpha = (1 - i / maxTrailLength) * 0.15;
      final trailPaint = Paint()
        ..color = data.primaryColor.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      final relativePos = _trailPositions[i] - position;
      canvas.drawCircle(
        Offset(size.x / 2 + relativePos.x, size.y / 2 + relativePos.y),
        10 - i * 1.5,
        trailPaint,
      );
    }
  }

  void _renderChild(Canvas canvas) {
    final legPhase = sin(_runCycleTime);
    final centerX = size.x / 2;
    final baseY = size.y + _bobOffset;

    // Shadow
    _drawShadow(canvas, centerX, baseY);

    // Legs
    final legPaint = Paint()..color = data.secondaryColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 6, baseY - 12 + legPhase * 3, 4, 10),
        const Radius.circular(2),
      ),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 2, baseY - 12 - legPhase * 3, 4, 10),
        const Radius.circular(2),
      ),
      legPaint,
    );

    // Body
    final bodyPaint = Paint()..color = data.primaryColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 8, baseY - 28, 16, 18),
        const Radius.circular(5),
      ),
      bodyPaint,
    );

    // Head
    final skinPaint = Paint()..color = const Color(0xFFFFDBB4);
    canvas.drawCircle(Offset(centerX, baseY - 34), 8, skinPaint);

    // Happy eyes (with white background for visibility)
    canvas.drawCircle(Offset(centerX - 3, baseY - 35), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(centerX + 3, baseY - 35), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(centerX - 3, baseY - 35), 1.5, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(centerX + 3, baseY - 35), 1.5, Paint()..color = Colors.black);

    // Smile
    _drawSmile(canvas, centerX, baseY - 30);
  }

  void _renderElder(Canvas canvas) {
    final legPhase = sin(_runCycleTime) * 0.5; // Slower movement
    final centerX = size.x / 2;
    final baseY = size.y + _bobOffset;

    _drawShadow(canvas, centerX, baseY);

    // Robe
    final robePaint = Paint()..color = data.primaryColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 10, baseY - 32, 20, 28),
        const Radius.circular(4),
      ),
      robePaint,
    );

    // Walking staff
    canvas.drawLine(
      Offset(centerX + 12, baseY - 25),
      Offset(centerX + 15, baseY),
      Paint()..color = const Color(0xFF5D4037)..strokeWidth = 2,
    );

    // Head
    final skinPaint = Paint()..color = const Color(0xFFE0C8B0);
    canvas.drawCircle(Offset(centerX, baseY - 38), 7, skinPaint);

    // Beard
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 4, baseY - 36, 8, 7),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white,
    );

    // Eyes (with white background for visibility)
    canvas.drawCircle(Offset(centerX - 2.5, baseY - 40), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(centerX + 2.5, baseY - 40), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(centerX - 2.5, baseY - 40), 1.5, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(centerX + 2.5, baseY - 40), 1.5, Paint()..color = Colors.black);

    _drawSmile(canvas, centerX, baseY - 33);
  }

  void _renderBird(Canvas canvas) {
    final wingFlap = sin(_runCycleTime * 2) * 5;
    final centerX = size.x / 2;
    final baseY = size.y - 10 + _bobOffset;

    // Body
    final bodyPaint = Paint()..color = data.primaryColor;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, baseY), width: 20, height: 14),
      bodyPaint,
    );

    // Wings (now healed and flapping!)
    final wingPaint = Paint()..color = data.secondaryColor;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, baseY - 5 + wingFlap),
        width: 12,
        height: 6,
      ),
      wingPaint,
    );

    // Head
    canvas.drawCircle(Offset(centerX + 7, baseY - 5), 6, bodyPaint);

    // Eye
    canvas.drawCircle(Offset(centerX + 9, baseY - 6), 1.5, Paint()..color = Colors.black);

    // Beak
    final beakPath = Path();
    beakPath.moveTo(centerX + 13, baseY - 5);
    beakPath.lineTo(centerX + 18, baseY - 4);
    beakPath.lineTo(centerX + 13, baseY - 3);
    beakPath.close();
    canvas.drawPath(beakPath, Paint()..color = const Color(0xFFFFB347));
  }

  void _renderTraveler(Canvas canvas) {
    final legPhase = sin(_runCycleTime);
    final centerX = size.x / 2;
    final baseY = size.y + _bobOffset;

    _drawShadow(canvas, centerX, baseY);

    // Backpack
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 2, baseY - 28, 12, 16),
        const Radius.circular(3),
      ),
      Paint()..color = data.secondaryColor,
    );

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 8, baseY - 26, 14, 20),
        const Radius.circular(4),
      ),
      Paint()..color = data.primaryColor,
    );

    // Head with hat
    canvas.drawCircle(Offset(centerX - 1, baseY - 32), 7, Paint()..color = const Color(0xFFD4A574));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX - 1, baseY - 38), width: 15, height: 5),
      Paint()..color = const Color(0xFF5D4037),
    );

    // Eyes (with white background for visibility)
    canvas.drawCircle(Offset(centerX - 4, baseY - 33), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(centerX + 2, baseY - 33), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(centerX - 4, baseY - 33), 1.5, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(centerX + 2, baseY - 33), 1.5, Paint()..color = Colors.black);

    _drawSmile(canvas, centerX - 1, baseY - 28);
  }

  void _renderArtist(Canvas canvas) {
    final centerX = size.x / 2;
    final baseY = size.y + _bobOffset;

    _drawShadow(canvas, centerX, baseY);

    // Smock
    final smockPaint = Paint()..color = data.primaryColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 10, baseY - 30, 20, 24),
        const Radius.circular(4),
      ),
      smockPaint,
    );

    // Paint splotches
    canvas.drawCircle(Offset(centerX - 3, baseY - 22), 2, Paint()..color = Colors.red);
    canvas.drawCircle(Offset(centerX + 3, baseY - 18), 1.5, Paint()..color = Colors.blue);

    // Head with beret
    canvas.drawCircle(Offset(centerX, baseY - 36), 7, Paint()..color = const Color(0xFFFFDBB4));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX - 1, baseY - 42), width: 14, height: 6),
      Paint()..color = data.secondaryColor,
    );

    // Paintbrush
    canvas.drawLine(
      Offset(centerX + 10, baseY - 22),
      Offset(centerX + 16, baseY - 32),
      Paint()..color = const Color(0xFF5D4037)..strokeWidth = 1.5,
    );

    // Eyes (with white background for visibility)
    canvas.drawCircle(Offset(centerX - 2.5, baseY - 37), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(centerX + 2.5, baseY - 37), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(centerX - 2.5, baseY - 37), 1.5, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(centerX + 2.5, baseY - 37), 1.5, Paint()..color = Colors.black);

    _drawSmile(canvas, centerX, baseY - 32);
  }

  void _renderMusician(Canvas canvas) {
    final centerX = size.x / 2;
    final baseY = size.y + _bobOffset;
    final noteFloat = sin(_runCycleTime) * 3;

    _drawShadow(canvas, centerX, baseY);

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 8, baseY - 28, 16, 22),
        const Radius.circular(4),
      ),
      Paint()..color = data.primaryColor,
    );

    // Head
    canvas.drawCircle(Offset(centerX, baseY - 34), 7, Paint()..color = const Color(0xFFFFDBB4));

    // Eyes (with white background for visibility)
    canvas.drawCircle(Offset(centerX - 2, baseY - 36), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(centerX + 2, baseY - 36), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(centerX - 2, baseY - 36), 1.5, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(centerX + 2, baseY - 36), 1.5, Paint()..color = Colors.black);

    // Musical notes
    canvas.drawCircle(
      Offset(centerX - 10, baseY - 42 + noteFloat),
      3,
      Paint()..color = data.secondaryColor,
    );
    canvas.drawLine(
      Offset(centerX - 7, baseY - 42 + noteFloat),
      Offset(centerX - 7, baseY - 50 + noteFloat),
      Paint()..color = data.secondaryColor..strokeWidth = 1.5,
    );

    _drawSmile(canvas, centerX, baseY - 30);
  }

  void _renderGardener(Canvas canvas) {
    final centerX = size.x / 2;
    final baseY = size.y + _bobOffset;

    _drawShadow(canvas, centerX, baseY);

    // Overalls
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 8, baseY - 30, 16, 24),
        const Radius.circular(4),
      ),
      Paint()..color = data.primaryColor,
    );

    // Head with sun hat
    canvas.drawCircle(Offset(centerX, baseY - 36), 7, Paint()..color = const Color(0xFFE8C8A0));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, baseY - 42), width: 18, height: 5),
      Paint()..color = const Color(0xFFF5DEB3),
    );

    // Flower in hand (now healthy!)
    canvas.drawCircle(Offset(centerX + 12, baseY - 18), 4, Paint()..color = Colors.pink);
    canvas.drawCircle(Offset(centerX + 12, baseY - 18), 2, Paint()..color = Colors.yellow);

    // Eyes (with white background for visibility)
    canvas.drawCircle(Offset(centerX - 2.5, baseY - 37), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(centerX + 2.5, baseY - 37), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(centerX - 2.5, baseY - 37), 1.5, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(centerX + 2.5, baseY - 37), 1.5, Paint()..color = Colors.black);

    _drawSmile(canvas, centerX, baseY - 32);
  }

  void _renderTeacher(Canvas canvas) {
    final centerX = size.x / 2;
    final baseY = size.y + _bobOffset;

    _drawShadow(canvas, centerX, baseY);

    // Cardigan
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 10, baseY - 30, 20, 24),
        const Radius.circular(4),
      ),
      Paint()..color = data.primaryColor,
    );

    // Head
    canvas.drawCircle(Offset(centerX, baseY - 36), 7, Paint()..color = const Color(0xFFD4A574));

    // Eyes (with white background for visibility)
    canvas.drawCircle(Offset(centerX - 3, baseY - 37), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(centerX + 3, baseY - 37), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(centerX - 3, baseY - 37), 1.2, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(centerX + 3, baseY - 37), 1.2, Paint()..color = Colors.black);

    // Glasses
    final glassesPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX - 3, baseY - 37), width: 5, height: 4),
      glassesPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX + 3, baseY - 37), width: 5, height: 4),
      glassesPaint,
    );

    // Book
    canvas.drawRect(
      Rect.fromLTWH(centerX - 12, baseY - 20, 8, 10),
      Paint()..color = data.secondaryColor,
    );

    _drawSmile(canvas, centerX, baseY - 32);
  }

  void _renderDoctor(Canvas canvas) {
    final centerX = size.x / 2;
    final baseY = size.y + _bobOffset;

    _drawShadow(canvas, centerX, baseY);

    // White coat
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 10, baseY - 32, 20, 26),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white,
    );

    // Coat outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 10, baseY - 32, 20, 26),
        const Radius.circular(4),
      ),
      Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    // Head
    canvas.drawCircle(Offset(centerX, baseY - 38), 7, Paint()..color = const Color(0xFFD4A574));

    // Eyes (with white background for visibility)
    canvas.drawCircle(Offset(centerX - 2.5, baseY - 39), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(centerX + 2.5, baseY - 39), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(centerX - 2.5, baseY - 39), 1.5, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(centerX + 2.5, baseY - 39), 1.5, Paint()..color = Colors.black);

    // Stethoscope
    canvas.drawArc(
      Rect.fromCenter(center: Offset(centerX, baseY - 28), width: 8, height: 8),
      0,
      pi,
      false,
      Paint()
        ..color = data.primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    _drawSmile(canvas, centerX, baseY - 34);
  }

  void _renderMayor(Canvas canvas) {
    final centerX = size.x / 2;
    final baseY = size.y + _bobOffset;

    _drawShadow(canvas, centerX, baseY);

    // Suit
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 10, baseY - 32, 20, 26),
        const Radius.circular(4),
      ),
      Paint()..color = data.primaryColor,
    );

    // Sash
    canvas.drawLine(
      Offset(centerX - 8, baseY - 32),
      Offset(centerX + 8, baseY - 14),
      Paint()..color = data.secondaryColor..strokeWidth = 4,
    );

    // Head
    canvas.drawCircle(Offset(centerX, baseY - 38), 7, Paint()..color = const Color(0xFFFFDBB4));

    // Eyes (with white background for visibility)
    canvas.drawCircle(Offset(centerX - 2.5, baseY - 39), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(centerX + 2.5, baseY - 39), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(centerX - 2.5, baseY - 39), 1.5, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(centerX + 2.5, baseY - 39), 1.5, Paint()..color = Colors.black);

    // Top hat
    canvas.drawRect(
      Rect.fromLTWH(centerX - 5, baseY - 50, 10, 10),
      Paint()..color = Colors.black,
    );
    canvas.drawRect(
      Rect.fromLTWH(centerX - 8, baseY - 41, 16, 3),
      Paint()..color = Colors.black,
    );

    _drawSmile(canvas, centerX, baseY - 34);
  }

  void _renderGeneric(Canvas canvas) {
    final legPhase = sin(_runCycleTime);
    final centerX = size.x / 2;
    final baseY = size.y + _bobOffset;

    _drawShadow(canvas, centerX, baseY);

    // Legs
    final legPaint = Paint()..color = data.secondaryColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 5, baseY - 10 + legPhase * 2, 4, 8),
        const Radius.circular(2),
      ),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 1, baseY - 10 - legPhase * 2, 4, 8),
        const Radius.circular(2),
      ),
      legPaint,
    );

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 8, baseY - 28, 16, 20),
        const Radius.circular(4),
      ),
      Paint()..color = data.primaryColor,
    );

    // Head
    canvas.drawCircle(Offset(centerX, baseY - 34), 7, Paint()..color = const Color(0xFFFFDBB4));

    // Eyes (with white background for visibility)
    canvas.drawCircle(Offset(centerX - 2.5, baseY - 35), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(centerX + 2.5, baseY - 35), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(centerX - 2.5, baseY - 35), 1.5, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(centerX + 2.5, baseY - 35), 1.5, Paint()..color = Colors.black);

    _drawSmile(canvas, centerX, baseY - 30);
  }

  void _drawShadow(Canvas canvas, double centerX, double baseY) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, baseY + 2), width: 20, height: 5),
      shadowPaint,
    );
  }

  void _drawSmile(Canvas canvas, double centerX, double baseY) {
    final smilePath = Path();
    smilePath.moveTo(centerX - 3, baseY);
    smilePath.quadraticBezierTo(centerX, baseY + 2, centerX + 3, baseY);
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = const Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}
