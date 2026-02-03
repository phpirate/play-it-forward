import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/power_up_manager.dart';
import '../managers/audio_manager.dart';
import '../managers/tutorial_manager.dart';
import '../effects/score_popup.dart';

/// Treasure chest tiers with different rewards
enum ChestTier {
  bronze,
  silver,
  gold,
}

/// A collectible treasure chest that gives coin bursts or rare power-ups
class TreasureChest extends PositionComponent
    with HasGameRef<PlayItForwardGame>, CollisionCallbacks {
  final ChestTier tier;
  final Random _random = Random();

  bool _isCollected = false;
  bool _isOpening = false;
  double _openTimer = 0;
  double _bounceTime = 0;
  double _glowPulse = 0;
  double _sparkleTimer = 0;

  // Chest visuals
  static const double chestWidth = 40;
  static const double chestHeight = 32;

  TreasureChest({
    required Vector2 position,
    required this.tier,
  }) : super(
          position: position,
          size: Vector2(chestWidth, chestHeight),
          anchor: Anchor.bottomCenter,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add hitbox for collision detection
    add(RectangleHitbox(
      size: Vector2(chestWidth - 8, chestHeight - 4),
      position: Vector2(4, 2),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    // Move with game speed
    position.x -= gameRef.effectiveGameSpeed * dt;

    // Tutorial hint when chest is visible
    if (position.x < gameRef.size.x * 0.8 && !_isCollected) {
      TutorialManager.instance.tryShowHint(TutorialManager.hintTreasureChest);
    }

    // Remove if off screen
    if (position.x < -60) {
      removeFromParent();
      return;
    }

    // Animate
    _bounceTime += dt * 3;
    _glowPulse += dt * 4;
    _sparkleTimer += dt;

    // Opening animation
    if (_isOpening) {
      _openTimer += dt;
      if (_openTimer >= 0.5) {
        _giveReward();
        removeFromParent();
      }
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (_isCollected || _isOpening) return;

    // Check if player collided
    if (other == gameRef.player) {
      _collectChest();
    }
  }

  void _collectChest() {
    _isCollected = true;
    _isOpening = true;

    // Play sound
    AudioManager.instance.playSfx('powerup.mp3');

    // Screen shake for gold chests
    if (tier == ChestTier.gold) {
      gameRef.triggerScreenShake(8, 0.3);
    }
  }

  void _giveReward() {
    final roll = _random.nextDouble();

    // Determine reward based on tier
    int coinReward;
    bool givesPowerUp = false;
    PowerUpType? powerUpType;

    switch (tier) {
      case ChestTier.bronze:
        // Bronze: 10-25 coins, 10% chance for common power-up
        coinReward = 10 + _random.nextInt(16);
        if (roll < 0.10) {
          givesPowerUp = true;
          powerUpType = PowerUpType.shield;
        }
        break;

      case ChestTier.silver:
        // Silver: 25-50 coins, 25% chance for power-up
        coinReward = 25 + _random.nextInt(26);
        if (roll < 0.25) {
          givesPowerUp = true;
          powerUpType = [
            PowerUpType.shield,
            PowerUpType.magnet,
            PowerUpType.doubleScore,
          ][_random.nextInt(3)];
        }
        break;

      case ChestTier.gold:
        // Gold: 50-100 coins, 50% chance for rare power-up
        coinReward = 50 + _random.nextInt(51);
        if (roll < 0.50) {
          givesPowerUp = true;
          powerUpType = [
            PowerUpType.shield,
            PowerUpType.magnet,
            PowerUpType.doubleScore,
            PowerUpType.slowMotion,
          ][_random.nextInt(4)];
        }
        break;
    }

    // Apply fever multiplier to coins
    final feverMultiplier = gameRef.feverManager.coinMultiplier;
    final totalCoins = coinReward * feverMultiplier;

    // Add coins
    gameRef.coins += totalCoins;

    // Show coin burst popup
    final tierName = tier.name.toUpperCase();
    gameRef.add(ScorePopup(
      position: position + Vector2(0, -40),
      text: '$tierName CHEST!\n+$totalCoins',
      color: _getTierColor(),
      fontSize: 18,
    ));

    // Give power-up if rolled
    if (givesPowerUp && powerUpType != null) {
      gameRef.collectPowerUp(powerUpType);

      // Show power-up popup
      gameRef.add(ScorePopup(
        position: position + Vector2(0, -70),
        text: '+${_getPowerUpName(powerUpType)}',
        color: Colors.purple,
        fontSize: 14,
      ));
    }

    // Spawn coin burst particles
    _spawnCoinBurst(coinReward ~/ 5);
  }

  String _getPowerUpName(PowerUpType type) {
    switch (type) {
      case PowerUpType.shield:
        return 'Shield';
      case PowerUpType.magnet:
        return 'Magnet';
      case PowerUpType.doubleScore:
        return '2x Score';
      case PowerUpType.slowMotion:
        return 'Slow-Mo';
    }
  }

  void _spawnCoinBurst(int count) {
    // Visual coin burst effect (coins flying out)
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * pi * 2;
      final velocity = Vector2(cos(angle), sin(angle)) * 100;
      gameRef.add(_BurstCoin(
        position: position.clone(),
        velocity: velocity,
        color: _getTierColor(),
      ));
    }
  }

  Color _getTierColor() {
    switch (tier) {
      case ChestTier.bronze:
        return const Color(0xFFCD7F32);
      case ChestTier.silver:
        return const Color(0xFFC0C0C0);
      case ChestTier.gold:
        return const Color(0xFFFFD700);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final tierColor = _getTierColor();
    final bounce = sin(_bounceTime) * 3;
    final glow = (sin(_glowPulse) + 1) / 2;

    // Save canvas state
    canvas.save();
    canvas.translate(0, bounce);

    // Glow effect
    if (!_isOpening) {
      final glowPaint = Paint()
        ..color = tierColor.withValues(alpha: 0.3 + glow * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(chestWidth / 2, chestHeight / 2),
            width: chestWidth + 10,
            height: chestHeight + 10,
          ),
          const Radius.circular(8),
        ),
        glowPaint,
      );
    }

    // Chest base (bottom part)
    final basePaint = Paint()..color = const Color(0xFF5D4037);
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, chestHeight * 0.4, chestWidth - 4, chestHeight * 0.6),
      const Radius.circular(4),
    );
    canvas.drawRRect(baseRect, basePaint);

    // Chest base highlight
    final baseHighlight = Paint()..color = const Color(0xFF8D6E63);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, chestHeight * 0.45, chestWidth - 8, chestHeight * 0.15),
        const Radius.circular(2),
      ),
      baseHighlight,
    );

    // Chest lid
    final lidOpenAngle = _isOpening ? _openTimer * pi * 0.8 : 0.0;
    canvas.save();
    canvas.translate(chestWidth / 2, chestHeight * 0.4);
    canvas.rotate(-lidOpenAngle);
    canvas.translate(-chestWidth / 2, -chestHeight * 0.4);

    final lidPaint = Paint()..color = const Color(0xFF6D4C41);
    final lidRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, chestWidth, chestHeight * 0.45),
      const Radius.circular(6),
    );
    canvas.drawRRect(lidRect, lidPaint);

    // Lid highlight
    final lidHighlight = Paint()..color = const Color(0xFF8D6E63);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, chestWidth - 4, chestHeight * 0.15),
        const Radius.circular(4),
      ),
      lidHighlight,
    );

    // Metal bands
    final bandPaint = Paint()..color = tierColor;
    // Top band
    canvas.drawRect(
      Rect.fromLTWH(0, chestHeight * 0.35, chestWidth, 4),
      bandPaint,
    );
    // Vertical bands
    canvas.drawRect(
      Rect.fromLTWH(chestWidth * 0.3, 0, 3, chestHeight * 0.4),
      bandPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(chestWidth * 0.65, 0, 3, chestHeight * 0.4),
      bandPaint,
    );

    canvas.restore(); // Restore lid rotation

    // Lock/clasp
    final lockPaint = Paint()..color = tierColor;
    final lockCenter = Offset(chestWidth / 2, chestHeight * 0.45);
    canvas.drawCircle(lockCenter, 6, lockPaint);

    // Lock keyhole
    final keyholePaint = Paint()..color = const Color(0xFF3E2723);
    canvas.drawCircle(lockCenter, 2, keyholePaint);
    canvas.drawRect(
      Rect.fromCenter(center: lockCenter + const Offset(0, 2), width: 2, height: 4),
      keyholePaint,
    );

    // Sparkles
    if (!_isOpening) {
      _drawSparkles(canvas, tierColor);
    }

    // Light burst when opening
    if (_isOpening) {
      final burstAlpha = (1 - _openTimer * 2).clamp(0.0, 1.0);
      final burstPaint = Paint()
        ..color = tierColor.withValues(alpha: burstAlpha * 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(
        Offset(chestWidth / 2, chestHeight / 2),
        30 + _openTimer * 50,
        burstPaint,
      );
    }

    canvas.restore(); // Restore bounce translation
  }

  void _drawSparkles(Canvas canvas, Color color) {
    final sparklePaint = Paint()..color = color;

    // Draw 3-4 sparkles around the chest
    for (int i = 0; i < 4; i++) {
      final angle = (_sparkleTimer * 2 + i * pi / 2) % (pi * 2);
      final distance = 25 + sin(_sparkleTimer * 3 + i) * 5;
      final sparkleX = chestWidth / 2 + cos(angle) * distance;
      final sparkleY = chestHeight / 2 + sin(angle) * distance * 0.6;

      final sparkleSize = 2 + sin(_sparkleTimer * 5 + i * 2) * 1;
      final alpha = (sin(_sparkleTimer * 4 + i) + 1) / 2;

      sparklePaint.color = color.withValues(alpha: alpha * 0.8);

      // Star sparkle shape
      _drawStar(canvas, Offset(sparkleX, sparkleY), sparkleSize, sparklePaint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2;
      final x = center.dx + cos(angle) * size;
      final y = center.dy + sin(angle) * size;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      // Inner point
      final innerAngle = angle + pi / 4;
      final innerX = center.dx + cos(innerAngle) * size * 0.3;
      final innerY = center.dy + sin(innerAngle) * size * 0.3;
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}

/// Visual effect coin that bursts from chest
class _BurstCoin extends PositionComponent {
  final Vector2 velocity;
  final Color color;
  double _life = 1.0;

  _BurstCoin({
    required Vector2 position,
    required this.velocity,
    required this.color,
  }) : super(position: position, size: Vector2.all(8));

  @override
  void update(double dt) {
    super.update(dt);

    // Move
    position += velocity * dt;
    velocity.y += 300 * dt; // Gravity

    // Fade out
    _life -= dt * 2;
    if (_life <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color.withValues(alpha: _life);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 4, paint);

    // Shine
    final shinePaint = Paint()..color = Colors.white.withValues(alpha: _life * 0.5);
    canvas.drawCircle(Offset(size.x / 2 - 1, size.y / 2 - 1), 1.5, shinePaint);
  }
}
