import 'package:flutter/material.dart';

/// Types of obstacles that can spawn
enum ObstacleType {
  crate,        // Basic wooden crate (Level 1+)
  spike,        // Sharp spikes (Level 3+)
  tallCrate,    // Tall barrel (Level 4+)
  rollingLog,   // Rolling log that moves toward player (Level 5+)
  gap,          // Gap in ground to jump over (Level 6+)
  swingingRope, // Swinging rope obstacle (Level 7+)
  mudPuddle,    // Slows player down (Level 8+)
  fireJet,      // Periodic fire bursts (Level 9+)
}

/// Difficulty settings for a level
class LevelDifficulty {
  final double obstacleFrequency; // Multiplier for obstacle spawn rate (0.5 = half, 2.0 = double)
  final double birdChance; // Chance of birds spawning (0.0 to 1.0)
  final double speed; // Starting game speed
  final bool hasWalls; // Whether walls spawn
  final bool hasPowerUps; // Whether power-ups spawn
  final List<ObstacleType> allowedObstacles; // Which obstacles can spawn

  const LevelDifficulty({
    this.obstacleFrequency = 1.0,
    this.birdChance = 0.25,
    this.speed = 250,
    this.hasWalls = false,
    this.hasPowerUps = false,
    this.allowedObstacles = const [ObstacleType.crate],
  });
}

/// World transformation effects applied after completing a level
class WorldTransform {
  final double colorSaturation; // 0.0 (grayscale) to 1.0 (full color)
  final bool hasFlowers; // Whether flowers appear in background
  final bool hasTreeColor; // Whether trees have full color
  final bool hasBirdsInSky; // Whether decorative birds appear
  final bool hasVillage; // Whether village elements appear
  final bool hasRainbow; // Whether rainbow appears
  final bool hasCelebration; // Whether confetti/celebration effects

  const WorldTransform({
    this.colorSaturation = 0.0,
    this.hasFlowers = false,
    this.hasTreeColor = false,
    this.hasBirdsInSky = false,
    this.hasVillage = false,
    this.hasRainbow = false,
    this.hasCelebration = false,
  });
}

/// Data for an NPC that needs help (goal at end of level)
class NPCData {
  final String name;
  final String spriteType; // 'child', 'elder', 'bird', 'traveler', 'artist', etc.
  final String dialogueOnRescue;
  final Color primaryColor;
  final Color secondaryColor;
  final String description;

  const NPCData({
    required this.name,
    required this.spriteType,
    required this.dialogueOnRescue,
    required this.primaryColor,
    required this.secondaryColor,
    required this.description,
  });
}

/// Passive bonuses provided by rescued followers
class FollowerBonus {
  final double coinValueBonus; // +X% coin value
  final double scoreMultiplierBonus; // +X% score
  final double coinMagnetRange; // Extra coin attraction range in pixels
  final double speedBonus; // +X% starting speed (careful - makes game harder!)
  final double jumpHeightBonus; // +X% jump height
  final double comboTimerBonus; // +X% combo window duration
  final double dashDurationBonus; // +X% dash duration
  final bool birdWarning; // Birds glow/flash before appearing
  final int extraStartingLives; // Extra lives at level start

  const FollowerBonus({
    this.coinValueBonus = 0.0,
    this.scoreMultiplierBonus = 0.0,
    this.coinMagnetRange = 0.0,
    this.speedBonus = 0.0,
    this.jumpHeightBonus = 0.0,
    this.comboTimerBonus = 0.0,
    this.dashDurationBonus = 0.0,
    this.birdWarning = false,
    this.extraStartingLives = 0,
  });

  /// Combine multiple bonuses
  FollowerBonus operator +(FollowerBonus other) {
    return FollowerBonus(
      coinValueBonus: coinValueBonus + other.coinValueBonus,
      scoreMultiplierBonus: scoreMultiplierBonus + other.scoreMultiplierBonus,
      coinMagnetRange: coinMagnetRange + other.coinMagnetRange,
      speedBonus: speedBonus + other.speedBonus,
      jumpHeightBonus: jumpHeightBonus + other.jumpHeightBonus,
      comboTimerBonus: comboTimerBonus + other.comboTimerBonus,
      dashDurationBonus: dashDurationBonus + other.dashDurationBonus,
      birdWarning: birdWarning || other.birdWarning,
      extraStartingLives: extraStartingLives + other.extraStartingLives,
    );
  }
}

/// A single campaign level
class Level {
  final int number;
  final String title;
  final String description;
  final double targetDistance; // Goal in meters
  final NPCData npcToHelp;
  final WorldTransform worldEffect;
  final LevelDifficulty difficulty;
  final FollowerBonus followerBonus;

  const Level({
    required this.number,
    required this.title,
    required this.description,
    required this.targetDistance,
    required this.npcToHelp,
    required this.worldEffect,
    required this.difficulty,
    required this.followerBonus,
  });

  /// Get the icon for this level
  IconData get icon {
    switch (npcToHelp.spriteType) {
      case 'child':
        return Icons.child_care;
      case 'elder':
        return Icons.elderly;
      case 'bird':
        return Icons.flutter_dash;
      case 'traveler':
        return Icons.hiking;
      case 'artist':
        return Icons.palette;
      case 'musician':
        return Icons.music_note;
      case 'gardener':
        return Icons.local_florist;
      case 'teacher':
        return Icons.school;
      case 'doctor':
        return Icons.medical_services;
      case 'mayor':
        return Icons.people;
      default:
        return Icons.person;
    }
  }

  /// Get the color theme for this level
  Color get themeColor => npcToHelp.primaryColor;
}
