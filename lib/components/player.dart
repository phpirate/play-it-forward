import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/audio_manager.dart';
import '../managers/power_up_manager.dart';
import '../managers/character_manager.dart';
import '../models/character.dart';
import '../effects/particle_factory.dart';
import '../effects/squash_stretch.dart';
import 'obstacle.dart';
import 'coin.dart';
import 'bird.dart';
import 'power_up.dart';
import 'wall.dart';
import 'soul.dart';
import 'risky_path.dart';
import 'rideable_bird.dart';
import 'stone.dart';

class Player extends PositionComponent with HasGameRef<PlayItForwardGame>, CollisionCallbacks {
  Player() : super(size: Vector2(50, 60), anchor: Anchor.bottomCenter);

  // Base constants
  static const double _baseGravity = 1200;
  static const double _baseJumpForce = -500;
  final double maxJumpHoldTime = 0.25;
  static const double _baseAirJumpForce = -420;
  final int maxJumps = 2;

  // Dash constants
  final double dashDuration = 0.25;
  final double dashCooldown = 2.5;
  final double dashSpeedMultiplier = 2.5;

  // Glide constants
  final double glideGravityMultiplier = 0.25;
  static const double _baseMaxGlideDuration = 2.0;

  // Character ability modifiers
  double get gravity {
    final ability = CharacterManager.instance.selectedCharacter.ability;
    if (ability == CharacterAbility.lowGravity) {
      return _baseGravity * 0.75; // 25% less gravity
    }
    return _baseGravity;
  }

  double get jumpForce {
    final ability = CharacterManager.instance.selectedCharacter.ability;
    if (ability == CharacterAbility.lowGravity) {
      return _baseJumpForce * 1.15; // Higher jumps
    }
    return _baseJumpForce;
  }

  double get airJumpForce {
    final ability = CharacterManager.instance.selectedCharacter.ability;
    if (ability == CharacterAbility.lowGravity) {
      return _baseAirJumpForce * 1.15;
    }
    return _baseAirJumpForce;
  }

  double get maxGlideDuration {
    final ability = CharacterManager.instance.selectedCharacter.ability;
    if (ability == CharacterAbility.longerGlide) {
      return _baseMaxGlideDuration * 1.5; // 50% longer glide
    }
    return _baseMaxGlideDuration;
  }

  // Track dash count for ninja's double dash ability
  int _dashCount = 0;

  // Ground pound constants
  final double groundPoundForce = 1200;

  double velocityY = 0;

  // Dash state
  bool _isDashing = false;
  double _dashTimer = 0;
  double _dashCooldownTimer = 0;

  // Glide state
  bool _isGliding = false;
  double _glideTimer = 0;
  bool _glideHeld = false;

  // Ground pound state
  bool _isGroundPounding = false;

  // Wall jump state
  bool _isTouchingWall = false;
  bool _isWallSliding = false;
  double _wallSlideSpeed = 100; // Slow descent on wall
  Wall? _currentWall;

  // Riding bird state
  bool _isRidingBird = false;
  RideableBird? _currentBird;

  // Stone throwing while riding
  double _throwCooldown = 0;
  static const double throwCooldownDuration = 0.3; // Can throw every 0.3 seconds
  bool isOnGround = true;
  bool isJumping = false;
  double jumpHoldTime = 0;
  bool isSliding = false;
  double slideTimer = 0;
  final double slideDuration = 0.6;
  int _jumpCount = 0;

  // Dust trail timer
  double _dustTimer = 0;
  final double _dustInterval = 0.2; // Increased from 0.1 for better performance

  // Squash/stretch animation
  final SquashStretchController _animController = SquashStretchController();

  // Near-miss tracking
  final Set<int> _nearMissedObjects = {};
  bool _wasOnGround = true;

  // Animation timers
  double _runCycleTime = 0;
  double _blinkTimer = 0;
  double _nextBlinkTime = 2.0;
  bool _isBlinking = false;
  double _blinkDuration = 0;
  final Random _random = Random();

  // Expression state
  bool _isWorried = false;
  double _worriedTimer = 0;
  bool _isExcited = false;
  double _excitedTimer = 0;
  bool _isDetermined = false; // At high speed

  // Scarf physics
  final List<Vector2> _scarfPoints = [];
  static const int scarfSegments = 6;

  // Previous velocity for landing detection
  double _prevVelocityY = 0;

  late RectangleHitbox _hitbox;

  // Shield visual effect
  bool _showingShield = false;

  // Death animation
  bool _isDying = false;
  double _deathTimer = 0;
  double _deathRotation = 0;
  double _deathBounceY = 0;
  static const double deathAnimationDuration = 1.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    position = Vector2(80, gameRef.size.y - 100);

    // Add collision hitbox
    _hitbox = RectangleHitbox(
      size: Vector2(35, 50),
      position: Vector2(7, 10),
    );
    add(_hitbox);

