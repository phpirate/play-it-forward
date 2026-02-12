import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/level_manager.dart';
import '../models/level.dart';

/// Overlay shown before starting a level
class LevelIntroOverlay extends StatefulWidget {
  final PlayItForwardGame game;

  const LevelIntroOverlay({super.key, required this.game});

  @override
  State<LevelIntroOverlay> createState() => _LevelIntroOverlayState();
}

class _LevelIntroOverlayState extends State<LevelIntroOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _slideIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideIn = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = LevelManager.instance.currentLevel;
    if (level == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                level.themeColor.withValues(alpha: 0.9 * _fadeIn.value),
                Colors.black.withValues(alpha: 0.85 * _fadeIn.value),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Transform.translate(
                offset: Offset(0, _slideIn.value),
                child: Opacity(
                  opacity: _fadeIn.value,
                  child: _buildContent(level),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(Level level) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Level number badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white38),
              ),
              child: Text(
                'LEVEL ${level.number}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Level title
            Text(
              level.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // NPC portrait circle
            _buildNPCPortrait(level),

            const SizedBox(height: 20),

            // NPC name and description
            Text(
              level.npcToHelp.name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: level.npcToHelp.primaryColor,
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                level.npcToHelp.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Story description
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                level.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Goal distance
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flag, color: Colors.amber, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Reach ${level.targetDistance.toInt()}m',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Start button
            _buildStartButton(level),

            const SizedBox(height: 16),

            // Back button
            TextButton.icon(
              onPressed: () {
                LevelManager.instance.endRun();
                widget.game.showLevelSelect();
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              label: const Text(
                'Back to Level Select',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNPCPortrait(Level level) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: level.themeColor.withValues(alpha: 0.3),
        border: Border.all(color: Colors.white38, width: 3),
        boxShadow: [
          BoxShadow(
            color: level.themeColor.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Icon(
        level.icon,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  Widget _buildStartButton(Level level) {
    return SizedBox(
      width: 200,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          widget.game.startCampaignLevel();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 8,
          shadowColor: Colors.green.withValues(alpha: 0.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow, size: 28),
            SizedBox(width: 8),
            Text(
              'START',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
