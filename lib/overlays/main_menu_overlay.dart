import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/score_manager.dart';
import '../managers/tutorial_manager.dart';
import '../managers/level_manager.dart';

class MainMenuOverlay extends StatelessWidget {
  final PlayItForwardGame game;

  const MainMenuOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade300,
            Colors.blue.shade700,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              const Text(
                'PLAY IT\nFORWARD',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(3, 3),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'A Charity Endless Runner',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 50),

              // High Score
              if (ScoreManager.instance.highScore > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'High Score: ${ScoreManager.instance.highScore}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Campaign Button
              _MenuButton(
                text: 'CAMPAIGN',
                color: Colors.green,
                onPressed: () => game.showLevelSelect(),
              ),

              const SizedBox(height: 15),

              // Endless Mode Button
              _MenuButton(
                text: 'ENDLESS',
                color: Colors.blue,
                onPressed: () => game.startGame(),
              ),

              const SizedBox(height: 15),

              // Characters Button
              _MenuButton(
                text: 'CHARACTERS',
                color: Colors.teal,
                onPressed: () => game.showCharacterSelect(),
              ),

              const SizedBox(height: 15),

              // Worlds Button
              _MenuButton(
                text: 'WORLDS',
                color: Colors.indigo,
                onPressed: () => game.showWorldSelect(),
              ),

              const SizedBox(height: 15),

              // Missions Button
              _MenuButton(
                text: 'MISSIONS',
                color: Colors.amber.shade700,
                onPressed: () => game.showMissions(),
              ),

              const SizedBox(height: 15),

              // Support Button
              _MenuButton(
                text: 'SUPPORT',
                color: Colors.orange,
                onPressed: () => game.showDonation(),
              ),

              const SizedBox(height: 15),

              // Settings Button
              _MenuButton(
                text: 'SETTINGS',
                color: Colors.purple,
                onPressed: () => game.showSettings(),
              ),

              const SizedBox(height: 20),

              // Reset buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset Tutorial Button (for testing)
                  TextButton(
                    onPressed: () async {
                      await TutorialManager.instance.resetAll();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tutorial reset!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Reset Tutorial',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Reset Campaign Button (for testing)
                  TextButton(
                    onPressed: () async {
                      await LevelManager.instance.resetAll();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Campaign reset! All levels locked.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Reset Campaign',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Footer
              const Text(
                '100% Free • Optional Donations Support Charity',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.text,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 5,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
