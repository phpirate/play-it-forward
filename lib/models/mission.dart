import 'package:flutter/material.dart';

/// Types of missions available
enum MissionType {
  collectCoins,      // Collect X coins in one run
  reachDistance,     // Reach X distance (score)
  achieveCombo,      // Achieve X combo
  stompBirds,        // Stomp X birds in one run
  usePowerUps,       // Use X power-ups in one run
  collectSouls,      // Collect X souls in one run
  playGames,         // Play X games total
  unlockCharacter,   // Unlock any character
  reachFever,        // Activate fever mode X times
}

/// Difficulty tiers for missions
enum MissionTier {
  bronze,   // Easy missions
  silver,   // Medium missions
  gold,     // Hard missions
}

/// A single mission with requirements and rewards
class Mission {
  final String id;
  final String title;
  final String description;
  final MissionType type;
  final MissionTier tier;
  final int targetValue;
  final int coinReward;
  final IconData icon;

  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.tier,
    required this.targetValue,
    required this.coinReward,
    required this.icon,
  });

  Color get tierColor {
    switch (tier) {
      case MissionTier.bronze:
        return const Color(0xFFCD7F32);
      case MissionTier.silver:
        return const Color(0xFFC0C0C0);
      case MissionTier.gold:
        return const Color(0xFFFFD700);
    }
  }

  String get tierName {
    switch (tier) {
      case MissionTier.bronze:
        return 'Bronze';
      case MissionTier.silver:
        return 'Silver';
      case MissionTier.gold:
        return 'Gold';
    }
  }
}

/// All available missions in the game
class Missions {
  static const List<Mission> all = [
    // Bronze tier - Easy
    Mission(
      id: 'collect_50_coins',
      title: 'Coin Collector',
      description: 'Collect 50 coins in one run',
      type: MissionType.collectCoins,
      tier: MissionTier.bronze,
      targetValue: 50,
      coinReward: 25,
      icon: Icons.monetization_on,
    ),
    Mission(
      id: 'reach_500_distance',
      title: 'First Steps',
      description: 'Reach a score of 500',
      type: MissionType.reachDistance,
      tier: MissionTier.bronze,
      targetValue: 500,
      coinReward: 25,
      icon: Icons.directions_run,
    ),
    Mission(
      id: 'combo_3',
      title: 'Combo Starter',
      description: 'Achieve a 3x combo',
      type: MissionType.achieveCombo,
      tier: MissionTier.bronze,
      targetValue: 3,
      coinReward: 20,
      icon: Icons.flash_on,
    ),
    Mission(
      id: 'stomp_3_birds',
      title: 'Bird Stomper',
      description: 'Stomp 3 birds in one run',
      type: MissionType.stompBirds,
      tier: MissionTier.bronze,
      targetValue: 3,
      coinReward: 30,
      icon: Icons.catching_pokemon,
    ),
    Mission(
      id: 'play_5_games',
      title: 'Getting Started',
      description: 'Play 5 games',
      type: MissionType.playGames,
      tier: MissionTier.bronze,
      targetValue: 5,
      coinReward: 50,
      icon: Icons.gamepad,
    ),

    // Silver tier - Medium
    Mission(
      id: 'collect_150_coins',
      title: 'Coin Hoarder',
      description: 'Collect 150 coins in one run',
      type: MissionType.collectCoins,
      tier: MissionTier.silver,
      targetValue: 150,
      coinReward: 75,
      icon: Icons.monetization_on,
    ),
    Mission(
      id: 'reach_2000_distance',
      title: 'Marathon Runner',
      description: 'Reach a score of 2000',
      type: MissionType.reachDistance,
      tier: MissionTier.silver,
      targetValue: 2000,
      coinReward: 100,
      icon: Icons.directions_run,
    ),
    Mission(
      id: 'combo_5',
      title: 'Combo Master',
      description: 'Achieve a 5x combo',
      type: MissionType.achieveCombo,
      tier: MissionTier.silver,
      targetValue: 5,
      coinReward: 60,
      icon: Icons.flash_on,
    ),
    Mission(
      id: 'stomp_10_birds',
      title: 'Bird Hunter',
      description: 'Stomp 10 birds in one run',
      type: MissionType.stompBirds,
      tier: MissionTier.silver,
      targetValue: 10,
      coinReward: 100,
      icon: Icons.catching_pokemon,
    ),
    Mission(
      id: 'use_5_powerups',
      title: 'Power Player',
      description: 'Use 5 power-ups in one run',
      type: MissionType.usePowerUps,
      tier: MissionTier.silver,
      targetValue: 5,
      coinReward: 75,
      icon: Icons.bolt,
    ),
    Mission(
      id: 'reach_fever_2',
      title: 'Fever Time',
      description: 'Activate fever mode 2 times in one run',
      type: MissionType.reachFever,
      tier: MissionTier.silver,
      targetValue: 2,
      coinReward: 80,
      icon: Icons.local_fire_department,
    ),
    Mission(
      id: 'play_25_games',
      title: 'Dedicated Player',
      description: 'Play 25 games',
      type: MissionType.playGames,
      tier: MissionTier.silver,
      targetValue: 25,
      coinReward: 150,
      icon: Icons.gamepad,
    ),

    // Gold tier - Hard
    Mission(
      id: 'collect_300_coins',
      title: 'Treasure Hunter',
      description: 'Collect 300 coins in one run',
      type: MissionType.collectCoins,
      tier: MissionTier.gold,
      targetValue: 300,
      coinReward: 200,
      icon: Icons.monetization_on,
    ),
    Mission(
      id: 'reach_5000_distance',
      title: 'Unstoppable',
      description: 'Reach a score of 5000',
      type: MissionType.reachDistance,
      tier: MissionTier.gold,
      targetValue: 5000,
      coinReward: 250,
      icon: Icons.directions_run,
    ),
    Mission(
      id: 'combo_10',
      title: 'Combo Legend',
      description: 'Achieve a 10x combo',
      type: MissionType.achieveCombo,
      tier: MissionTier.gold,
      targetValue: 10,
      coinReward: 150,
      icon: Icons.flash_on,
    ),
    Mission(
      id: 'stomp_20_birds',
      title: 'Sky Dominator',
      description: 'Stomp 20 birds in one run',
      type: MissionType.stompBirds,
      tier: MissionTier.gold,
      targetValue: 20,
      coinReward: 200,
      icon: Icons.catching_pokemon,
    ),
    Mission(
      id: 'collect_3_souls',
      title: 'Soul Keeper',
      description: 'Collect 3 souls in one run',
      type: MissionType.collectSouls,
      tier: MissionTier.gold,
      targetValue: 3,
      coinReward: 200,
      icon: Icons.favorite,
    ),
    Mission(
      id: 'reach_fever_5',
      title: 'Fever Master',
      description: 'Activate fever mode 5 times in one run',
      type: MissionType.reachFever,
      tier: MissionTier.gold,
      targetValue: 5,
      coinReward: 250,
      icon: Icons.local_fire_department,
    ),
    Mission(
      id: 'unlock_character',
      title: 'New Friend',
      description: 'Unlock any character',
      type: MissionType.unlockCharacter,
      tier: MissionTier.gold,
      targetValue: 1,
      coinReward: 100,
      icon: Icons.person_add,
    ),
    Mission(
      id: 'play_100_games',
      title: 'Veteran',
      description: 'Play 100 games',
      type: MissionType.playGames,
      tier: MissionTier.gold,
      targetValue: 100,
      coinReward: 500,
      icon: Icons.gamepad,
    ),
  ];

  static Mission? getById(String id) {
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}
