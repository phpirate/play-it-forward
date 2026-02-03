import 'package:flutter/material.dart';

/// Defines a themed world with unique visuals and gameplay modifiers
class WorldTheme {
  final String id;
  final String name;
  final String description;
  final int unlockDistance; // Distance in meters to unlock
  final WorldColors colors;
  final WeatherType defaultWeather;
  final double gravityModifier;
  final String? backgroundMusic;

  const WorldTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.unlockDistance,
    required this.colors,
    this.defaultWeather = WeatherType.clear,
    this.gravityModifier = 1.0,
    this.backgroundMusic,
  });
}

/// Color palette for a world theme
class WorldColors {
  // Sky colors for day/night cycle
  final Color skyDawn;
  final Color skyDay;
  final Color skyDusk;
  final Color skyNight;

  // Ground colors
  final Color groundTop;
  final Color groundMiddle;
  final Color groundBottom;
  final Color grassLight;
  final Color grassDark;

  // Background elements
  final Color hillsFar;
  final Color hillsNear;
  final Color treeTrunk;
  final Color treeLeaves;

  // Decorations
  final Color decorPrimary;
  final Color decorSecondary;

  const WorldColors({
    required this.skyDawn,
    required this.skyDay,
    required this.skyDusk,
    required this.skyNight,
    required this.groundTop,
    required this.groundMiddle,
    required this.groundBottom,
    required this.grassLight,
    required this.grassDark,
    required this.hillsFar,
    required this.hillsNear,
    required this.treeTrunk,
    required this.treeLeaves,
    required this.decorPrimary,
    required this.decorSecondary,
  });
}

enum WeatherType { clear, rain, snow, sandstorm, aurora }

/// All available world themes
class WorldThemes {
  static const forest = WorldTheme(
    id: 'forest',
    name: 'Forest',
    description: 'Peaceful woodland trails',
    unlockDistance: 0,
    colors: WorldColors(
      skyDawn: Color(0xFFFF9966),
      skyDay: Color(0xFF87CEEB),
      skyDusk: Color(0xFF4B0082),
      skyNight: Color(0xFF191970),
      groundTop: Color(0xFF8B4513),
      groundMiddle: Color(0xFF5D4037),
      groundBottom: Color(0xFF3E2723),
      grassLight: Color(0xFF4CAF50),
      grassDark: Color(0xFF2E7D32),
      hillsFar: Color(0xFF228B22),
      hillsNear: Color(0xFF1B5E20),
      treeTrunk: Color(0xFF5D4037),
      treeLeaves: Color(0xFF32CD32),
      decorPrimary: Color(0xFFFF6B6B), // Flowers
      decorSecondary: Color(0xFFFFE066), // Yellow flowers
    ),
    defaultWeather: WeatherType.clear,
  );

  static const desert = WorldTheme(
    id: 'desert',
    name: 'Desert',
    description: 'Scorching sands and ancient ruins',
    unlockDistance: 1000,
    colors: WorldColors(
      skyDawn: Color(0xFFFFB347),
      skyDay: Color(0xFF87CEFA),
      skyDusk: Color(0xFFFF6347),
      skyNight: Color(0xFF1A1A2E),
      groundTop: Color(0xFFDEB887),
      groundMiddle: Color(0xFFD2B48C),
      groundBottom: Color(0xFFC19A6B),
      grassLight: Color(0xFFDAA520), // Dry grass
      grassDark: Color(0xFFB8860B),
      hillsFar: Color(0xFFE6C88C),
      hillsNear: Color(0xFFD4A953),
      treeTrunk: Color(0xFF228B22), // Cactus
      treeLeaves: Color(0xFF2E8B57), // Cactus
      decorPrimary: Color(0xFF8B4513), // Rocks
      decorSecondary: Color(0xFFFFD700), // Golden artifacts
    ),
    defaultWeather: WeatherType.sandstorm,
  );

  static const snow = WorldTheme(
    id: 'snow',
    name: 'Snow',
    description: 'Frozen tundra and icy peaks',
    unlockDistance: 2500,
    colors: WorldColors(
      skyDawn: Color(0xFFFFB6C1),
      skyDay: Color(0xFFB0E0E6),
      skyDusk: Color(0xFF4682B4),
      skyNight: Color(0xFF0D1B2A),
      groundTop: Color(0xFFFFFFFF),
      groundMiddle: Color(0xFFE0E0E0),
      groundBottom: Color(0xFFB0C4DE),
      grassLight: Color(0xFFE8F4F8), // Snow
      grassDark: Color(0xFFCAE1EB),
      hillsFar: Color(0xFFB0C4DE),
      hillsNear: Color(0xFF87CEEB),
      treeTrunk: Color(0xFF5D4037),
      treeLeaves: Color(0xFF1B5E20), // Pine trees
      decorPrimary: Color(0xFF00CED1), // Ice crystals
      decorSecondary: Color(0xFFADD8E6), // Snowflakes
    ),
    defaultWeather: WeatherType.snow,
    gravityModifier: 1.0, // Ice is slippery but same gravity
  );

  static const space = WorldTheme(
    id: 'space',
    name: 'Space',
    description: 'Cosmic void and distant stars',
    unlockDistance: 5000,
    colors: WorldColors(
      skyDawn: Color(0xFF4A0E4E),
      skyDay: Color(0xFF1A1A2E),
      skyDusk: Color(0xFF16213E),
      skyNight: Color(0xFF0A0A0F),
      groundTop: Color(0xFF4A4A4A),
      groundMiddle: Color(0xFF2D2D2D),
      groundBottom: Color(0xFF1A1A1A),
      grassLight: Color(0xFF6B4C9A), // Alien plants
      grassDark: Color(0xFF4A3070),
      hillsFar: Color(0xFF2D1B4E),
      hillsNear: Color(0xFF1A0F2E),
      treeTrunk: Color(0xFF6B4C9A), // Crystal formations
      treeLeaves: Color(0xFFE040FB), // Glowing crystals
      decorPrimary: Color(0xFF00FFFF), // Cyan glow
      decorSecondary: Color(0xFFFF00FF), // Magenta glow
    ),
    defaultWeather: WeatherType.aurora,
    gravityModifier: 0.7, // Low gravity in space!
  );

  static List<WorldTheme> get all => [forest, desert, snow, space];

  static WorldTheme getById(String id) {
    return all.firstWhere((w) => w.id == id, orElse: () => forest);
  }
}
