import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../models/level.dart';
import '../effects/particle_factory.dart';

/// NPC at the end of a level that needs help (goal marker)
class NPC extends PositionComponent with HasGameRef<PlayItForwardGame>, CollisionCallbacks {
  final NPCData data;
  bool _isCollected = false;
  double _bobTime = 0;
  double _glowTime = 0;
  double _waveTime = 0;
  final Random _random = Random();

  NPC({
    required this.data,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(50, 60),
          anchor: Anchor.bottomCenter,
        );

  bool get isCollected => _isCollected;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add collision hitbox
    add(RectangleHitbox(
      size: Vector2(40, 55),
      position: Vector2(5, 5),
    ));
  }

  // Position where NPC stops scrolling and starts walking toward player
  static const double waitingPositionX = 0.75; // 75% of screen width from left
  static const double walkSpeed = 150.0; // Speed at which NPC walks toward player (faster!)
  bool _isWalkingToPlayer = false;

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    // Calculate the waiting position (right side of screen)
    final waitX = gameRef.size.x * waitingPositionX;

    if (!_isWalkingToPlayer) {
      // Move with game world until reaching waiting position
      if (position.x > waitX) {
        position.x -= gameRef.effectiveGameSpeed * dt;

        // Start walking toward player once we reach waiting position
        if (position.x <= waitX) {
          position.x = waitX;
          _isWalkingToPlayer = true;
        }
      } else {
        // Already past waiting position, start walking
        _isWalkingToPlayer = true;
      }
    } else {
      // Walk toward the player
      final playerX = gameRef.player.position.x + gameRef.player.size.x / 2;
      if (position.x > playerX + 10) {
        position.x -= walkSpeed * dt;
      }
    }

    // Animation timers
    _bobTime += dt * 2;
    _glowTime += dt * 3;
    _waveTime += dt * 4;

