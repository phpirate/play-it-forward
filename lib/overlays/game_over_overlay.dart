import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/score_manager.dart';

class GameOverOverlay extends StatelessWidget {
  final PlayItForwardGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final isNewHighScore = game.score >= ScoreManager.instance.highScore && game.score > 0;

    return Container(
      color: Colors.black54,
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'GAME OVER',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),

                const SizedBox(height: 20),

                // Score
                Text(
                  'Score: ${game.score}',
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 10),

                // Coins collected
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      '${game.coins}',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // High score indicator
                if (isNewHighScore)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '🎉 NEW HIGH SCORE! 🎉',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  )
                else
                  Text(
                    'Best: ${ScoreManager.instance.highScore}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),

                const SizedBox(height: 30),

                // Play Again Button
                SizedBox(
                  width: 180,
                  child: ElevatedButton(
                    onPressed: () => game.restartGame(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'PLAY AGAIN',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Support Button
                SizedBox(
                  width: 180,
                  child: ElevatedButton(
                    onPressed: () => game.showDonation(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'SUPPORT ❤️',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Menu Button
                TextButton(
                  onPressed: () => game.returnToMenu(),
                  child: const Text(
                    'Main Menu',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
