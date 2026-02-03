import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/world_manager.dart';
import '../models/world_theme.dart';

class WorldSelectOverlay extends StatefulWidget {
  final PlayItForwardGame game;

  const WorldSelectOverlay({super.key, required this.game});

  @override
  State<WorldSelectOverlay> createState() => _WorldSelectOverlayState();
}

class _WorldSelectOverlayState extends State<WorldSelectOverlay> {
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
                    onPressed: () => widget.game.hideWorldSelect(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'SELECT WORLD',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Highest distance display
            ListenableBuilder(
              listenable: WorldManager.instance,
              builder: (context, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.explore, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'Highest Distance: ${WorldManager.instance.highestDistance}m',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // World list
            Expanded(
              child: ListenableBuilder(
                listenable: WorldManager.instance,
                builder: (context, child) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: WorldThemes.all.length,
                    itemBuilder: (context, index) {
                      final world = WorldThemes.all[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _WorldCard(
                          world: world,
                          isSelected: world.id == WorldManager.instance.selectedWorldId,
                          isUnlocked: WorldManager.instance.isUnlocked(world.id),
                          progress: WorldManager.instance.getUnlockProgress(world.id),
                          onTap: () => _handleWorldTap(world),
                        ),
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

  void _handleWorldTap(WorldTheme world) {
    if (WorldManager.instance.isUnlocked(world.id)) {
      WorldManager.instance.selectWorld(world.id);
      setState(() {});
    }
  }
}

class _WorldCard extends StatelessWidget {
  final WorldTheme world;
  final bool isSelected;
  final bool isUnlocked;
  final double progress;
  final VoidCallback onTap;

  const _WorldCard({
    required this.world,
    required this.isSelected,
    required this.isUnlocked,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: world.colors.skyDay.withValues(alpha: 0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // World preview background
            _WorldPreview(world: world, isLocked: !isUnlocked),

            // Overlay for locked worlds
            if (!isUnlocked)
              Container(
                color: Colors.black54,
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // World name
                      Text(
                        world.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? Colors.white : Colors.grey,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 4),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Selected badge
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'SELECTED',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      // Locked indicator
                      if (!isUnlocked)
                        const Icon(Icons.lock, color: Colors.grey, size: 28),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Description
                  Text(
                    world.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUnlocked ? Colors.white70 : Colors.grey,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 2),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Unlock progress or modifiers
                  if (!isUnlocked)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unlock at ${world.unlockDistance}m',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Stack(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        // Weather icon
                        _WeatherIcon(weather: world.defaultWeather),
                        const SizedBox(width: 8),
                        // Gravity modifier
                        if (world.gravityModifier != 1.0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.expand_less, color: Colors.white, size: 16),
                                Text(
                                  world.gravityModifier < 1.0 ? 'Low Gravity' : 'High Gravity',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherIcon extends StatelessWidget {
  final WeatherType weather;

  const _WeatherIcon({required this.weather});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String label;

    switch (weather) {
      case WeatherType.clear:
        icon = Icons.wb_sunny;
        color = Colors.amber;
        label = 'Clear';
        break;
      case WeatherType.rain:
        icon = Icons.water_drop;
        color = Colors.blue;
        label = 'Rain';
        break;
      case WeatherType.snow:
        icon = Icons.ac_unit;
        color = Colors.lightBlue;
        label = 'Snow';
        break;
      case WeatherType.sandstorm:
        icon = Icons.air;
        color = Colors.orange;
        label = 'Sandstorm';
        break;
      case WeatherType.aurora:
        icon = Icons.auto_awesome;
        color = Colors.purple;
        label = 'Aurora';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _WorldPreview extends StatelessWidget {
  final WorldTheme world;
  final bool isLocked;

  const _WorldPreview({required this.world, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    final colors = world.colors;

    return CustomPaint(
      size: const Size(double.infinity, 140),
      painter: _WorldPreviewPainter(colors: colors, isLocked: isLocked),
    );
  }
}

class _WorldPreviewPainter extends CustomPainter {
  final WorldColors colors;
  final bool isLocked;

  _WorldPreviewPainter({required this.colors, required this.isLocked});

  @override
  void paint(Canvas canvas, Size size) {
    // Sky gradient
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [colors.skyDay, colors.skyDawn],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = skyGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Far hills
    final hillPath = Path();
    hillPath.moveTo(0, size.height * 0.6);
    hillPath.quadraticBezierTo(size.width * 0.25, size.height * 0.4, size.width * 0.5, size.height * 0.55);
    hillPath.quadraticBezierTo(size.width * 0.75, size.height * 0.45, size.width, size.height * 0.5);
    hillPath.lineTo(size.width, size.height);
    hillPath.lineTo(0, size.height);
    hillPath.close();
    canvas.drawPath(hillPath, Paint()..color = colors.hillsFar);

    // Near hills
    final nearHillPath = Path();
    nearHillPath.moveTo(0, size.height * 0.75);
    nearHillPath.quadraticBezierTo(size.width * 0.3, size.height * 0.6, size.width * 0.6, size.height * 0.7);
    nearHillPath.quadraticBezierTo(size.width * 0.85, size.height * 0.65, size.width, size.height * 0.72);
    nearHillPath.lineTo(size.width, size.height);
    nearHillPath.lineTo(0, size.height);
    nearHillPath.close();
    canvas.drawPath(nearHillPath, Paint()..color = colors.hillsNear);

    // Ground
    final groundGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [colors.groundTop, colors.groundMiddle, colors.groundBottom],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.85, size.width, size.height * 0.15),
      Paint()..shader = groundGradient.createShader(
        Rect.fromLTWH(0, size.height * 0.85, size.width, size.height * 0.15),
      ),
    );

    // Grass
    for (double x = 0; x < size.width; x += 8) {
      final grassPath = Path();
      grassPath.moveTo(x, size.height * 0.85);
      grassPath.lineTo(x + 2, size.height * 0.85 - 6);
      grassPath.lineTo(x + 4, size.height * 0.85);
      canvas.drawPath(grassPath, Paint()..color = colors.grassLight);
    }

    // Trees
    for (double x = 30; x < size.width; x += 80) {
      // Trunk
      canvas.drawRect(
        Rect.fromLTWH(x - 3, size.height * 0.65, 6, 20),
        Paint()..color = colors.treeTrunk,
      );
      // Leaves
      final treePath = Path();
      treePath.moveTo(x, size.height * 0.45);
      treePath.lineTo(x + 15, size.height * 0.65);
      treePath.lineTo(x - 15, size.height * 0.65);
      treePath.close();
      canvas.drawPath(treePath, Paint()..color = colors.treeLeaves);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
