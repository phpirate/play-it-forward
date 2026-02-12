import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/power_up_manager.dart';
import '../managers/fever_manager.dart';
import '../managers/level_manager.dart';

class HudOverlay extends StatelessWidget {
  final PlayItForwardGame game;

  const HudOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Score
                _buildScoreWidget(),

                // Pause Button
                IconButton(
                  onPressed: () => game.pauseGame(),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.pause,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),

            // Level progress bar (campaign mode only)
            if (LevelManager.instance.isPlayingCampaign)
              _buildLevelProgressBar(),

            const SizedBox(height: 4),

            // Lives indicator (campaign mode only)
            if (LevelManager.instance.isPlayingCampaign)
              _buildLivesWidget(),

            const SizedBox(height: 4),

            // Coins, Souls, Combo and Followers row
            Row(
              children: [
                _buildCoinWidget(),
                const SizedBox(width: 10),
                _buildSoulsWidget(),
                const SizedBox(width: 10),
                _buildComboWidget(),
                if (LevelManager.instance.isPlayingCampaign) ...[
                  const SizedBox(width: 10),
                  _buildFollowerWidget(),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // Active power-ups
            Align(
              alignment: Alignment.topLeft,
              child: _buildPowerUpsWidget(),
            ),

            const SizedBox(height: 8),

            // Fever meter
            _buildFeverMeter(),

            const Spacer(),

            // Ability indicators at bottom
            _buildAbilityIndicators(),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelProgressBar() {
    return ListenableBuilder(
      listenable: LevelManager.instance,
      builder: (context, child) {
        final levelManager = LevelManager.instance;
        final level = levelManager.currentLevel;
        if (level == null) return const SizedBox.shrink();

        final progress = levelManager.levelProgress;
        final currentDistance = levelManager.currentDistance.toInt();
        final targetDistance = level.targetDistance.toInt();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    level.icon,
                    color: level.themeColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Level ${level.number}: ${level.npcToHelp.name}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${currentDistance}m / ${targetDistance}m',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 200,
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 8,
                      width: 200 * progress,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            level.themeColor,
                            level.themeColor.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Goal flag at end
                    Positioned(
                      right: 0,
                      top: -2,
                      child: Icon(
                        Icons.flag,
                        size: 12,
                        color: progress >= 1.0 ? Colors.green : Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLivesWidget() {
    return ValueListenableBuilder<int>(
      valueListenable: _LivesNotifier(game),
      builder: (context, lives, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Lives: ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              ...List.generate(PlayItForwardGame.maxLives, (index) {
                final isActive = index < game.lives;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    isActive ? Icons.favorite : Icons.favorite_border,
                    color: isActive ? Colors.red : Colors.red.withValues(alpha: 0.3),
                    size: 20,
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFollowerWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pink.shade700,
            Colors.pink.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people, color: Colors.white, size: 18),
          const SizedBox(width: 5),
          Text(
            '${game.followerCount}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeverMeter() {
    return ListenableBuilder(
      listenable: game.feverManager,
      builder: (context, child) {
        final feverManager = game.feverManager;

        if (feverManager.isFeverActive) {
          // Show active fever countdown
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: 1.1),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF1493),
                        Color(0xFFFF69B4),
                        Color(0xFFFFD700),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF1493).withValues(alpha: 0.6),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'FEVER! ${feverManager.feverTimeRemaining.ceil()}s',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '3x',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.yellow.shade100,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        // Show fever meter
        return Container(
          width: 150,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: feverManager.feverProgress > 0.7
                        ? Colors.orange
                        : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'FEVER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Stack(
                children: [
                  Container(
                    height: 6,
                    width: 130,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 6,
                    width: 130 * feverManager.feverProgress,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: feverManager.feverProgress > 0.7
                            ? [Colors.orange, Colors.red]
                            : [Colors.pink.shade300, Colors.pink],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAbilityIndicators() {
    return ValueListenableBuilder<double>(
      valueListenable: _DashCooldownNotifier(game),
      builder: (context, cooldown, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dash ability
              _AbilityButton(
                icon: Icons.flash_on,
                label: 'E',
                color: const Color(0xFF00BFFF),
                progress: game.player.dashCooldownProgress,
                isReady: game.player.canDash,
              ),
              const SizedBox(width: 16),
              // Glide hint
              _AbilityButton(
                icon: Icons.air,
                label: 'Hold ↑',
                color: const Color(0xFF87CEEB),
                progress: 1.0,
                isReady: true,
                small: true,
              ),
              const SizedBox(width: 16),
              // Ground Pound hint
              _AbilityButton(
                icon: Icons.arrow_downward,
                label: '↓ Air',
                color: const Color(0xFFFF6B35),
                progress: 1.0,
                isReady: true,
                small: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScoreWidget() {
    return ValueListenableBuilder<int>(
      valueListenable: _ScoreNotifier(game),
      builder: (context, score, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Score: ${game.score}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoinWidget() {
    return ValueListenableBuilder<int>(
      valueListenable: _CoinsNotifier(game),
      builder: (context, coins, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
              const SizedBox(width: 5),
              Text(
                '${game.coins}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSoulsWidget() {
    return ValueListenableBuilder<int>(
      valueListenable: _SoulsNotifier(game),
      builder: (context, souls, child) {
        // Animate when souls change
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: 1.0),
          duration: const Duration(milliseconds: 200),
          key: ValueKey(game.souls),
          builder: (context, scale, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: game.souls > 0
                      ? [
                          const Color(0xFF006666),
                          const Color(0xFF008B8B),
                        ]
                      : [
                          Colors.grey.shade700,
                          Colors.grey.shade600,
                        ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: game.souls > 0
                    ? Border.all(color: const Color(0xFF00FFFF), width: 1)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite,
                    color: game.souls > 0
                        ? const Color(0xFF00FFFF)
                        : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${game.souls}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: game.souls > 0 ? Colors.white : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildComboWidget() {
    return ValueListenableBuilder<int>(
      valueListenable: _ComboNotifier(game),
      builder: (context, combo, child) {
        if (game.comboCount < 2) {
          return const SizedBox.shrink();
        }

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.2, end: 1.0),
          duration: const Duration(milliseconds: 150),
          key: ValueKey(game.comboCount),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade700,
                      Colors.amber.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      'x${game.comboCount}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPowerUpsWidget() {
    return ListenableBuilder(
      listenable: game.powerUpManager,
      builder: (context, child) {
        final activePowerUps = game.powerUpManager.activePowerUps;
        if (activePowerUps.isEmpty) {
          return const SizedBox.shrink();
        }

        return Wrap(
          spacing: 8,
          runSpacing: 4,
          children: activePowerUps.values.map((powerUp) {
            return _PowerUpIndicator(powerUp: powerUp);
          }).toList(),
        );
      },
    );
  }
}

class _PowerUpIndicator extends StatelessWidget {
  final ActivePowerUp powerUp;

  const _PowerUpIndicator({required this.powerUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getColor(), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(), color: _getColor(), size: 20),
          const SizedBox(width: 6),
          SizedBox(
            width: 40,
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: powerUp.progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: _getColor(),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${powerUp.remainingTime.ceil()}s',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (powerUp.type) {
      case PowerUpType.shield:
        return const Color(0xFF4169E1); // Royal blue
      case PowerUpType.magnet:
        return const Color(0xFFDC143C); // Crimson
      case PowerUpType.doubleScore:
        return const Color(0xFFFFD700); // Gold
      case PowerUpType.slowMotion:
        return const Color(0xFF9370DB); // Medium purple
    }
  }

  IconData _getIcon() {
    switch (powerUp.type) {
      case PowerUpType.shield:
        return Icons.shield;
      case PowerUpType.magnet:
        return Icons.attractions;
      case PowerUpType.doubleScore:
        return Icons.looks_two;
      case PowerUpType.slowMotion:
        return Icons.slow_motion_video;
    }
  }
}

class _AbilityButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double progress;
  final bool isReady;
  final bool small;

  const _AbilityButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.progress,
    required this.isReady,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = small ? 36.0 : 48.0;
    final iconSize = small ? 18.0 : 24.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black45,
                border: Border.all(
                  color: isReady ? color : Colors.grey,
                  width: 2,
                ),
              ),
            ),
            // Cooldown overlay
            if (!isReady)
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  color: color,
                  backgroundColor: Colors.transparent,
                ),
              ),
            // Icon
            Icon(
              icon,
              color: isReady ? color : Colors.grey,
              size: iconSize,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: small ? 9 : 10,
            color: isReady ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Simple notifier to trigger rebuilds
class _ScoreNotifier extends ValueNotifier<int> {
  final PlayItForwardGame game;

  _ScoreNotifier(this.game) : super(0) {
    _update();
  }

  void _update() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (game.gameState == GameState.playing) {
        value = game.score;
        _update();
      }
    });
  }
}

class _ComboNotifier extends ValueNotifier<int> {
  final PlayItForwardGame game;

  _ComboNotifier(this.game) : super(0) {
    _update();
  }

  void _update() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (game.gameState == GameState.playing) {
        value = game.comboCount;
        _update();
      }
    });
  }
}

class _DashCooldownNotifier extends ValueNotifier<double> {
  final PlayItForwardGame game;

  _DashCooldownNotifier(this.game) : super(1.0) {
    _update();
  }

  void _update() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (game.gameState == GameState.playing) {
        value = game.player.dashCooldownProgress;
        _update();
      }
    });
  }
}

class _SoulsNotifier extends ValueNotifier<int> {
  final PlayItForwardGame game;

  _SoulsNotifier(this.game) : super(0) {
    _update();
  }

  void _update() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (game.gameState == GameState.playing) {
        value = game.souls;
        _update();
      }
    });
  }
}

class _LivesNotifier extends ValueNotifier<int> {
  final PlayItForwardGame game;

  _LivesNotifier(this.game) : super(5) {
    _update();
  }

  void _update() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (game.gameState == GameState.playing) {
        value = game.lives;
        _update();
      }
    });
  }
}

class _CoinsNotifier extends ValueNotifier<int> {
  final PlayItForwardGame game;

  _CoinsNotifier(this.game) : super(0) {
    _update();
  }

  void _update() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (game.gameState == GameState.playing) {
        value = game.coins;
        _update();
      }
    });
  }
}