    // Spawn help particles occasionally
    if (_random.nextDouble() < 0.02) {
      _spawnHelpParticle();
    }
  }

  void _spawnHelpParticle() {
    final particle = ParticleFactory.createSparkle(
      Vector2(position.x, position.y - size.y / 2),
      data.primaryColor,
    );
    if (particle != null) {
      gameRef.add(particle);
    }
  }

  /// Called when player reaches this NPC
  void collect() {
    if (_isCollected) return;
    _isCollected = true;

    // Spawn celebration particles
    final celebrationPos = Vector2(position.x, position.y - 30);
    final celebration = ParticleFactory.createCelebration(celebrationPos);
    if (celebration != null) {
      gameRef.add(celebration);
    }

    // Will be removed after level complete overlay shows
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_isCollected) return;

    // Draw glow effect
    _renderGlow(canvas);

    // Flip horizontally when walking toward player (facing left)
    if (_isWalkingToPlayer) {
      canvas.save();
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }

    // Draw NPC based on sprite type
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

    // Restore canvas if we flipped it
    if (_isWalkingToPlayer) {
      canvas.restore();
    }

    // Draw help indicator
    _renderHelpIndicator(canvas);
  }

  void _renderGlow(Canvas canvas) {
    final glowIntensity = 0.3 + sin(_glowTime) * 0.1;
    final glowPaint = Paint()
      ..color = data.primaryColor.withValues(alpha: glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      40,
      glowPaint,
    );
  }

  void _renderHelpIndicator(Canvas canvas) {
    // Floating "Help!" text or icon above NPC
    final bobOffset = sin(_bobTime) * 5;
    final iconY = -15 + bobOffset;

    // Help icon background
    final bgPaint = Paint()..color = Colors.red.shade400;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.x / 2, iconY), width: 35, height: 20),
        const Radius.circular(10),
      ),
      bgPaint,
    );

    // Exclamation mark
    final textPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.x / 2, iconY - 5),
      Offset(size.x / 2, iconY + 2),
      textPaint,
    );
    canvas.drawCircle(
      Offset(size.x / 2, iconY + 6),
      1.5,
      Paint()..color = Colors.white,
    );
  }

  void _renderChild(Canvas canvas) {
    final waveOffset = sin(_waveTime) * 3;
    final centerX = size.x / 2;
    final baseY = size.y;

    // Small body
    final bodyPaint = Paint()..color = data.primaryColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 12, baseY - 40, 24, 25),
        const Radius.circular(8),
      ),
      bodyPaint,
    );

    // Legs
    final legPaint = Paint()..color = data.secondaryColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 8, baseY - 18, 6, 16),
        const Radius.circular(3),
      ),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 2, baseY - 18, 6, 16),
        const Radius.circular(3),
      ),
      legPaint,
    );

    // Head
    final skinPaint = Paint()..color = const Color(0xFFFFDBB4);
    canvas.drawCircle(Offset(centerX, baseY - 48), 12, skinPaint);

    // Waving arm
    canvas.save();
    canvas.translate(centerX + 12, baseY - 35);
    canvas.rotate(sin(_waveTime) * 0.5 + 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, -2, 12, 5),
        const Radius.circular(2),
      ),
      bodyPaint,
    );
    canvas.restore();

    // Eyes (looking hopeful)
    canvas.drawCircle(Offset(centerX - 4, baseY - 50), 2, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(centerX + 4, baseY - 50), 2, Paint()..color = Colors.black);

    // Small smile
    final smilePath = Path();
    smilePath.moveTo(centerX - 4, baseY - 44);
    smilePath.quadraticBezierTo(centerX, baseY - 41, centerX + 4, baseY - 44);
    canvas.drawPath(smilePath, Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
  }

  void _renderElder(Canvas canvas) {
    final centerX = size.x / 2;
    final baseY = size.y;

    // Robe/coat
    final robePaint = Paint()..color = data.primaryColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 15, baseY - 45, 30, 35),
        const Radius.circular(5),
      ),
      robePaint,
    );

    // Walking stick
    final stickPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(centerX + 18, baseY - 35),
      Offset(centerX + 22, baseY),
      stickPaint,
    );

    // Head
    final skinPaint = Paint()..color = const Color(0xFFE0C8B0);
    canvas.drawCircle(Offset(centerX, baseY - 52), 10, skinPaint);

    // White beard
    final beardPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 6, baseY - 48, 12, 10),
        const Radius.circular(5),
      ),
      beardPaint,
    );

    // Wise eyes
    canvas.drawCircle(Offset(centerX - 3, baseY - 54), 1.5, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(centerX + 3, baseY - 54), 1.5, Paint()..color = Colors.black);
  }

  void _renderBird(Canvas canvas) {
    final bobOffset = sin(_bobTime * 2) * 3;
    final centerX = size.x / 2;
    final baseY = size.y - 20 + bobOffset;

    // Body
    final bodyPaint = Paint()..color = data.primaryColor;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, baseY), width: 30, height: 20),
      bodyPaint,
    );

    // Wing (drooping - injured)
    final wingPaint = Paint()..color = data.secondaryColor;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX - 5, baseY + 8), width: 15, height: 10),
      wingPaint,
    );

    // Head
    canvas.drawCircle(Offset(centerX + 10, baseY - 8), 8, bodyPaint);

    // Eye
    canvas.drawCircle(Offset(centerX + 12, baseY - 10), 2, Paint()..color = Colors.black);

    // Beak
    final beakPaint = Paint()..color = const Color(0xFFFFB347);
    final beakPath = Path();
    beakPath.moveTo(centerX + 18, baseY - 8);
    beakPath.lineTo(centerX + 25, baseY - 6);
    beakPath.lineTo(centerX + 18, baseY - 4);
    beakPath.close();
    canvas.drawPath(beakPath, beakPaint);

    // Bandage on wing
    final bandagePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centerX - 10, baseY + 5),
      Offset(centerX, baseY + 10),
      bandagePaint,
    );
  }

  void _renderTraveler(Canvas canvas) {
    final centerX = size.x / 2;
    final baseY = size.y;

    // Backpack
    final packPaint = Paint()..color = data.secondaryColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 5, baseY - 40, 18, 25),
        const Radius.circular(4),
      ),
      packPaint,
    );

    // Body
    final bodyPaint = Paint()..color = data.primaryColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 12, baseY - 38, 20, 28),
        const Radius.circular(6),
      ),
      bodyPaint,
    );

    // Head with hat
    final skinPaint = Paint()..color = const Color(0xFFD4A574);
    canvas.drawCircle(Offset(centerX - 2, baseY - 48), 10, skinPaint);

    // Hat
    final hatPaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX - 2, baseY - 56), width: 22, height: 8),
      hatPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 10, baseY - 62, 16, 8),
        const Radius.circular(4),
      ),
      hatPaint,
    );

    // Tired eyes
    canvas.drawLine(
      Offset(centerX - 6, baseY - 50),
      Offset(centerX - 2, baseY - 50),
      Paint()..color = Colors.black..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(centerX + 1, baseY - 50),
      Offset(centerX + 5, baseY - 50),
      Paint()..color = Colors.black..strokeWidth = 2,
    );
  }

  void _renderArtist(Canvas canvas) {
    final centerX = size.x / 2;
    final baseY = size.y;

    // Smock/apron
    final smockPaint = Paint()..color = data.primaryColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 14, baseY - 42, 28, 32),
        const Radius.circular(6),
      ),
      smockPaint,
    );

    // Paint splotches
    canvas.drawCircle(Offset(centerX - 5, baseY - 30), 3, Paint()..color = Colors.red);
    canvas.drawCircle(Offset(centerX + 5, baseY - 25), 2, Paint()..color = Colors.blue);
    canvas.drawCircle(Offset(centerX + 2, baseY - 35), 2, Paint()..color = Colors.yellow);

    // Head with beret
    final skinPaint = Paint()..color = const Color(0xFFFFDBB4);
    canvas.drawCircle(Offset(centerX, baseY - 50), 10, skinPaint);

    // Beret
    final beretPaint = Paint()..color = data.secondaryColor;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX - 2, baseY - 58), width: 20, height: 10),
      beretPaint,
    );

    // Brush in hand
    final brushPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(centerX + 15, baseY - 30),
      Offset(centerX + 25, baseY - 45),
      brushPaint,
    );
  }

  void _renderMusician(Canvas canvas) {
    final centerX = size.x / 2;
    final baseY = size.y;

    // Body
    final bodyPaint = Paint()..color = data.primaryColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 12, baseY - 40, 24, 30),
        const Radius.circular(6),
      ),
      bodyPaint,
    );

    // Head
    final skinPaint = Paint()..color = const Color(0xFFFFDBB4);
    canvas.drawCircle(Offset(centerX, baseY - 50), 10, skinPaint);

    // Musical notes floating
    final notePaint = Paint()..color = data.secondaryColor;
    final noteOffset = sin(_waveTime) * 5;
    canvas.drawCircle(Offset(centerX - 15, baseY - 60 + noteOffset), 4, notePaint);
    canvas.drawLine(
      Offset(centerX - 11, baseY - 60 + noteOffset),
      Offset(centerX - 11, baseY - 70 + noteOffset),
      Paint()..color = data.secondaryColor..strokeWidth = 2,
    );
  }

  void _renderGardener(Canvas canvas) {
    final centerX = size.x / 2;
    final baseY = size.y;

    // Overalls
    final overallPaint = Paint()..color = data.primaryColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 12, baseY - 42, 24, 32),
        const Radius.circular(5),
      ),
      overallPaint,
    );

    // Straps
    canvas.drawLine(
      Offset(centerX - 8, baseY - 42),
      Offset(centerX - 8, baseY - 50),
      Paint()..color = data.secondaryColor..strokeWidth = 3,
    );
    canvas.drawLine(
      Offset(centerX + 8, baseY - 42),
      Offset(centerX + 8, baseY - 50),
      Paint()..color = data.secondaryColor..strokeWidth = 3,
    );

    // Head with sun hat
    final skinPaint = Paint()..color = const Color(0xFFE8C8A0);
    canvas.drawCircle(Offset(centerX, baseY - 52), 10, skinPaint);

    // Sun hat
    final hatPaint = Paint()..color = const Color(0xFFF5DEB3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, baseY - 60), width: 28, height: 8),
      hatPaint,
    );

    // Wilted flower in hand
    final flowerPaint = Paint()..color = Colors.grey;
    canvas.drawCircle(Offset(centerX + 18, baseY - 25), 5, flowerPaint);
  }

  void _renderTeacher(Canvas canvas) {
    final centerX = size.x / 2;
    final baseY = size.y;

    // Cardigan
    final cardiganPaint = Paint()..color = data.primaryColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 14, baseY - 42, 28, 32),
        const Radius.circular(5),
      ),
      cardiganPaint,
    );

    // Head
    final skinPaint = Paint()..color = const Color(0xFFD4A574);
    canvas.drawCircle(Offset(centerX, baseY - 50), 10, skinPaint);

    // Glasses
    final glassesPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX - 5, baseY - 52), width: 8, height: 6),
      glassesPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX + 5, baseY - 52), width: 8, height: 6),
      glassesPaint,
    );
    canvas.drawLine(
      Offset(centerX - 1, baseY - 52),
      Offset(centerX + 1, baseY - 52),
      glassesPaint,
    );

    // Book
    final bookPaint = Paint()..color = data.secondaryColor;
    canvas.drawRect(
      Rect.fromLTWH(centerX - 18, baseY - 28, 12, 15),
      bookPaint,
    );
  }

  void _renderDoctor(Canvas canvas) {
    final centerX = size.x / 2;
    final baseY = size.y;

    // White coat
    final coatPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 14, baseY - 44, 28, 34),
        const Radius.circular(5),
      ),
      coatPaint,
    );

    // Coat outline
    final outlinePaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 14, baseY - 44, 28, 34),
        const Radius.circular(5),
      ),
      outlinePaint,
    );

    // Head
    final skinPaint = Paint()..color = const Color(0xFFD4A574);
    canvas.drawCircle(Offset(centerX, baseY - 52), 10, skinPaint);

    // Stethoscope
    final stethPaint = Paint()
      ..color = data.primaryColor
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(centerX, baseY - 38), width: 12, height: 12),
      0,
      pi,
      false,
      stethPaint,
    );

    // Tired expression
    canvas.drawLine(
      Offset(centerX - 5, baseY - 54),
      Offset(centerX - 2, baseY - 53),
      Paint()..color = Colors.black..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(centerX + 2, baseY - 53),
      Offset(centerX + 5, baseY - 54),
      Paint()..color = Colors.black..strokeWidth = 2,
    );
  }

  void _renderMayor(Canvas canvas) {
    final centerX = size.x / 2;
    final baseY = size.y;

    // Fancy suit
    final suitPaint = Paint()..color = data.primaryColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 14, baseY - 44, 28, 34),
        const Radius.circular(5),
      ),
      suitPaint,
    );

    // Sash
    final sashPaint = Paint()
      ..color = data.secondaryColor
      ..strokeWidth = 6;
    canvas.drawLine(
      Offset(centerX - 12, baseY - 44),
      Offset(centerX + 12, baseY - 20),
      sashPaint,
    );

    // Head
    final skinPaint = Paint()..color = const Color(0xFFFFDBB4);
    canvas.drawCircle(Offset(centerX, baseY - 52), 10, skinPaint);

    // Top hat
    final hatPaint = Paint()..color = Colors.black;
    canvas.drawRect(
      Rect.fromLTWH(centerX - 8, baseY - 72, 16, 15),
      hatPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(centerX - 12, baseY - 58, 24, 5),
      hatPaint,
    );

    // Hopeful smile
    final smilePath = Path();
    smilePath.moveTo(centerX - 5, baseY - 46);
    smilePath.quadraticBezierTo(centerX, baseY - 42, centerX + 5, baseY - 46);
    canvas.drawPath(smilePath, Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
  }

  void _renderGeneric(Canvas canvas) {
    final centerX = size.x / 2;
    final baseY = size.y;

    // Body
    final bodyPaint = Paint()..color = data.primaryColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 12, baseY - 40, 24, 30),
        const Radius.circular(6),
      ),
      bodyPaint,
    );

    // Head
    final skinPaint = Paint()..color = const Color(0xFFFFDBB4);
    canvas.drawCircle(Offset(centerX, baseY - 48), 10, skinPaint);

    // Eyes
    canvas.drawCircle(Offset(centerX - 4, baseY - 50), 2, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(centerX + 4, baseY - 50), 2, Paint()..color = Colors.black);
  }
}
