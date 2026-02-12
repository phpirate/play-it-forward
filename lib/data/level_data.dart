import 'package:flutter/material.dart';
import '../models/level.dart';

/// All campaign levels for "Chain of Kindness"
class LevelData {
  static const List<Level> levels = [
    // Level 1: The Lost Child
    Level(
      number: 1,
      title: "The Lost Child",
      description: "A young child named Lily has wandered too far from home and is scared. Can you help her find her way back?",
      targetDistance: 500,
      npcToHelp: NPCData(
        name: "Lily",
        spriteType: "child",
        dialogueOnRescue: "Thank you! I was so scared... Now I want to help others too!",
        primaryColor: Color(0xFFFFB6C1), // Light pink
        secondaryColor: Color(0xFFFF69B4), // Hot pink
        description: "A brave little girl who got lost while chasing butterflies.",
      ),
      worldEffect: WorldTransform(
        colorSaturation: 0.1,
        hasFlowers: true,
      ),
      difficulty: LevelDifficulty(
        obstacleFrequency: 0.7,
        birdChance: 0.0,
        speed: 250,
        hasWalls: false,
        hasPowerUps: false,
        allowedObstacles: [ObstacleType.crate], // Easy start - just crates
      ),
      followerBonus: FollowerBonus(
        coinValueBonus: 0.15, // +15% coin value - Lily spots shiny coins!
      ),
    ),

    // Level 2: The Tired Elder
    Level(
      number: 2,
      title: "The Tired Elder",
      description: "An elderly man named Marcus has traveled far and needs help reaching the village. His wisdom could guide many.",
      targetDistance: 700,
      npcToHelp: NPCData(
        name: "Marcus",
        spriteType: "elder",
        dialogueOnRescue: "Bless you, young one. Age has made my legs weak, but my heart still yearns to help.",
        primaryColor: Color(0xFF8B4513), // Saddle brown
        secondaryColor: Color(0xFFD2B48C), // Tan
        description: "A wise elder who has stories of kindness from generations past.",
      ),
      worldEffect: WorldTransform(
        colorSaturation: 0.2,
        hasFlowers: true,
        hasTreeColor: true,
      ),
      difficulty: LevelDifficulty(
        obstacleFrequency: 0.8,
        birdChance: 0.15,
        speed: 260,
        hasWalls: false,
        hasPowerUps: false,
        allowedObstacles: [ObstacleType.crate], // Still easy - just crates
      ),
      followerBonus: FollowerBonus(
        comboTimerBonus: 0.30, // +30% combo window - Elder's patience!
        scoreMultiplierBonus: 0.10, // +10% score from wisdom
      ),
    ),

    // Level 3: The Injured Bird
    Level(
      number: 3,
      title: "The Injured Bird",
      description: "A beautiful bluebird named Skyler has hurt its wing. Help it reach the healing springs so it can fly again.",
      targetDistance: 900,
      npcToHelp: NPCData(
        name: "Skyler",
        spriteType: "bird",
        dialogueOnRescue: "Chirp chirp! My wing feels better already! I'll sing songs of your kindness!",
        primaryColor: Color(0xFF87CEEB), // Sky blue
        secondaryColor: Color(0xFF4682B4), // Steel blue
        description: "A melodious bluebird who brings joy wherever it goes.",
      ),
      worldEffect: WorldTransform(
        colorSaturation: 0.35,
        hasFlowers: true,
        hasTreeColor: true,
        hasBirdsInSky: true,
      ),
      difficulty: LevelDifficulty(
        obstacleFrequency: 0.85,
        birdChance: 0.25,
        speed: 270,
        hasWalls: false,
        hasPowerUps: false,
        allowedObstacles: [ObstacleType.crate, ObstacleType.spike], // Introduce spikes!
      ),
      followerBonus: FollowerBonus(
        birdWarning: true, // Skyler warns you when birds approach!
        coinMagnetRange: 40.0, // +40 pixels magnet range - sharp bird eyes!
      ),
    ),

    // Level 4: The Hungry Traveler
    Level(
      number: 4,
      title: "The Hungry Traveler",
      description: "A traveler named Sam has run out of supplies and is too weak to continue. Help them reach the village market.",
      targetDistance: 1100,
      npcToHelp: NPCData(
        name: "Sam",
        spriteType: "traveler",
        dialogueOnRescue: "You saved my life! I was about to give up... Now I'll never forget this kindness.",
        primaryColor: Color(0xFF228B22), // Forest green
        secondaryColor: Color(0xFF32CD32), // Lime green
        description: "A world traveler on a journey to spread hope across lands.",
      ),
      worldEffect: WorldTransform(
        colorSaturation: 0.5,
        hasFlowers: true,
        hasTreeColor: true,
        hasBirdsInSky: true,
        hasVillage: true,
      ),
      difficulty: LevelDifficulty(
        obstacleFrequency: 0.9,
        birdChance: 0.25,
        speed: 280,
        hasWalls: true,
        hasPowerUps: false,
        allowedObstacles: [ObstacleType.crate, ObstacleType.spike, ObstacleType.tallCrate], // Add tall barrels
      ),
      followerBonus: FollowerBonus(
        dashDurationBonus: 0.25, // +25% dash duration - Sam knows shortcuts!
      ),
    ),

    // Level 5: The Scared Artist
    Level(
      number: 5,
      title: "The Scared Artist",
      description: "An artist named Rosa has lost faith in her work. Show her that creativity can inspire and heal the world.",
      targetDistance: 1300,
      npcToHelp: NPCData(
        name: "Rosa",
        spriteType: "artist",
        dialogueOnRescue: "You've reminded me why I create... Art isn't just for galleries - it's for hearts!",
        primaryColor: Color(0xFF9370DB), // Medium purple
        secondaryColor: Color(0xFFDA70D6), // Orchid
        description: "A passionate artist who paints emotions and dreams.",
      ),
      worldEffect: WorldTransform(
        colorSaturation: 0.6,
        hasFlowers: true,
        hasTreeColor: true,
        hasBirdsInSky: true,
        hasVillage: true,
        hasRainbow: true,
      ),
      difficulty: LevelDifficulty(
        obstacleFrequency: 1.0,
        birdChance: 0.3,
        speed: 300,
        hasWalls: true,
        hasPowerUps: true,
        allowedObstacles: [ObstacleType.crate, ObstacleType.spike, ObstacleType.tallCrate, ObstacleType.rollingLog], // Rolling logs!
      ),
      followerBonus: FollowerBonus(
        jumpHeightBonus: 0.15, // +15% jump height - Rosa's creative leaps!
      ),
    ),

    // Level 6: The Silent Musician
    Level(
      number: 6,
      title: "The Silent Musician",
      description: "A musician named Melody hasn't played in years after losing her instrument. Help her rediscover her gift.",
      targetDistance: 1500,
      npcToHelp: NPCData(
        name: "Melody",
        spriteType: "musician",
        dialogueOnRescue: "Music lives in the soul, not the instrument! Thank you for helping me remember.",
        primaryColor: Color(0xFFFFD700), // Gold
        secondaryColor: Color(0xFFFFA500), // Orange
        description: "A talented musician whose melodies once united communities.",
      ),
      worldEffect: WorldTransform(
        colorSaturation: 0.7,
        hasFlowers: true,
        hasTreeColor: true,
        hasBirdsInSky: true,
        hasVillage: true,
        hasRainbow: true,
      ),
      difficulty: LevelDifficulty(
        obstacleFrequency: 1.1,
        birdChance: 0.3,
        speed: 320,
        hasWalls: true,
        hasPowerUps: true,
        allowedObstacles: [ObstacleType.crate, ObstacleType.spike, ObstacleType.tallCrate, ObstacleType.rollingLog, ObstacleType.gap], // Gaps to jump!
      ),
      followerBonus: FollowerBonus(
        scoreMultiplierBonus: 0.15, // +15% score - Melody's harmonious rhythm!
        comboTimerBonus: 0.15, // +15% combo window - music keeps the beat going
      ),
    ),

    // Level 7: The Wilted Gardener
    Level(
      number: 7,
      title: "The Wilted Gardener",
      description: "A gardener named Flora is overwhelmed trying to save her dying garden. Help her restore life to the land.",
      targetDistance: 1800,
      npcToHelp: NPCData(
        name: "Flora",
        spriteType: "gardener",
        dialogueOnRescue: "With many hands, even the hardest soil can bloom! Thank you for not giving up on us.",
        primaryColor: Color(0xFF98FB98), // Pale green
        secondaryColor: Color(0xFF00FA9A), // Medium spring green
        description: "A nurturing soul who believes every seed deserves a chance.",
      ),
      worldEffect: WorldTransform(
        colorSaturation: 0.8,
        hasFlowers: true,
        hasTreeColor: true,
        hasBirdsInSky: true,
        hasVillage: true,
        hasRainbow: true,
      ),
      difficulty: LevelDifficulty(
        obstacleFrequency: 1.2,
        birdChance: 0.35,
        speed: 350,
        hasWalls: true,
        hasPowerUps: true,
        allowedObstacles: [ObstacleType.crate, ObstacleType.spike, ObstacleType.tallCrate, ObstacleType.rollingLog, ObstacleType.gap, ObstacleType.swingingRope], // Swinging ropes!
      ),
      followerBonus: FollowerBonus(
        extraStartingLives: 1, // +1 life - Flora nurtures life!
        coinMagnetRange: 25.0, // Flora tends to all the coins around
      ),
    ),

    // Level 8: The Overwhelmed Teacher
    Level(
      number: 8,
      title: "The Overwhelmed Teacher",
      description: "A teacher named Professor Oak struggles to reach all the children who need guidance. Help her find hope.",
      targetDistance: 2100,
      npcToHelp: NPCData(
        name: "Professor Oak",
        spriteType: "teacher",
        dialogueOnRescue: "Every child is a seed of potential. Thank you for reminding me that I'm not alone.",
        primaryColor: Color(0xFFDEB887), // Burlywood
        secondaryColor: Color(0xFFD2691E), // Chocolate
        description: "A dedicated educator who has taught generations with patience.",
      ),
      worldEffect: WorldTransform(
        colorSaturation: 0.85,
        hasFlowers: true,
        hasTreeColor: true,
        hasBirdsInSky: true,
        hasVillage: true,
        hasRainbow: true,
      ),
      difficulty: LevelDifficulty(
        obstacleFrequency: 1.3,
        birdChance: 0.35,
        speed: 380,
        hasWalls: true,
        hasPowerUps: true,
        allowedObstacles: [ObstacleType.crate, ObstacleType.spike, ObstacleType.tallCrate, ObstacleType.rollingLog, ObstacleType.gap, ObstacleType.swingingRope, ObstacleType.mudPuddle], // Mud puddles!
      ),
      followerBonus: FollowerBonus(
        coinMagnetRange: 35.0, // Professor gathers knowledge (coins) from afar!
        scoreMultiplierBonus: 0.10, // Teaching multiplies wisdom
      ),
    ),

    // Level 9: The Exhausted Healer
    Level(
      number: 9,
      title: "The Exhausted Healer",
      description: "Doctor Grace has been caring for everyone but herself. Help her reach the sanctuary where she can rest.",
      targetDistance: 2500,
      npcToHelp: NPCData(
        name: "Doctor Grace",
        spriteType: "doctor",
        dialogueOnRescue: "Healers need healing too. Thank you for showing me it's okay to accept help.",
        primaryColor: Color(0xFFE0FFFF), // Light cyan
        secondaryColor: Color(0xFF00CED1), // Dark turquoise
        description: "A compassionate healer who has mended countless hearts and bodies.",
      ),
      worldEffect: WorldTransform(
        colorSaturation: 0.95,
        hasFlowers: true,
        hasTreeColor: true,
        hasBirdsInSky: true,
        hasVillage: true,
        hasRainbow: true,
      ),
      difficulty: LevelDifficulty(
        obstacleFrequency: 1.4,
        birdChance: 0.4,
        speed: 420,
        hasWalls: true,
        hasPowerUps: true,
        allowedObstacles: [ObstacleType.crate, ObstacleType.spike, ObstacleType.tallCrate, ObstacleType.rollingLog, ObstacleType.gap, ObstacleType.swingingRope, ObstacleType.mudPuddle, ObstacleType.fireJet], // Fire jets!
      ),
      followerBonus: FollowerBonus(
        extraStartingLives: 1, // +1 life - Doctor Grace preserves life!
        dashDurationBonus: 0.15, // Quick reflexes from medical training
      ),
    ),

    // Level 10: The Grand Celebration
    Level(
      number: 10,
      title: "The Whole Town",
      description: "The Mayor is organizing a grand celebration of kindness, but fears no one will come. Unite the whole town!",
      targetDistance: 3000,
      npcToHelp: NPCData(
        name: "Mayor Heart",
        spriteType: "mayor",
        dialogueOnRescue: "Look at what we've built together! This isn't just a celebration - it's a new beginning!",
        primaryColor: Color(0xFFFF6B6B), // Light red
        secondaryColor: Color(0xFFFFE66D), // Light yellow
        description: "A hopeful leader who believes in the power of community.",
      ),
      worldEffect: WorldTransform(
        colorSaturation: 1.0,
        hasFlowers: true,
        hasTreeColor: true,
        hasBirdsInSky: true,
        hasVillage: true,
        hasRainbow: true,
        hasCelebration: true,
      ),
      difficulty: LevelDifficulty(
        obstacleFrequency: 1.5,
        birdChance: 0.4,
        speed: 450,
        hasWalls: true,
        hasPowerUps: true,
        allowedObstacles: ObstacleType.values, // ALL obstacles - grand finale!
      ),
      followerBonus: FollowerBonus(
        // Mayor inspires everyone - a bit of every bonus!
        coinValueBonus: 0.10,
        scoreMultiplierBonus: 0.10,
        coinMagnetRange: 20.0,
        jumpHeightBonus: 0.10,
        comboTimerBonus: 0.10,
        dashDurationBonus: 0.10,
      ),
    ),
  ];

  /// Get a level by its number (1-indexed)
  static Level? getLevel(int number) {
    if (number < 1 || number > levels.length) return null;
    return levels[number - 1];
  }

  /// Get total number of levels
  static int get totalLevels => levels.length;

  /// Calculate combined bonus from all followers up to a level
  static FollowerBonus getCumulativeBonus(int completedLevels) {
    FollowerBonus total = const FollowerBonus();
    for (int i = 0; i < completedLevels && i < levels.length; i++) {
      total = total + levels[i].followerBonus;
    }
    return total;
  }

  /// Get world saturation based on completed levels
  static double getWorldSaturation(int completedLevels) {
    if (completedLevels <= 0) return 0.0;
    if (completedLevels >= levels.length) return 1.0;
    return levels[completedLevels - 1].worldEffect.colorSaturation;
  }

  /// Get current world transform based on completed levels
  static WorldTransform getCurrentWorldTransform(int completedLevels) {
    if (completedLevels <= 0) {
      return const WorldTransform();
    }
    if (completedLevels >= levels.length) {
      return levels.last.worldEffect;
    }
    return levels[completedLevels - 1].worldEffect;
  }
}