    // Initialize scarf points
    for (int i = 0; i < scarfSegments; i++) {
      _scarfPoints.add(Vector2(0, 0));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Handle death animation
    if (_isDying) {
      _updateDeathAnimation(dt);
      return;
    }

    if (gameRef.gameState != GameState.playing) return;

    // If riding a bird, skip normal physics (bird controls position)
    if (_isRidingBird) {
      _updateRiding(dt);
      return;
    }

    // Update dash cooldown
    if (_dashCooldownTimer > 0) {
      _dashCooldownTimer -= dt;
    }

    // Update dash timer
    if (_isDashing) {
      _dashTimer -= dt;
      if (_dashTimer <= 0) {
        _isDashing = false;
      } else {
        // Spawn dash particles
        _spawnDashParticles();
      }
    }

    // Apply gravity (modified by glide or ground pound)
    double effectiveGravity = gravity;
    if (_isGliding && velocityY > 0) {
      effectiveGravity = gravity * glideGravityMultiplier;
      _glideTimer += dt;
      if (_glideTimer >= maxGlideDuration) {
        _isGliding = false;
      }
    } else if (_isGroundPounding) {
      effectiveGravity = 0; // Ground pound uses fixed velocity
    } else if (_isDashing) {
      effectiveGravity = gravity * 0.3; // Reduced gravity during dash
    }

    velocityY += effectiveGravity * dt;

    // Wall sliding - slow descent when touching wall and falling
    if (_isWallSliding && velocityY > _wallSlideSpeed) {
      velocityY = _wallSlideSpeed;
    }

    // Clear wall contact if on ground
    if (isOnGround) {
      _isTouchingWall = false;
      _isWallSliding = false;
      _currentWall = null;
    }

    // Apply jump hold for variable height
    if (isJumping && jumpHoldTime > 0) {
      jumpHoldTime -= dt;
    }

    // Handle slide timer
    if (isSliding) {
      slideTimer -= dt;
      if (slideTimer <= 0) {
        stopSlide();
      }
    }

    // Update position
    position.y += velocityY * dt;

    // Check for risky path platform collision first
    double? platformY;
    for (final child in gameRef.children) {
      if (child is RiskyPath) {
        platformY = child.getPlatformY(position.x);
        if (platformY != null) break;
      }
    }

    // Ground collision - use terrain height or platform
    final groundY = gameRef.ground.getGroundYAt(position.x);
    final effectiveGroundY = platformY ?? groundY;

    // Only land on platforms if falling down
    final canLandOnPlatform = platformY != null && velocityY > 0 && position.y <= platformY + 10;

    if (position.y >= effectiveGroundY && (platformY == null || canLandOnPlatform)) {
      position.y = effectiveGroundY;

      // Trigger landing animation and effects if we were in the air
      if (!_wasOnGround && !isSliding) {
        _animController.setState(PlayerAnimState.landing);

        // Ground pound landing creates big impact
        if (_isGroundPounding) {
          _isGroundPounding = false;
          gameRef.spawnLandingEffect(position, 1.5); // Extra intense
          gameRef.triggerScreenShake(15, 0.3);
          AudioManager.instance.playSfx('jump.mp3');
        } else {
          // Spawn landing effects based on fall speed
          final landingIntensity = (_prevVelocityY / 500).clamp(0.0, 1.0);
          if (landingIntensity > 0.2) {
            gameRef.spawnLandingEffect(position, landingIntensity);
          }
        }
      }

      velocityY = 0;
      isOnGround = true;
      isJumping = false;
      _jumpCount = 0; // Reset jump count on landing
      _isGliding = false;
      _glideTimer = 0;
    } else if (platformY == null && position.y < groundY) {
      // In the air (no platform beneath and above ground)
      isOnGround = false;
    }
    _prevVelocityY = velocityY;
    _wasOnGround = isOnGround;

    // Update run cycle animation
    if (isOnGround && !isSliding) {
      _runCycleTime += dt * 12; // Speed of run animation
    }

    // Update blink animation
    _updateBlink(dt);

    // Update worried expression timer
    if (_isWorried) {
      _worriedTimer -= dt;
      if (_worriedTimer <= 0) {
        _isWorried = false;
      }
    }

    // Update excited expression timer
    if (_isExcited) {
      _excitedTimer -= dt;
      if (_excitedTimer <= 0) {
        _isExcited = false;
      }
    }

    // Determined expression at high speed
    _isDetermined = gameRef.effectiveGameSpeed > 500;

    // Update scarf physics
    _updateScarf(dt);

    // Spawn dust particles while running on ground
    if (isOnGround && !isSliding) {
      _dustTimer += dt;
      if (_dustTimer >= _dustInterval) {
        _dustTimer = 0;
        _spawnDustParticles();
      }
    }

    // Update squash/stretch animation
    _updateAnimationState();
    _animController.update(dt);

    // Update shield visual based on power-up state
    final shieldActive =
        gameRef.powerUpManager.isActive(PowerUpType.shield);
    if (shieldActive && !_showingShield) {
      _showingShield = true;
    } else if (!shieldActive && _showingShield) {
      _showingShield = false;
    }
  }

  void _updateBlink(double dt) {
    _blinkTimer += dt;

    if (_isBlinking) {
      _blinkDuration += dt;
      if (_blinkDuration >= 0.1) {
        _isBlinking = false;
        _blinkDuration = 0;
        _nextBlinkTime = 2.0 + _random.nextDouble() * 3.0;
        _blinkTimer = 0;
      }
    } else if (_blinkTimer >= _nextBlinkTime) {
      _isBlinking = true;
    }
  }

