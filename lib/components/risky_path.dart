import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/tutorial_manager.dart';
import 'coin.dart';
import 'treasure_chest.dart';

/// A risky path split - high road with more rewards, low road is safer
class RiskyPath extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final Random _random = Random();

  // Path configuration
  static const double pathLength = 600; // Total length of the split section
  static const double platformHeight = 120; // Height above ground for high road
  static const double platformWidth = 80;
  static const double gapWidth = 60; // Gap between platforms

  final List<_Platform> _platforms = [];
  final List<Component> _decorations = [];
  bool _coinsSpawned = false;

  RiskyPath({required Vector2 position}) : super(position: position);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final groundY = gameRef.ground.getGroundYAt(position.x);

    // Create warning sign at the start
    add(_WarningSign(position: Vector2(0, groundY - position.y - 60)));

    // Create the high road platforms
    double currentX = 100; // Start after warning sign
    int platformCount = 0;

    while (currentX < pathLength - 100) {
      final platformY = groundY - position.y - platformHeight;

      // Vary platform width slightly
      final width = platformWidth + _random.nextDouble() * 20 - 10;

      final platform = _Platform(
        position: Vector2(currentX, platformY),
        platformSize: Vector2(width, 20),
        isFirst: platformCount == 0,
        isLast: currentX + width + gapWidth >= pathLength - 100,
      );
      _platforms.add(platform);
      add(platform);

      currentX += width + gapWidth + _random.nextDouble() * 20;
      platformCount++;
    }

    // Add arrow indicators pointing up at the split
    add(_ArrowIndicator(
      position: Vector2(80, groundY - position.y - 40),
      pointsUp: true,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    // Move with game speed
    position.x -= gameRef.effectiveGameSpeed * dt;

    // Spawn coins once when path enters screen
    if (!_coinsSpawned && position.x < gameRef.size.x + 50) {
      _spawnRewards();
      _coinsSpawned = true;
    }

    // Tutorial hint when risky path is visible
    if (position.x < gameRef.size.x * 0.9) {
      TutorialManager.instance.tryShowHint(TutorialManager.hintRiskyPath);
    }

    // Remove when fully off screen
    if (position.x + pathLength < -50) {
      removeFromParent();
    }
  }

  void _spawnRewards() {
    final groundY = gameRef.ground.getGroundYAt(position.x);

    // HIGH ROAD: Many coins on platforms
    for (final platform in _platforms) {
      // Coins above each platform
      final numCoins = 3 + _random.nextInt(3);
      for (int i = 0; i < numCoins; i++) {
        final coinX = position.x + platform.position.x + 10 + i * 20;
        final coinY = groundY - platformHeight - 30 - _random.nextDouble() * 20;
        gameRef.add(Coin(position: Vector2(coinX, coinY)));
      }
    }

    // Chance for gold chest on high road (30%)
    if (_random.nextDouble() < 0.30 && _platforms.isNotEmpty) {
      final midPlatform = _platforms[_platforms.length ~/ 2];
      final chestX = position.x + midPlatform.position.x + midPlatform.platformSize.x / 2;
      final chestY = groundY - platformHeight - 20;

      // Higher chance for better chests on risky path
      final roll = _random.nextDouble();
      ChestTier tier;
      if (roll < 0.30) {
        tier = ChestTier.gold; // 30% gold on risky path!
      } else if (roll < 0.70) {
        tier = ChestTier.silver;
      } else {
        tier = ChestTier.bronze;
      }

      gameRef.add(TreasureChest(
        position: Vector2(chestX, chestY),
        tier: tier,
      ));
    }

    // LOW ROAD: Fewer coins on ground level
    final lowRoadCoins = 2 + _random.nextInt(2);
    for (int i = 0; i < lowRoadCoins; i++) {
      final coinX = position.x + 150 + i * 100 + _random.nextDouble() * 50;
      final coinY = groundY - 40 - _random.nextDouble() * 30;
      gameRef.add(Coin(position: Vector2(coinX, coinY)));
    }
  }

  /// Check if player is on a platform at given position
  bool isOnPlatform(Vector2 playerPos, Vector2 playerSize) {
    for (final platform in _platforms) {
      final platWorldX = position.x + platform.position.x;
      final platWorldY = position.y + platform.position.y;

      // Check if player is above and landing on platform
      if (playerPos.x + playerSize.x / 2 >= platWorldX &&
          playerPos.x - playerSize.x / 2 <= platWorldX + platform.platformSize.x) {
        final playerBottom = playerPos.y + playerSize.y;
        if (playerBottom >= platWorldY && playerBottom <= platWorldY + 25) {
          return true;
        }
      }
    }
    return false;
  }

  /// Get the Y position of platform at given X, or null if not on platform
  double? getPlatformY(double worldX) {
    for (final platform in _platforms) {
      final platWorldX = position.x + platform.position.x;
      if (worldX >= platWorldX && worldX <= platWorldX + platform.platformSize.x) {
        return position.y + platform.position.y;
      }
    }
    return null;
  }
}

