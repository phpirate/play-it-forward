import 'dart:math';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/level_manager.dart';
import '../data/level_data.dart';

/// Overlay shown when completing a level
class LevelCompleteOverlay extends StatefulWidget {
  final PlayItForwardGame game;

  const LevelCompleteOverlay({super.key, required this.game});

  @override
  State<LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<LevelCompleteOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _starController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<double> _starRotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _starController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _starRotation = Tween<double>(begin: 0, end: 2 * pi).animate(_starController);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = LevelManager.instance.currentLevel;
    final coins = LevelManager.instance.currentLevelCoins;
    final time = LevelManager.instance.currentLevelTime;
    final hasNextLevel = level != null && level.number < LevelData.totalLevels;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF2E7D32).withValues(alpha: 0.95 * _fadeIn.value),
                const Color(0xFF1B5E20).withValues(alpha: 0.95 * _fadeIn.value),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Transform.scale(
                scale: _scaleIn.value,
                child: Opacity(
                  opacity: _fadeIn.value,
                  child: _buildContent(level, coins, time.toInt(), hasNextLevel),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(dynamic level, int coins, int timeSeconds, bool hasNextLevel) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Celebration icon
            _buildCelebrationIcon(),

            const SizedBox(height: 20),

            // Level Complete title
            const Text(
              'LEVEL COMPLETE!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3,
                shadows: [
                  Shadow(
                    color: Colors.black38,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Rescue message
            if (level != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          level.icon,
                          color: level.npcToHelp.primaryColor,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${level.npcToHelp.name} rescued!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '"${level.npcToHelp.dialogueOnRescue}"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Stats
            _buildStatsRow(coins, timeSeconds),

            const SizedBox(height: 16),

            // Follower bonus unlocked
            if (level != null) _buildBonusUnlocked(level),

            const SizedBox(height: 24),

            // World transformation hint
            _buildWorldTransformHint(),

            const SizedBox(height: 32),

            // Action buttons
            if (hasNextLevel)
              _buildNextLevelButton()
            else
              _buildCelebrationMessage(),

            const SizedBox(height: 12),

            _buildSecondaryButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationIcon() {
    return AnimatedBuilder(
      animation: _starRotation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Rotating stars
            Transform.rotate(
              angle: _starRotation.value,
              child: SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _StarPainter(),
                ),
              ),
            ),
            // Trophy icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.shade600,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 45,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsRow(int coins, int timeSeconds) {
    final minutes = timeSeconds ~/ 60;
    final seconds = timeSeconds % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatCard(Icons.monetization_on, coins.toString(), 'Coins', Colors.amber),
        const SizedBox(width: 20),
        _buildStatCard(Icons.timer, timeString, 'Time', Colors.blue),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusUnlocked(dynamic level) {
    final bonus = level.followerBonus;
    final bonusText = _getBonusText(bonus);
    if (bonusText.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.3),
            Colors.blue.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
          const SizedBox(width: 10),
          Text(
            'Follower Bonus: $bonusText',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getBonusText(dynamic bonus) {
    final parts = <String>[];
    if (bonus.coinValueBonus > 0) {
      parts.add('+${(bonus.coinValueBonus * 100).toInt()}% coins');
    }
    if (bonus.scoreMultiplierBonus > 0) {
      parts.add('+${(bonus.scoreMultiplierBonus * 100).toInt()}% score');
    }
    if (bonus.coinMagnetRange > 0) {
      parts.add('+${bonus.coinMagnetRange.toInt()} magnet');
    }
    if (bonus.speedBonus > 0) {
      parts.add('+${(bonus.speedBonus * 100).toInt()}% speed');
    }
    if (bonus.jumpHeightBonus > 0) {
      parts.add('+${(bonus.jumpHeightBonus * 100).toInt()}% jump');
    }
    if (bonus.comboTimerBonus > 0) {
      parts.add('+${(bonus.comboTimerBonus * 100).toInt()}% combo');
    }
    if (bonus.dashDurationBonus > 0) {
      parts.add('+${(bonus.dashDurationBonus * 100).toInt()}% dash');
    }
    if (bonus.birdWarning) {
      parts.add('Bird warning');
    }
    if (bonus.extraStartingLives > 0) {
      parts.add('+${bonus.extraStartingLives} life');
    }
    return parts.join(', ');
  }

  Widget _buildWorldTransformHint() {
    final completedLevels = LevelManager.instance.completedLevels;
    final saturation = (LevelData.getWorldSaturation(completedLevels) * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.landscape, color: Colors.teal, size: 20),
          const SizedBox(width: 10),
          Text(
            'World color restored: $saturation%',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextLevelButton() {
    final currentLevel = LevelManager.instance.currentLevel;
    final nextLevelNum = (currentLevel?.number ?? 0) + 1;

    return SizedBox(
      width: 220,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          widget.game.startNextLevel(nextLevelNum);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade600,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 8,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'NEXT LEVEL',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationMessage() {
    return Column(
      children: [
        const Text(
          '🎉 CAMPAIGN COMPLETE! 🎉',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You have helped everyone in the town!\nThe world is now full of color and kindness.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: () {
            widget.game.showLevelSelectFromComplete();
          },
          icon: const Icon(Icons.list, color: Colors.white70, size: 20),
          label: const Text(
            'Level Select',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        const SizedBox(width: 16),
        TextButton.icon(
          onPressed: () {
            widget.game.returnToMenu();
          },
          icon: const Icon(Icons.home, color: Colors.white70, size: 20),
          label: const Text(
            'Main Menu',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for decorative rotating stars
class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    const starCount = 6;
    for (int i = 0; i < starCount; i++) {
      final angle = (i / starCount) * 2 * pi;
      final x = size.width / 2 + cos(angle) * 45;
      final y = size.height / 2 + sin(angle) * 45;
      _drawStar(canvas, Offset(x, y), 6, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const points = 4;
    for (int i = 0; i < points * 2; i++) {
      final radius = i % 2 == 0 ? size : size * 0.4;
      final angle = (i / (points * 2)) * 2 * pi - pi / 2;
      final point = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
