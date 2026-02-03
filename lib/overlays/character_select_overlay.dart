import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/character_manager.dart';
import '../models/character.dart' as game_characters;

class CharacterSelectOverlay extends StatefulWidget {
  final PlayItForwardGame game;

  const CharacterSelectOverlay({super.key, required this.game});

  @override
  State<CharacterSelectOverlay> createState() => _CharacterSelectOverlayState();
}

class _CharacterSelectOverlayState extends State<CharacterSelectOverlay> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => widget.game.hideCharacterSelect(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'SELECT CHARACTER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  // Coins display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade800,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.white, size: 20),
                        const SizedBox(width: 6),
                        ListenableBuilder(
                          listenable: CharacterManager.instance,
                          builder: (context, child) {
                            return Text(
                              '${CharacterManager.instance.totalCoins}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Character grid
            Expanded(
              child: ListenableBuilder(
                listenable: CharacterManager.instance,
                builder: (context, child) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: game_characters.Characters.all.length,
                    itemBuilder: (context, index) {
                      final character = game_characters.Characters.all[index];
                      return _CharacterCard(
                        character: character,
                        isSelected: character.id == CharacterManager.instance.selectedCharacterId,
                        isUnlocked: CharacterManager.instance.isUnlocked(character.id),
                        onTap: () => _handleCharacterTap(character),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCharacterTap(game_characters.GameCharacter character) {
    final manager = CharacterManager.instance;

    if (manager.isUnlocked(character.id)) {
      // Select the character
      manager.selectCharacter(character.id);
      setState(() {});
    } else {
      // Try to unlock
      if (manager.totalCoins >= character.unlockCost) {
        _showUnlockDialog(character);
      } else {
        _showNotEnoughCoinsDialog(character);
      }
    }
  }

  void _showUnlockDialog(game_characters.GameCharacter character) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        title: Text(
          'Unlock ${character.name}?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CharacterPreview(character: character),
            const SizedBox(height: 16),
            Text(
              character.description,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                character.abilityDescription,
                style: TextStyle(
                  color: character.colors.scarf,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 6),
                Text(
                  '${character.unlockCost}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              CharacterManager.instance.unlockCharacter(character.id);
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Unlock!'),
          ),
        ],
      ),
    );
  }

  void _showNotEnoughCoinsDialog(game_characters.GameCharacter character) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text(
          'Not Enough Coins',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You need ${character.unlockCost} coins to unlock ${character.name}.',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You have ${CharacterManager.instance.totalCoins} coins.',
              style: const TextStyle(color: Colors.amber),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final game_characters.GameCharacter character;
  final bool isSelected;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _CharacterCard({
    required this.character,
    required this.isSelected,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isUnlocked
                ? [
                    character.colors.bodyLight.withValues(alpha: 0.8),
                    character.colors.body.withValues(alpha: 0.8),
                    character.colors.bodyDark.withValues(alpha: 0.8),
                  ]
                : [
                    Colors.grey.shade700,
                    Colors.grey.shade800,
                    Colors.grey.shade900,
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: character.colors.body.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Character content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Character preview
                  Expanded(
                    child: _CharacterPreview(character: character, isLocked: !isUnlocked),
                  ),

                  // Name
                  Text(
                    character.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.white : Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Ability or cost
                  if (isUnlocked)
                    Text(
                      character.abilityDescription,
                      style: TextStyle(
                        fontSize: 10,
                        color: character.colors.scarf,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, color: Colors.grey, size: 14),
                        const SizedBox(width: 4),
                        const Icon(Icons.monetization_on, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '${character.unlockCost}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Selected badge
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CharacterPreview extends StatelessWidget {
  final game_characters.GameCharacter character;
  final bool isLocked;

  const _CharacterPreview({required this.character, this.isLocked = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(80, 100),
      painter: _CharacterPainter(character: character, isLocked: isLocked),
    );
  }
}

class _CharacterPainter extends CustomPainter {
  final game_characters.GameCharacter character;
  final bool isLocked;

  _CharacterPainter({required this.character, required this.isLocked});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = isLocked
        ? game_characters.CharacterColors(
            body: Colors.grey.shade600,
            bodyLight: Colors.grey.shade500,
            bodyDark: Colors.grey.shade700,
            skin: Colors.grey.shade400,
            scarf: Colors.grey.shade500,
            scarfDark: Colors.grey.shade600,
          )
        : character.colors;

    final centerX = size.width / 2;
    final baseY = size.height * 0.85;

    // Scarf
    final scarfPath = Path();
    scarfPath.moveTo(centerX - 5, baseY - 45);
    scarfPath.quadraticBezierTo(centerX - 20, baseY - 40, centerX - 30, baseY - 35);
    scarfPath.quadraticBezierTo(centerX - 25, baseY - 30, centerX - 20, baseY - 35);
    canvas.drawPath(
      scarfPath,
      Paint()
        ..color = colors.scarf
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centerX, baseY - 27), width: 25, height: 30),
      const Radius.circular(6),
    );
    final bodyGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [colors.bodyLight, colors.body, colors.bodyDark],
    );
    canvas.drawRRect(
      bodyRect,
      Paint()..shader = bodyGradient.createShader(bodyRect.outerRect),
    );

    // Legs
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 10, baseY - 12, 8, 14),
        const Radius.circular(3),
      ),
      Paint()..color = colors.body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 2, baseY - 12, 8, 14),
        const Radius.circular(3),
      ),
      Paint()..color = colors.bodyDark,
    );

    // Head
    canvas.drawCircle(
      Offset(centerX, baseY - 50),
      12,
      Paint()..color = colors.skin,
    );

    // Eyes
    if (!isLocked) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(centerX - 4, baseY - 52), width: 5, height: 5),
        Paint()..color = Colors.white,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(centerX + 4, baseY - 52), width: 5, height: 5),
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(Offset(centerX - 4, baseY - 52), 2, Paint()..color = Colors.black);
      canvas.drawCircle(Offset(centerX + 4, baseY - 52), 2, Paint()..color = Colors.black);

      // Smile
      final smilePath = Path();
      smilePath.moveTo(centerX - 4, baseY - 46);
      smilePath.quadraticBezierTo(centerX, baseY - 43, centerX + 4, baseY - 46);
      canvas.drawPath(
        smilePath,
        Paint()
          ..color = const Color(0xFF5D4037)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    } else {
      // Question mark for locked
      final textPainter = TextPainter(
        text: const TextSpan(
          text: '?',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(centerX - 5, baseY - 56));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
