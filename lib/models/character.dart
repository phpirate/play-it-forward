import 'package:flutter/material.dart';

/// Defines a playable character with unique appearance and ability
class GameCharacter {
  final String id;
  final String name;
  final String description;
  final int unlockCost;
  final CharacterColors colors;
  final CharacterAbility ability;
  final String abilityDescription;

  const GameCharacter({
    required this.id,
    required this.name,
    required this.description,
    required this.unlockCost,
    required this.colors,
    required this.ability,
    required this.abilityDescription,
  });
}

/// Color scheme for a character
class CharacterColors {
  final Color body;
  final Color bodyLight;
  final Color bodyDark;
  final Color skin;
  final Color scarf;
  final Color scarfDark;

  const CharacterColors({
    required this.body,
    required this.bodyLight,
    required this.bodyDark,
    required this.skin,
    required this.scarf,
    required this.scarfDark,
  });
}

/// Special abilities that modify gameplay
enum CharacterAbility {
  none,           // Default runner - balanced
  doubleDash,     // Ninja - can dash twice before cooldown
  longerGlide,    // Robot - glide lasts 50% longer
  magnetAura,     // Wizard - coins attracted from further away
  lowGravity,     // Astronaut - lower gravity, higher jumps
  fasterFever,    // Phoenix - fever meter fills faster
}

/// All available characters in the game
class Characters {
  static const runner = GameCharacter(
    id: 'runner',
    name: 'Runner',
    description: 'A balanced athlete ready for adventure',
    unlockCost: 0,
    colors: CharacterColors(
      body: Color(0xFF4A90D9),
      bodyLight: Color(0xFF6BB3F5),
      bodyDark: Color(0xFF2E5A8C),
      skin: Color(0xFFFFDBB4),
      scarf: Color(0xFFE74C3C),
      scarfDark: Color(0xFFC0392B),
    ),
    ability: CharacterAbility.none,
    abilityDescription: 'No special ability',
  );

  static const ninja = GameCharacter(
    id: 'ninja',
    name: 'Ninja',
    description: 'Swift shadow warrior',
    unlockCost: 500,
    colors: CharacterColors(
      body: Color(0xFF2C3E50),
      bodyLight: Color(0xFF34495E),
      bodyDark: Color(0xFF1A252F),
      skin: Color(0xFFFFDBB4),
      scarf: Color(0xFF8E44AD),
      scarfDark: Color(0xFF6C3483),
    ),
    ability: CharacterAbility.doubleDash,
    abilityDescription: 'Can dash twice before cooldown',
  );

  static const robot = GameCharacter(
    id: 'robot',
    name: 'Robot',
    description: 'Advanced flying machine',
    unlockCost: 750,
    colors: CharacterColors(
      body: Color(0xFF7F8C8D),
      bodyLight: Color(0xFF95A5A6),
      bodyDark: Color(0xFF616A6B),
      skin: Color(0xFFBDC3C7),
      scarf: Color(0xFF3498DB),
      scarfDark: Color(0xFF2980B9),
    ),
    ability: CharacterAbility.longerGlide,
    abilityDescription: 'Glide lasts 50% longer',
  );

  static const wizard = GameCharacter(
    id: 'wizard',
    name: 'Wizard',
    description: 'Master of magnetic magic',
    unlockCost: 1000,
    colors: CharacterColors(
      body: Color(0xFF9B59B6),
      bodyLight: Color(0xFFBB8FCE),
      bodyDark: Color(0xFF7D3C98),
      skin: Color(0xFFFFDBB4),
      scarf: Color(0xFFF39C12),
      scarfDark: Color(0xFFD68910),
    ),
    ability: CharacterAbility.magnetAura,
    abilityDescription: 'Coins attracted from further away',
  );

  static const astronaut = GameCharacter(
    id: 'astronaut',
    name: 'Astronaut',
    description: 'Space explorer with low gravity suit',
    unlockCost: 1500,
    colors: CharacterColors(
      body: Color(0xFFECF0F1),
      bodyLight: Color(0xFFFFFFFF),
      bodyDark: Color(0xFFBDC3C7),
      skin: Color(0xFFFFDBB4),
      scarf: Color(0xFFE74C3C),
      scarfDark: Color(0xFFC0392B),
    ),
    ability: CharacterAbility.lowGravity,
    abilityDescription: 'Lower gravity, higher jumps',
  );

  static const phoenix = GameCharacter(
    id: 'phoenix',
    name: 'Phoenix',
    description: 'Blazing spirit of rebirth',
    unlockCost: 2000,
    colors: CharacterColors(
      body: Color(0xFFE74C3C),
      bodyLight: Color(0xFFF1948A),
      bodyDark: Color(0xFFC0392B),
      skin: Color(0xFFFFE0B2),
      scarf: Color(0xFFF39C12),
      scarfDark: Color(0xFFD68910),
    ),
    ability: CharacterAbility.fasterFever,
    abilityDescription: 'Fever meter fills 50% faster',
  );

  static List<GameCharacter> get all => [
    runner,
    ninja,
    robot,
    wizard,
    astronaut,
    phoenix,
  ];

  static GameCharacter getById(String id) {
    return all.firstWhere((c) => c.id == id, orElse: () => runner);
  }
}
