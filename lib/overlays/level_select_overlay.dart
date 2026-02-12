import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/level_manager.dart';
import '../data/level_data.dart';
import '../models/level.dart';

/// Overlay for selecting campaign levels
class LevelSelectOverlay extends StatelessWidget {
  final PlayItForwardGame game;

  const LevelSelectOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.indigo.shade400.withValues(alpha: 0.95),
            Colors.indigo.shade900.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Level grid
            Expanded(
              child: _buildLevelGrid(context),
            ),

            // Footer with follower count
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => game.hideLevelSelect(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'CAMPAIGN',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildLevelGrid(BuildContext context) {
    return ListenableBuilder(
      listenable: LevelManager.instance,
      builder: (context, child) {
        final levelManager = LevelManager.instance;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: LevelData.totalLevels,
          itemBuilder: (context, index) {
            final levelNumber = index + 1;
            final level = LevelData.getLevel(levelNumber)!;
            final isUnlocked = levelManager.isLevelUnlocked(levelNumber);
            final isCompleted = levelManager.isLevelCompleted(levelNumber);
            final stats = levelManager.getLevelStats(levelNumber);

            return _LevelCard(
              level: level,
              isUnlocked: isUnlocked,
              isCompleted: isCompleted,
              stats: stats,
              onTap: isUnlocked
                  ? () => game.selectLevel(levelNumber)
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return ListenableBuilder(
      listenable: LevelManager.instance,
      builder: (context, child) {
        final completedLevels = LevelManager.instance.completedLevels;
        final totalLevels = LevelData.totalLevels;
        final saturation = LevelManager.instance.worldSaturation;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Followers count
              _buildStatItem(
                Icons.people,
                '$completedLevels / $totalLevels',
                'Followers',
                Colors.pink,
              ),
              // World color
              _buildStatItem(
                Icons.palette,
                '${(saturation * 100).toInt()}%',
                'World Color',
                Colors.teal,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  final Level level;
  final bool isUnlocked;
  final bool isCompleted;
  final LevelStats? stats;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.level,
    required this.isUnlocked,
    required this.isCompleted,
    required this.stats,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isUnlocked
              ? (isCompleted
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.15))
              : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
            color: isCompleted
                ? Colors.green
                : (isUnlocked ? level.themeColor : Colors.grey),
            width: isCompleted ? 3 : 2,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: level.themeColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Level number and icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? level.themeColor.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${level.number}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                      Icon(
                        level.icon,
                        color: isUnlocked ? level.themeColor : Colors.grey,
                        size: 28,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Level title
                  Text(
                    level.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.white : Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // NPC name
                  Text(
                    level.npcToHelp.name,
                    style: TextStyle(
                      fontSize: 11,
                      color: isUnlocked
                          ? level.npcToHelp.primaryColor
                          : Colors.grey.withValues(alpha: 0.7),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Distance goal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.flag,
                        size: 14,
                        color: isUnlocked ? Colors.amber : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${level.targetDistance.toInt()}m',
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnlocked ? Colors.amber : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  // Best stats if completed
                  if (isCompleted && stats != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.monetization_on, size: 12, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            '${stats!.coinsCollected}',
                            style: const TextStyle(fontSize: 11, color: Colors.amber),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Completed checkmark
            if (isCompleted)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),

            // Lock overlay
            if (!isUnlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock,
                          color: Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Complete Level ${level.number - 1}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