  /// Set worried expression (called on near-miss)
  void setWorried() {
    _isWorried = true;
    _worriedTimer = 0.5;
  }

  /// Set excited expression (called on high combos)
  void setExcited() {
    _isExcited = true;
    _excitedTimer = 1.0;
  }

  /// Start death animation
  void startDeathAnimation() {
    if (_isDying) return;
    _isDying = true;
    _deathTimer = 0;
    _deathRotation = 0;
    _deathBounceY = position.y;
    velocityY = -300; // Initial bounce up
  }

  void _updateDeathAnimation(double dt) {
    _deathTimer += dt;
    _deathRotation += dt * 10; // Spin

    // Apply gravity and update position
    velocityY += gravity * dt * 0.5;
    position.y += velocityY * dt;

    // Bounce on ground
    final groundY = gameRef.ground.getGroundYAt(position.x);
    if (position.y >= groundY && velocityY > 0) {
      position.y = groundY;
      velocityY = -velocityY * 0.5; // Damped bounce
      if (velocityY.abs() < 50) velocityY = 0;
    }

    // End animation and trigger game over
    if (_deathTimer >= deathAnimationDuration) {
      _isDying = false;
      gameRef.triggerGameOver();
    }
  }

  bool get isDying => _isDying;

  /// Update scarf physics
  void _updateScarf(double dt) {
    if (_scarfPoints.isEmpty) return;

    // Scarf anchor point (back of neck)
    final anchorX = position.x - 5;
    final anchorY = position.y - 45;

    // Wind and movement influence
    final windX = gameRef.effectiveGameSpeed * 0.15;
    final windY = velocityY * 0.05;

    // Update first point to anchor
    _scarfPoints[0] = Vector2(anchorX, anchorY);

    // Update rest of scarf with physics
    for (int i = 1; i < _scarfPoints.length; i++) {
      final prev = _scarfPoints[i - 1];
      final curr = _scarfPoints[i];

      // Target position (trailing behind previous point)
      final targetX = prev.x - 8;
      final targetY = prev.y + 3 + sin(_runCycleTime * 0.5 + i * 0.5) * 2;

      // Apply wind
      final windInfluence = i / _scarfPoints.length;
      curr.x += (targetX + windX * windInfluence - curr.x) * dt * 10;
      curr.y += (targetY + windY * windInfluence - curr.y) * dt * 10;

      // Constrain distance from previous point
      final dist = curr.distanceTo(prev);
      if (dist > 10) {
        final dir = (curr - prev).normalized();
        curr.x = prev.x + dir.x * 10;
        curr.y = prev.y + dir.y * 10;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw scarf behind character (in world coordinates)
    if (!_isDying) {
      _renderScarf(canvas);
    }

    // Get squash/stretch scale
    final scaleX = _animController.scaleX;
    final scaleY = _animController.scaleY;

    // Apply scale transformation
    canvas.save();
    canvas.translate(size.x / 2, size.y);

    // Apply death rotation
    if (_isDying) {
      canvas.translate(0, -size.y / 2);
      canvas.rotate(_deathRotation);
      canvas.translate(0, size.y / 2);
    }

    canvas.scale(scaleX, scaleY);
    canvas.translate(-size.x / 2, -size.y);

    if (isSliding) {
      _renderSliding(canvas);
    } else if (!isOnGround) {
      _renderJumping(canvas);
    } else {
      _renderRunning(canvas);
    }

    canvas.restore();

    // Draw shield effect on top
    if (_showingShield) {
      _renderShield(canvas);
    }

    // Draw invincibility effect (from soul or fever)
    if (gameRef.isPlayerInvincible) {
      _renderInvincibility(canvas);
    }
  }

  void _renderInvincibility(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2 - 5);
    final isFever = gameRef.feverManager.isFeverActive;

    // Pulsing effect
    final pulse = sin(_runCycleTime * 5) * 0.3 + 0.7;

    if (isFever) {
      // Rainbow fever glow
      final colors = [
        Colors.red.withValues(alpha: pulse * 0.3),
        Colors.orange.withValues(alpha: pulse * 0.3),
        Colors.yellow.withValues(alpha: pulse * 0.3),
        Colors.green.withValues(alpha: pulse * 0.3),
        Colors.blue.withValues(alpha: pulse * 0.3),
        Colors.purple.withValues(alpha: pulse * 0.3),
      ];
      for (int i = 0; i < colors.length; i++) {
        final radius = 45 - i * 5.0;
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = colors[i]
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
    } else {
      // Cyan soul glow
      final glowPaint = Paint()
        ..color = const Color(0xFF00FFFF).withValues(alpha: pulse * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(center, 40, glowPaint);

      // Inner glow
      final innerGlow = Paint()
        ..color = Colors.white.withValues(alpha: pulse * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(center, 30, innerGlow);
    }
  }

  void _renderScarf(Canvas canvas) {
    if (_scarfPoints.length < 2) return;

    // Draw scarf as a series of connected segments
    final scarfPath = Path();

    // Convert world coordinates to local coordinates
    final localPoints = _scarfPoints.map((p) =>
      Offset(p.x - position.x + size.x / 2, p.y - position.y + size.y)
    ).toList();

    // Create smooth path through points
    scarfPath.moveTo(localPoints[0].dx, localPoints[0].dy);

    for (int i = 1; i < localPoints.length; i++) {
      final p0 = i > 0 ? localPoints[i - 1] : localPoints[0];
      final p1 = localPoints[i];

      // Simple curve
      scarfPath.lineTo(p1.dx, p1.dy);
    }

    // Get scarf colors from character
    final characterColors = CharacterManager.instance.selectedCharacter.colors;

    // Draw scarf with gradient
    final scarfPaint = Paint()
      ..color = characterColors.scarf
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(scarfPath, scarfPaint);

    // Darker edge
    final edgePaint = Paint()
      ..color = characterColors.scarfDark
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(scarfPath, edgePaint);

    // Main scarf color on top
    canvas.drawPath(scarfPath, scarfPaint);

    // Highlight (lighter version of scarf color)
    final highlightPaint = Paint()
      ..color = Color.lerp(characterColors.scarf, Colors.white, 0.3) ?? characterColors.scarf
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final highlightPath = Path();
    highlightPath.moveTo(localPoints[0].dx, localPoints[0].dy - 2);
    for (int i = 1; i < localPoints.length - 1; i++) {
      highlightPath.lineTo(localPoints[i].dx, localPoints[i].dy - 2);
    }
    canvas.drawPath(highlightPath, highlightPaint);
  }

  void _renderRunning(Canvas canvas) {
    // Get colors from selected character
    final characterColors = CharacterManager.instance.selectedCharacter.colors;
    final bodyColor = characterColors.body;
    final bodyDarkColor = characterColors.bodyDark;
    final bodyLightColor = characterColors.bodyLight;
    final skinColor = characterColors.skin;

    // Leg animation (alternating)
    final legPhase = sin(_runCycleTime);
    final legOffset1 = legPhase * 8;
    final legOffset2 = -legPhase * 8;

    // Arm animation (opposite to legs)
    final armOffset1 = -legPhase * 6;
    final armOffset2 = legPhase * 6;

    // Shadow
    _drawShadow(canvas, Offset(25, size.y + 2));

    // Back leg
    _drawLeg(canvas, 30, size.y - 15 + legOffset2, bodyDarkColor);

    // Back arm
    _drawArm(canvas, 35, 30 + armOffset2, bodyDarkColor);

    // Body
    _drawBody(canvas, bodyColor, bodyLightColor, bodyDarkColor);

    // Front leg
    _drawLeg(canvas, 18, size.y - 15 + legOffset1, bodyColor);

    // Front arm
    _drawArm(canvas, 10, 30 + armOffset1, bodyColor);

    // Head
    _drawHead(canvas, skinColor);
  }

  void _renderJumping(Canvas canvas) {
    final characterColors = CharacterManager.instance.selectedCharacter.colors;
    final bodyColor = characterColors.body;
    final bodyDarkColor = characterColors.bodyDark;
    final bodyLightColor = characterColors.bodyLight;
    final skinColor = characterColors.skin;

    // Shadow (smaller when higher)
    _drawShadow(canvas, Offset(25, size.y + 2));

    // Legs together, slightly bent
    _drawLeg(canvas, 20, size.y - 10, bodyColor);
    _drawLeg(canvas, 28, size.y - 10, bodyDarkColor);

    // Body
    _drawBody(canvas, bodyColor, bodyLightColor, bodyDarkColor);

    // Arms up
    _drawArm(canvas, 8, 18, bodyColor, angle: -0.8);
    _drawArm(canvas, 38, 18, bodyColor, angle: 0.8);

    // Head
    _drawHead(canvas, skinColor);
  }

  void _renderSliding(Canvas canvas) {
    final characterColors = CharacterManager.instance.selectedCharacter.colors;
    final bodyColor = characterColors.body;
    final bodyDarkColor = characterColors.bodyDark;
    final bodyLightColor = characterColors.bodyLight;
    final skinColor = characterColors.skin;

    // Shadow
    _drawShadow(canvas, Offset(25, size.y + 2), wide: true);

    // Sliding body (horizontal)
    final slideBodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(5, size.y - 25, 45, 20),
      const Radius.circular(8),
    );
    final bodyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [bodyLightColor, bodyColor, bodyDarkColor],
    );
    canvas.drawRRect(
      slideBodyRect,
      Paint()..shader = bodyGradient.createShader(slideBodyRect.outerRect),
    );

    // Head at front
    final headCenter = Offset(45, size.y - 22);
    _drawHeadAt(canvas, headCenter, skinColor, small: true);

    // Legs stretched back
    final legPaint = Paint()..color = bodyColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-5, size.y - 18, 20, 8),
        const Radius.circular(4),
      ),
      legPaint,
    );
  }

  void _drawShadow(Canvas canvas, Offset center, {bool wide = false}) {
    // Get dynamic shadow offset from day/night cycle
    final (shadowOffsetX, shadowLength) = gameRef.dayNightCycle.getShadowOffset();

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25 * shadowLength)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + shadowOffsetX, center.dy),
        width: (wide ? 50 : 35) * shadowLength,
        height: 8,
      ),
      shadowPaint,
    );
  }

  void _drawBody(Canvas canvas, Color bodyColor, Color lightColor, Color darkColor) {
    // Torso with rounded rectangle and gradient
    final torsoRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 20, 30, 35),
      const Radius.circular(8),
    );

    final bodyGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [lightColor, bodyColor, darkColor],
      stops: const [0.0, 0.5, 1.0],
    );

    canvas.drawRRect(
      torsoRect,
      Paint()..shader = bodyGradient.createShader(torsoRect.outerRect),
    );

    // Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12, 22, 12, 15),
        const Radius.circular(6),
      ),
      highlightPaint,
    );
  }

  void _drawLeg(Canvas canvas, double x, double y, Color color) {
    final legPaint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, 10, 18),
        const Radius.circular(4),
      ),
      legPaint,
    );

    // Shoe
    final shoePaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 2, y + 14, 14, 6),
        const Radius.circular(3),
      ),
      shoePaint,
    );
  }

  void _drawArm(Canvas canvas, double x, double y, Color color, {double angle = 0}) {
    canvas.save();
    canvas.translate(x + 4, y);
    canvas.rotate(angle);

    final armPaint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-4, 0, 8, 16),
        const Radius.circular(4),
      ),
      armPaint,
    );

    // Hand
    final handPaint = Paint()..color = const Color(0xFFFFDBB4);
    canvas.drawCircle(const Offset(0, 16), 4, handPaint);

    canvas.restore();
  }

  void _drawHead(Canvas canvas, Color skinColor) {
    _drawHeadAt(canvas, const Offset(25, 15), skinColor);
  }

  void _drawHeadAt(Canvas canvas, Offset center, Color skinColor, {bool small = false}) {
    final scale = small ? 0.7 : 1.0;
    final headRadius = 12.0 * scale;

    // Head circle with gradient
    final headGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        skinColor,
        Color.lerp(skinColor, const Color(0xFFD4A574), 0.3) ?? skinColor,
      ],
    );
    final headRect = Rect.fromCircle(center: center, radius: headRadius);
    canvas.drawCircle(
      center,
      headRadius,
      Paint()..shader = headGradient.createShader(headRect),
    );

    // Eyes
    if (!small) {
      final eyeY = center.dy - 2;
      final eyeSpacing = 6.0;

      // Eye whites
      final eyeHeight = _isBlinking ? 1.0 : 6.0;
      final leftEyeRect = Rect.fromCenter(
        center: Offset(center.dx - eyeSpacing, eyeY),
        width: 6,
        height: eyeHeight,
      );
      final rightEyeRect = Rect.fromCenter(
        center: Offset(center.dx + eyeSpacing, eyeY),
        width: 6,
        height: eyeHeight,
      );

      canvas.drawOval(leftEyeRect, Paint()..color = Colors.white);
      canvas.drawOval(rightEyeRect, Paint()..color = Colors.white);

      // Pupils (only if not blinking)
      if (!_isBlinking) {
        // Pupils shift based on velocity
        final pupilShiftX = velocityY < 0 ? 0.0 : 1.0;
        final pupilShiftY = velocityY.clamp(-100, 100) / 100 * 1.5;

        canvas.drawCircle(
          Offset(center.dx - eyeSpacing + pupilShiftX, eyeY + pupilShiftY),
          2,
          Paint()..color = Colors.black,
        );
        canvas.drawCircle(
          Offset(center.dx + eyeSpacing + pupilShiftX, eyeY + pupilShiftY),
          2,
          Paint()..color = Colors.black,
        );
      }

      // Mouth
      final mouthY = center.dy + 5;
      final mouthPaint = Paint()
        ..color = const Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      if (_isWorried) {
        // Worried expression (wavy line)
        final mouthPath = Path();
        mouthPath.moveTo(center.dx - 4, mouthY);
        mouthPath.quadraticBezierTo(center.dx - 2, mouthY + 2, center.dx, mouthY);
        mouthPath.quadraticBezierTo(center.dx + 2, mouthY - 2, center.dx + 4, mouthY);
        canvas.drawPath(mouthPath, mouthPaint);
      } else if (_isExcited) {
        // Excited expression (big open smile)
        final mouthPath = Path();
        mouthPath.moveTo(center.dx - 5, mouthY - 1);
        mouthPath.quadraticBezierTo(center.dx, mouthY + 5, center.dx + 5, mouthY - 1);
        mouthPath.quadraticBezierTo(center.dx, mouthY + 2, center.dx - 5, mouthY - 1);
        canvas.drawPath(mouthPath, Paint()..color = const Color(0xFF5D4037));

        // Sparkle near eyes for excitement
        final sparklePaint = Paint()..color = const Color(0xFFFFD700);
        canvas.drawCircle(Offset(center.dx - 12, center.dy - 6), 2, sparklePaint);
        canvas.drawCircle(Offset(center.dx + 12, center.dy - 6), 2, sparklePaint);
      } else if (_isDetermined) {
        // Determined expression (straight focused line)
        final mouthPath = Path();
        mouthPath.moveTo(center.dx - 4, mouthY);
        mouthPath.lineTo(center.dx + 4, mouthY);
        canvas.drawPath(mouthPath, mouthPaint..strokeWidth = 2);

        // Furrowed brow effect (small lines above eyes)
        final browPaint = Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(center.dx - 8, center.dy - 8),
          Offset(center.dx - 4, center.dy - 7),
          browPaint,
        );
        canvas.drawLine(
          Offset(center.dx + 4, center.dy - 7),
          Offset(center.dx + 8, center.dy - 8),
          browPaint,
        );
      } else {
        // Happy smile
        final mouthPath = Path();
        mouthPath.moveTo(center.dx - 4, mouthY - 1);
        mouthPath.quadraticBezierTo(center.dx, mouthY + 3, center.dx + 4, mouthY - 1);
        canvas.drawPath(mouthPath, mouthPaint);
      }

      // Cheek blush
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx - 9, mouthY - 1),
          width: 4,
          height: 2,
        ),
        Paint()..color = const Color(0xFFFFB6C1).withValues(alpha: 0.5),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx + 9, mouthY - 1),
          width: 4,
          height: 2,
        ),
        Paint()..color = const Color(0xFFFFB6C1).withValues(alpha: 0.5),
      );
    }
  }

  void _renderShield(Canvas canvas) {
    final shieldCenter = Offset(size.x / 2, size.y / 2 - 5);

    // Outer glow
    final glowPaint = Paint()
      ..color = const Color(0xFF4169E1).withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(shieldCenter, 45, glowPaint);

    // Shield bubble
    final bubblePaint = Paint()
      ..color = const Color(0xFF4169E1).withValues(alpha: 0.15);
    canvas.drawCircle(shieldCenter, 40, bubblePaint);

    // Shield outline
    final outlinePaint = Paint()
      ..color = const Color(0xFF4169E1).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(shieldCenter, 40, outlinePaint);

    // Highlight arc
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: shieldCenter, radius: 35),
      -pi * 0.7,
      pi * 0.5,
      false,
      highlightPaint,
    );
  }

  void _updateAnimationState() {
    if (isSliding) {
      _animController.setState(PlayerAnimState.sliding);
    } else if (!isOnGround) {
      if (velocityY < 0) {
        _animController.setState(PlayerAnimState.jumping);
      } else {
        _animController.setState(PlayerAnimState.falling);
      }
    } else if (_animController.currentState != PlayerAnimState.landing) {
      _animController.setState(PlayerAnimState.running);
    }
  }

  void _spawnDustParticles() {
    final dustPos = Vector2(position.x - 10, position.y);
    final dust = ParticleFactory.createDustTrail(dustPos);
    if (dust != null) {
      gameRef.add(dust);
    }
  }

  void _spawnDashParticles() {
    final dashPos = Vector2(position.x - 15, position.y - 30);
    final dash = ParticleFactory.createDashTrail(dashPos);
    if (dash != null) {
      gameRef.add(dash);
    }
  }

  void jump() {
    if (isSliding) return; // Can't jump while sliding

    // Wall jump
    if (_isWallSliding && _isTouchingWall) {
      velocityY = jumpForce * 0.9;
      _isWallSliding = false;
      _isTouchingWall = false;
      _jumpCount = 1; // Reset to allow one more air jump
      _currentWall = null;
      AudioManager.instance.playSfx('jump.mp3');

      // Wall jump particles
      final ringPos = Vector2(position.x, position.y - 30);
      final ring = ParticleFactory.createDoubleJumpRing(ringPos);
      if (ring != null) {
        gameRef.add(ring);
      }
      return;
    }

    if (isOnGround) {
      // First jump from ground
      velocityY = jumpForce;
      isOnGround = false;
      isJumping = true;
      jumpHoldTime = maxJumpHoldTime;
      _jumpCount = 1;
      AudioManager.instance.playSfx('jump.mp3');
    } else if (_jumpCount < maxJumps) {
      // Double jump (air jump)
      velocityY = airJumpForce;
      _jumpCount++;
      AudioManager.instance.playSfx('jump.mp3');

      // Spawn double jump ring effect
      final ringPos = Vector2(position.x, position.y - 30);
      final ring = ParticleFactory.createDoubleJumpRing(ringPos);
      if (ring != null) {
        gameRef.add(ring);
      }
    } else if (isJumping && jumpHoldTime > 0) {
      // Extended jump while holding (only for first jump)
      velocityY = jumpForce * 0.6;
    }
  }

  void slide() {
    if (!isOnGround || isSliding) return; // Can only slide on ground

    isSliding = true;
    slideTimer = slideDuration;

    // Shrink hitbox for sliding
    _hitbox.size = Vector2(45, 25);
    _hitbox.position = Vector2(2, 35);

    AudioManager.instance.playSfx('jump.mp3'); // Reuse jump sound for now
  }

  /// Dash forward with a speed boost
  void dash() {
    if (_isDashing || isSliding) return;

    final ability = CharacterManager.instance.selectedCharacter.ability;
    final maxDashes = ability == CharacterAbility.doubleDash ? 2 : 1;

    // Check if we can dash (either cooldown is ready or we have dashes remaining for ninja)
    if (_dashCooldownTimer > 0 && _dashCount >= maxDashes) return;

    _isDashing = true;
    _dashTimer = dashDuration;
    _dashCount++;

    // Start cooldown only after all dashes used (for ninja) or after single dash (others)
    if (_dashCount >= maxDashes) {
      _dashCooldownTimer = dashCooldown;
      _dashCount = 0;
    }

    // Small upward boost if in air to feel better
    if (!isOnGround && velocityY > 0) {
      velocityY *= 0.3;
    }

    AudioManager.instance.playSfx('jump.mp3');
  }

  /// Start or stop gliding (called when jump button is held/released)
  void setGliding(bool gliding) {
    if (gliding && !isOnGround && velocityY > 0 && !_isGroundPounding) {
      _isGliding = true;
      _glideHeld = true;
    } else {
      _isGliding = false;
      _glideHeld = false;
    }
  }

  /// Ground pound - slam downward fast
  void groundPound() {
    if (isOnGround || _isGroundPounding || isSliding) return;

    _isGroundPounding = true;
    _isGliding = false;
    velocityY = groundPoundForce;

    AudioManager.instance.playSfx('jump.mp3');
  }

  // Getters for UI
  bool get isDashing => _isDashing;
  double get dashCooldownProgress => _dashCooldownTimer > 0
      ? 1.0 - (_dashCooldownTimer / dashCooldown)
      : 1.0;
  bool get canDash => _dashCooldownTimer <= 0 && !_isDashing;
  bool get isGliding => _isGliding;
  bool get isGroundPounding => _isGroundPounding;
  bool get isWallSliding => _isWallSliding;
  bool get isRidingBird => _isRidingBird;

  /// Start riding a bird
  void startRiding(RideableBird bird) {
    _isRidingBird = true;
    _currentBird = bird;
    isOnGround = false;
    velocityY = 0;
    _isGliding = false;
    _isGroundPounding = false;
  }

  /// End riding (bird flies away)
  void endRiding() {
    _isRidingBird = false;
    _currentBird = null;
    // Give a small upward boost when dismounting
    velocityY = jumpForce * 0.4;
  }

  void _updateRiding(double dt) {
    // Update animations while riding
    _runCycleTime += dt * 8;
    _updateBlink(dt);
    _updateScarf(dt);

    // Update throw cooldown
    if (_throwCooldown > 0) {
      _throwCooldown -= dt;
    }

    // Player is excited while riding
    _isExcited = true;
    _excitedTimer = 1.0;
  }

  /// Throw a stone while riding (called on tap)
  void throwStone() {
    if (!_isRidingBird || _throwCooldown > 0) return;

    _throwCooldown = throwCooldownDuration;

    // Create stone flying forward and slightly up
    final stonePos = Vector2(position.x + 30, position.y - 20);
    final stoneVelocity = Vector2(500, -50); // Fast forward, slight upward arc

    final stone = Stone(position: stonePos, velocity: stoneVelocity);
    gameRef.add(stone);

    // Play throw sound
    AudioManager.instance.playSfx('jump.mp3');
  }

  bool get canThrowStone => _isRidingBird && _throwCooldown <= 0;

  void stopSlide() {
    if (!isSliding) return;

    isSliding = false;
    slideTimer = 0;

    // Restore hitbox size
    _hitbox.size = Vector2(35, 50);
    _hitbox.position = Vector2(7, 10);
  }

  void reset() {
    final groundY = gameRef.ground.getGroundYAt(80);
    position = Vector2(80, groundY);
    velocityY = 0;
    _prevVelocityY = 0;
    isOnGround = true;
    isJumping = false;
    _jumpCount = 0;
    _dustTimer = 0;
    _wasOnGround = true;
    _nearMissedObjects.clear();
    _runCycleTime = 0;
    _blinkTimer = 0;
    _isBlinking = false;
    _isWorried = false;
    _isExcited = false;
    _isDetermined = false;

    // Reset new ability states
    _isDashing = false;
    _dashTimer = 0;
    _dashCooldownTimer = 0;
    _dashCount = 0;
    _isGliding = false;
    _glideTimer = 0;
    _glideHeld = false;
    _isGroundPounding = false;
    _isTouchingWall = false;
    _isWallSliding = false;
    _currentWall = null;
    _isRidingBird = false;
    _currentBird = null;
    _throwCooldown = 0;

    // Reset scarf positions
    for (int i = 0; i < _scarfPoints.length; i++) {
      _scarfPoints[i] = Vector2(position.x - i * 8, position.y - 45);
    }

    // Reset death animation
    _isDying = false;
    _deathTimer = 0;
    _deathRotation = 0;
    stopSlide();
    _showingShield = false;
    _animController.reset();
  }

  /// Check for near-miss with an obstacle/bird
  /// Called by obstacles/birds in their update method
  void checkNearMiss(PositionComponent obstacle) {
    if (gameRef.gameState != GameState.playing) return;

    // Skip if we already registered a near-miss with this object
    final objectId = obstacle.hashCode;
    if (_nearMissedObjects.contains(objectId)) return;

    // Calculate distance between centers
    final playerCenter = position + Vector2(25, -30);
    final obstacleCenter = obstacle.position + (obstacle.size / 2);

    final distance = playerCenter.distanceTo(obstacleCenter);

    // Near-miss threshold (close but not colliding)
    const nearMissThreshold = 60.0;
    const tooCloseThreshold = 40.0;

    if (distance < nearMissThreshold && distance > tooCloseThreshold) {
      _nearMissedObjects.add(objectId);

      // Trigger worried expression
      setWorried();

      // Trigger light screen shake
      gameRef.triggerScreenShake(4, 0.1);

      // Spawn near-miss particles between player and obstacle
      final effectPos = (playerCenter + obstacleCenter) / 2;
      final effect = ParticleFactory.createNearMissEffect(effectPos);
      if (effect != null) {
        gameRef.add(effect);
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is PowerUp) {
      other.collect();
      gameRef.collectPowerUp(other.type);
    } else if (other is RideableBird) {
      final bird = other;
      if (bird.isStomped) return;

      // Check if player is stomping (falling down onto bird)
      if (_isStompingRideableBird(bird, intersectionPoints)) {
        bird.startRide();
      } else if (!_isRidingBird) {
        // Side collision when not riding - try to survive
        _handleLethalCollision(other);
      }
    } else if (other is Bird) {
      final bird = other;
      if (bird.isStomped) return;

      // Check if player is stomping (falling down and feet are above bird's top)
      if (_isStompingBird(bird, intersectionPoints)) {
        _stompBird(bird);
      } else {
        // Side collision - try to survive
        _handleLethalCollision(other);
      }
    } else if (other is Obstacle) {
      // Lethal collision - try to survive
      _handleLethalCollision(other);
    } else if (other is Coin) {
      other.collect();
      gameRef.collectCoin();
    } else if (other is Soul) {
      other.collect();
      gameRef.collectSoul();
    } else if (other is Wall) {
      // Wall collision - initiate wall slide
      if (!isOnGround && velocityY >= 0) {
        _isTouchingWall = true;
        _isWallSliding = true;
        _currentWall = other;
        _jumpCount = 0; // Reset jump count to allow wall jump
      }
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);

    if (other is Wall && other == _currentWall) {
      _isTouchingWall = false;
      _isWallSliding = false;
      _currentWall = null;
    }
  }

  /// Check if player is stomping on a bird (falling down with feet above bird)
  bool _isStompingBird(Bird bird, Set<Vector2> intersectionPoints) {
    // Must be falling down
    if (velocityY <= 0) return false;

    // Player's feet (bottom of player) should be near the top of the bird
    final playerBottom = position.y;
    final birdTop = bird.position.y;

    // Check if most intersection points are near the top of the bird
    // This means we're landing on top, not hitting from the side
    final topHits = intersectionPoints.where((point) {
      return point.y < bird.position.y + bird.size.y * 0.4;
    }).length;

    return topHits > intersectionPoints.length / 2 && playerBottom < birdTop + 20;
  }

  /// Check if player is stomping on a rideable bird
  bool _isStompingRideableBird(RideableBird bird, Set<Vector2> intersectionPoints) {
    // Must be falling down
    if (velocityY <= 0) return false;

    // Player's feet should be near the top of the bird
    final playerBottom = position.y;
    final birdTop = bird.position.y;

    final topHits = intersectionPoints.where((point) {
      return point.y < bird.position.y + bird.size.y * 0.4;
    }).length;

    return topHits > intersectionPoints.length / 2 && playerBottom < birdTop + 25;
  }

  /// Handle stomping a bird
  void _stompBird(Bird bird) {
    // Stomp the bird
    bird.stomp();

    // Bounce player upward
    velocityY = jumpForce * 0.6; // Smaller bounce than regular jump

    // Award bonus coins (3 coins for stomping)
    const stompBonus = 3;
    gameRef.collectStompBonus(stompBonus, bird.position + bird.size / 2);

    // Play stomp sound (reuse jump sound)
    AudioManager.instance.playSfx('jump.mp3');

    // Light screen shake
    gameRef.triggerScreenShake(6, 0.15);
  }

  /// Handle a potentially lethal collision
  /// Checks: invincibility -> shield -> soul -> game over
  void _handleLethalCollision(PositionComponent other) {
    // If invincible (from fever or soul), ignore
    if (gameRef.isPlayerInvincible) {
      // Destroy the obstacle during fever
      if (gameRef.feverManager.isFeverActive) {
        other.removeFromParent();
      }
      return;
    }

    // Try shield first
    if (gameRef.powerUpManager.consumeShield()) {
      _breakShieldOnCollision(other);
      return;
    }

    // Try to use a soul
    if (gameRef.consumeSoul()) {
      // Soul saved us! Bounce back a little
      velocityY = jumpForce * 0.5;
      other.removeFromParent();
      return;
    }

    // No protection - game over
    gameRef.gameOver();
  }

  /// Break shield and remove obstacle
  void _breakShieldOnCollision(PositionComponent other) {
    AudioManager.instance.playSfx('shield_break.mp3');

    // Spawn shield break particles and trigger screen shake
    final breakPos = Vector2(position.x + 25, position.y - 30);
    final shieldBreak = ParticleFactory.createShieldBreak(breakPos);
    if (shieldBreak != null) {
      gameRef.add(shieldBreak);
    }
    gameRef.triggerScreenShake(12, 0.25);

    // Remove the obstacle/bird that hit us
    other.removeFromParent();
  }
}
