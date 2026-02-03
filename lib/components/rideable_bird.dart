import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/audio_manager.dart';
import '../effects/particle_factory.dart';
import '../managers/tutorial_manager.dart';
import 'coin.dart';

/// A large bird that the player can ride when stomped on
class RideableBird extends PositionComponent
    with HasGameRef<PlayItForwardGame>, CollisionCallbacks {
  RideableBird() : super(size: Vector2(90, 60), anchor: Anchor.centerLeft);

  double _wingTimer = 0;
  double _wingAngle = 0;
  final double wingFlapSpeed = 8; // Slower flaps for bigger bird

  // Bird states
  bool _isBeingRidden = false;
  bool _isStomped = false;
  double _rideTimer = 0;
  static const double rideDuration = 10.0; // 10 seconds of riding

  // Flying path during ride
  double _flyHeight = 0;
  double _targetHeight = 0;
  double _heightChangeTimer = 0;
  final Random _random = Random();

  // Coin spawning during ride
  double _coinTimer = 0;
  static const double coinInterval = 0.3;

  // Speed boost while riding
  static const double rideSpeedBoost = 100;

  bool get isBeingRidden => _isBeingRidden;
  bool get isStomped => _isStomped;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Larger hitbox for bigger bird
    add(RectangleHitbox(
      size: Vector2(70, 35),
      position: Vector2(10, 15),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    // Animate wing flapping
    _wingTimer += dt * wingFlapSpeed;
    _wingAngle = sin(_wingTimer) * 0.4;

    if (_isBeingRidden) {
      _updateRiding(dt);
    } else if (!_isStomped) {
      _updateFlying(dt);
    }
  }

  void _updateFlying(double dt) {
    // Stay in place relative to the world (move with world scroll)
    // This makes the bird appear stationary, waiting for player to reach it
    position.x -= gameRef.effectiveGameSpeed * dt;

    // Follow terrain at flying height (hovering in place)
    final groundY = gameRef.ground.getGroundYAt(position.x);
    position.y = groundY - 80; // Hovering above ground

    // Tutorial hint when rideable bird is visible
    if (position.x < gameRef.size.x * 0.8) {
      TutorialManager.instance.tryShowHint(TutorialManager.hintRideableBird);
    }

    // Remove when off screen (player missed it)
    if (position.x < -size.x) {
      removeFromParent();
    }
  }

  void _updateRiding(double dt) {
    _rideTimer += dt;

    // Bird stays at a fixed screen X position (like the player normally does)
    // This keeps the bird visible on screen while the world scrolls past
    const targetScreenX = 120.0; // Slightly ahead of normal player position
    position.x = targetScreenX;

    // Get ground height at bird's position for reference
    final groundY = gameRef.ground.getGroundYAt(position.x + 100);

    // Vary flying height for interesting path - high enough to clear obstacles
    _heightChangeTimer += dt;
    if (_heightChangeTimer >= 1.5) {
      _heightChangeTimer = 0;
      _targetHeight = 120 + _random.nextDouble() * 60; // Fly high above obstacles
    }
    _flyHeight += (_targetHeight - _flyHeight) * dt * 2;

    // Position bird above ground
    position.y = groundY - _flyHeight;

    // Update player position to ride on bird
    gameRef.player.position.x = position.x + 10;
    gameRef.player.position.y = position.y - 10;

    // Spawn coins ahead along the flight path
    _coinTimer += dt;
    if (_coinTimer >= coinInterval) {
      _coinTimer = 0;
      _spawnRideCoin();
    }

    // End ride after duration
    if (_rideTimer >= rideDuration) {
      _endRide();
    }
  }

  void _spawnRideCoin() {
    // Spawn coins ahead of the bird (off-screen to the right, they'll scroll in)
    final coinX = gameRef.size.x + 50 + _random.nextDouble() * 100;
    final coinY = position.y + _random.nextDouble() * 60 - 30;
    gameRef.add(Coin(position: Vector2(coinX, coinY)));
  }

  /// Called when player stomps on this bird
  void startRide() {
    if (_isStomped || _isBeingRidden) return;

    _isStomped = true;
    _isBeingRidden = true;
    _rideTimer = 0;
    _flyHeight = 100;
    _targetHeight = 100;

    // Notify player they're riding
    gameRef.player.startRiding(this);

    // Show throw stone hint
    TutorialManager.instance.tryShowHint(TutorialManager.hintThrowStone);

    // Play sound
    AudioManager.instance.playSfx('powerup.mp3');

    // Screen shake for impact
    gameRef.triggerScreenShake(8, 0.2);

    // Feather burst effect
    final burstPos = Vector2(position.x + size.x / 2, position.y);
    final feathers = ParticleFactory.createFeatherBurst(burstPos);
    if (feathers != null) {
      gameRef.add(feathers);
    }
  }

  void _endRide() {
    _isBeingRidden = false;

    // Tell player ride is over
    gameRef.player.endRiding();

    // Bird flies away
    _flyAway();
  }

  void _flyAway() {
    // Bird will continue off screen
    removeFromParent();

    // Spawn feathers as bird leaves
    final burstPos = Vector2(position.x + size.x / 2, position.y);
    final feathers = ParticleFactory.createFeatherBurst(burstPos);
    if (feathers != null) {
      gameRef.add(feathers);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Bird always faces right:
    // - When hovering: facing the approaching player
    // - When being ridden: flying forward
    canvas.save();
    // No flip needed - bird naturally faces right

    // Colors - golden/majestic bird
    const bodyColor = Color(0xFFDAA520); // Goldenrod
    const bodyDarkColor = Color(0xFFB8860B); // Dark goldenrod
    const bodyLightColor = Color(0xFFFFD700); // Gold
    const beakColor = Color(0xFFFF6B00); // Orange-red
    const wingColor = Color(0xFFCD853F); // Peru
    const wingDarkColor = Color(0xFF8B4513); // Saddle brown

    final bodyCenter = Offset(40, 30);

    // Glow effect when rideable (not yet ridden)
    if (!_isStomped) {
      final glowPaint = Paint()
        ..color = Colors.yellow.withValues(alpha: 0.3 + sin(_wingTimer) * 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawOval(
        Rect.fromCenter(center: bodyCenter, width: 80, height: 50),
        glowPaint,
      );
    }

    // Rainbow trail when being ridden
    if (_isBeingRidden) {
      _drawRainbowTrail(canvas);
    }

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(bodyCenter.dx, size.y + 8), width: 60, height: 12),
      shadowPaint,
    );

    // Tail feathers (larger, more majestic)
    _drawTailFeathers(canvas, bodyCenter, bodyDarkColor, bodyLightColor);

    // Body (larger oval)
    final bodyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [bodyLightColor, bodyColor, bodyDarkColor],
      stops: const [0.0, 0.5, 1.0],
    );
    final bodyRect = Rect.fromCenter(center: bodyCenter, width: 55, height: 35);
    final bodyPaint = Paint()..shader = bodyGradient.createShader(bodyRect);
    canvas.drawOval(bodyRect, bodyPaint);

    // Body highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bodyCenter.dx - 8, bodyCenter.dy - 6),
        width: 25,
        height: 12,
      ),
      highlightPaint,
    );

    // Wings (larger)
    _drawWing(canvas, bodyCenter, wingColor, wingDarkColor);

    // Head
    final headCenter = Offset(68, 22);
    final headGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [bodyLightColor, bodyColor],
    );
    final headRect = Rect.fromCenter(center: headCenter, width: 24, height: 20);
    final headPaint = Paint()..shader = headGradient.createShader(headRect);
    canvas.drawOval(headRect, headPaint);

    // Crest (small feathers on head)
    _drawCrest(canvas, headCenter, bodyLightColor);

    // Beak (larger, curved)
    final beakPath = Path();
    beakPath.moveTo(80, 22);
    beakPath.quadraticBezierTo(92, 20, 95, 25);
    beakPath.quadraticBezierTo(90, 28, 80, 26);
    beakPath.close();
    final beakGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [beakColor, const Color(0xFFCC5500)],
    );
    final beakPaint = Paint()
      ..shader = beakGradient.createShader(const Rect.fromLTWH(80, 20, 15, 8));
    canvas.drawPath(beakPath, beakPaint);

    // Eye (larger, more expressive)
    final eyeCenter = Offset(72, 18);
    canvas.drawCircle(eyeCenter, 6, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(eyeCenter.dx + 1, eyeCenter.dy),
      3,
      Paint()..color = Colors.black,
    );
    canvas.drawCircle(
      Offset(eyeCenter.dx - 1, eyeCenter.dy - 2),
      1.5,
      Paint()..color = Colors.white,
    );

    // Indicator when rideable
    if (!_isStomped) {
      _drawRideIndicator(canvas, bodyCenter);
    }

    canvas.restore();
  }

  void _drawTailFeathers(Canvas canvas, Offset bodyCenter, Color darkColor, Color lightColor) {
    final tailPaint = Paint();
    for (int i = 0; i < 5; i++) {
      final yOffset = (i - 2) * 8.0;
      final length = 20.0 + (2 - (i - 2).abs()) * 8;

      tailPaint.color = i % 2 == 0 ? darkColor : lightColor;

      final tailPath = Path();
      tailPath.moveTo(8, bodyCenter.dy + yOffset);
      tailPath.quadraticBezierTo(
        -length / 2, bodyCenter.dy + yOffset + 2,
        -length, bodyCenter.dy + yOffset,
      );
      tailPath.quadraticBezierTo(
        -length / 2, bodyCenter.dy + yOffset - 2,
        8, bodyCenter.dy + yOffset,
      );
      canvas.drawPath(tailPath, tailPaint);
    }
  }

  void _drawWing(Canvas canvas, Offset bodyCenter, Color wingColor, Color wingDarkColor) {
    canvas.save();
    canvas.translate(bodyCenter.dx - 8, bodyCenter.dy - 8);
    canvas.rotate(_wingAngle);

    // Larger wing
    final wingPath = Path();
    wingPath.moveTo(0, 8);
    wingPath.quadraticBezierTo(-10, -20, 10, -30);
    wingPath.quadraticBezierTo(30, -25, 40, -10);
    wingPath.quadraticBezierTo(30, 0, 10, 8);
    wingPath.close();

    final wingGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [wingColor, wingDarkColor],
    );
    final wingRect = const Rect.fromLTWH(-10, -30, 50, 40);
    final wingPaint = Paint()..shader = wingGradient.createShader(wingRect);
    canvas.drawPath(wingPath, wingPaint);

    // Wing feather details
    final featherPaint = Paint()
      ..color = wingDarkColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(0, 0), const Offset(15, -20), featherPaint);
    canvas.drawLine(const Offset(8, 2), const Offset(22, -15), featherPaint);
    canvas.drawLine(const Offset(16, 4), const Offset(30, -10), featherPaint);
    canvas.drawLine(const Offset(24, 5), const Offset(36, -5), featherPaint);

    canvas.restore();
  }

  void _drawCrest(Canvas canvas, Offset headCenter, Color color) {
    final crestPaint = Paint()..color = color;
    for (int i = 0; i < 3; i++) {
      final crestPath = Path();
      final baseX = headCenter.dx - 5 + i * 5;
      final baseY = headCenter.dy - 10;
      crestPath.moveTo(baseX, baseY);
      crestPath.quadraticBezierTo(
        baseX + 2, baseY - 12 - i * 2,
        baseX + 4, baseY - 8,
      );
      crestPath.lineTo(baseX, baseY);
      canvas.drawPath(crestPath, crestPaint);
    }
  }

  void _drawRideIndicator(Canvas canvas, Offset center) {
    // Bouncing arrow above bird
    final bounce = sin(_wingTimer * 2) * 5;
    final arrowY = center.dy - 45 + bounce;

    final arrowPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.8);

    final arrowPath = Path();
    arrowPath.moveTo(center.dx, arrowY);
    arrowPath.lineTo(center.dx - 10, arrowY - 15);
    arrowPath.lineTo(center.dx - 5, arrowY - 15);
    arrowPath.lineTo(center.dx - 5, arrowY - 25);
    arrowPath.lineTo(center.dx + 5, arrowY - 25);
    arrowPath.lineTo(center.dx + 5, arrowY - 15);
    arrowPath.lineTo(center.dx + 10, arrowY - 15);
    arrowPath.close();

    canvas.drawPath(arrowPath, arrowPaint);

    // Glow
    final glowPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(arrowPath, glowPaint);
  }

  void _drawRainbowTrail(Canvas canvas) {
    final colors = [
      Colors.red.withValues(alpha: 0.3),
      Colors.orange.withValues(alpha: 0.3),
      Colors.yellow.withValues(alpha: 0.3),
      Colors.green.withValues(alpha: 0.3),
      Colors.blue.withValues(alpha: 0.3),
      Colors.purple.withValues(alpha: 0.3),
    ];

    for (int i = 0; i < colors.length; i++) {
      final trailPaint = Paint()
        ..color = colors[i]
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final trailY = 30.0 + (i - 2.5) * 6;
      canvas.drawOval(
        Rect.fromLTWH(-30 - i * 10, trailY - 5, 40, 10),
        trailPaint,
      );
    }
  }
}