/// A single platform in the high road
class _Platform extends PositionComponent {
  final Vector2 platformSize;
  final bool isFirst;
  final bool isLast;

  _Platform({
    required Vector2 position,
    required this.platformSize,
    this.isFirst = false,
    this.isLast = false,
  }) : super(position: position, size: platformSize);

  @override
  void render(Canvas canvas) {
    // Platform top (grass)
    final grassPaint = Paint()..color = const Color(0xFF4CAF50);
    final grassRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, 8),
      const Radius.circular(4),
    );
    canvas.drawRRect(grassRect, grassPaint);

    // Platform body (dirt)
    final dirtGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF8B4513),
        Color(0xFF5D4037),
      ],
    );
    final dirtRect = Rect.fromLTWH(0, 6, size.x, size.y - 6);
    final dirtPaint = Paint()..shader = dirtGradient.createShader(dirtRect);
    canvas.drawRect(dirtRect, dirtPaint);

    // Platform bottom edge
    final edgePaint = Paint()..color = const Color(0xFF3E2723);
    canvas.drawRect(
      Rect.fromLTWH(0, size.y - 3, size.x, 3),
      edgePaint,
    );

    // Ramp indicators on first/last platforms
    if (isFirst) {
      _drawRamp(canvas, true);
    }
    if (isLast) {
      _drawRamp(canvas, false);
    }
  }

  void _drawRamp(Canvas canvas, bool isEntry) {
    final rampPaint = Paint()..color = const Color(0xFF6D4C41);
    final path = Path();

    if (isEntry) {
      // Entry ramp on left side
      path.moveTo(0, size.y);
      path.lineTo(-15, size.y + 30);
      path.lineTo(0, size.y + 30);
      path.close();
    } else {
      // Exit ramp on right side
      path.moveTo(size.x, size.y);
      path.lineTo(size.x + 15, size.y + 30);
      path.lineTo(size.x, size.y + 30);
      path.close();
    }

    canvas.drawPath(path, rampPaint);
  }
}

/// Warning sign before path split
class _WarningSign extends PositionComponent {
  double _bounceTime = 0;

  _WarningSign({required Vector2 position})
      : super(position: position, size: Vector2(30, 40));

  @override
  void update(double dt) {
    super.update(dt);
    _bounceTime += dt * 4;
  }

  @override
  void render(Canvas canvas) {
    final bounce = sin(_bounceTime) * 2;

    canvas.save();
    canvas.translate(0, bounce);

    // Sign post
    final postPaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRect(
      Rect.fromLTWH(size.x / 2 - 3, size.y * 0.6, 6, size.y * 0.5),
      postPaint,
    );

    // Sign background (diamond shape)
    final signPaint = Paint()..color = const Color(0xFFFFD700);
    final path = Path();
    path.moveTo(size.x / 2, 0);
    path.lineTo(size.x, size.y * 0.4);
    path.lineTo(size.x / 2, size.y * 0.8);
    path.lineTo(0, size.y * 0.4);
    path.close();
    canvas.drawPath(path, signPaint);

    // Sign border
    final borderPaint = Paint()
      ..color = const Color(0xFFFF8F00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);

    // Exclamation mark
    final textPaint = Paint()..color = Colors.black;
    canvas.drawRect(
      Rect.fromLTWH(size.x / 2 - 2, size.y * 0.15, 4, size.y * 0.35),
      textPaint,
    );
    canvas.drawCircle(
      Offset(size.x / 2, size.y * 0.6),
      3,
      textPaint,
    );

    canvas.restore();
  }
}

/// Arrow indicator showing path choice
class _ArrowIndicator extends PositionComponent {
  final bool pointsUp;
  double _pulseTime = 0;

  _ArrowIndicator({required Vector2 position, required this.pointsUp})
      : super(position: position, size: Vector2(24, 30));

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTime += dt * 5;
  }

  @override
  void render(Canvas canvas) {
    final pulse = (sin(_pulseTime) + 1) / 2;
    final alpha = 0.5 + pulse * 0.5;

    final arrowPaint = Paint()
      ..color = const Color(0xFF4CAF50).withValues(alpha: alpha);

    final path = Path();
    if (pointsUp) {
      // Up arrow
      path.moveTo(size.x / 2, 0);
      path.lineTo(size.x, size.y * 0.4);
      path.lineTo(size.x * 0.65, size.y * 0.4);
      path.lineTo(size.x * 0.65, size.y);
      path.lineTo(size.x * 0.35, size.y);
      path.lineTo(size.x * 0.35, size.y * 0.4);
      path.lineTo(0, size.y * 0.4);
      path.close();
    }

    canvas.drawPath(path, arrowPaint);

    // Glow effect
    final glowPaint = Paint()
      ..color = const Color(0xFF4CAF50).withValues(alpha: alpha * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(path, glowPaint);
  }
}
