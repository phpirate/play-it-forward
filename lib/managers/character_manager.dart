import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character.dart';

/// Manages character unlocks, selection, and persistence
class CharacterManager extends ChangeNotifier {
  static final CharacterManager _instance = CharacterManager._();
  static CharacterManager get instance => _instance;
  CharacterManager._();

  static const String _unlockedKey = 'unlocked_characters';
  static const String _selectedKey = 'selected_character';

  final Set<String> _unlockedCharacters = {'runner'}; // Runner is always unlocked
  String _selectedCharacterId = 'runner';
  int _totalCoins = 0;

  GameCharacter get selectedCharacter => Characters.getById(_selectedCharacterId);
  String get selectedCharacterId => _selectedCharacterId;
  int get totalCoins => _totalCoins;

  bool isUnlocked(String characterId) => _unlockedCharacters.contains(characterId);

  List<GameCharacter> get allCharacters => Characters.all;

  List<GameCharacter> get unlockedCharacters =>
      Characters.all.where((c) => isUnlocked(c.id)).toList();

  /// Load saved data from SharedPreferences
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Load unlocked characters
    final unlockedList = prefs.getStringList(_unlockedKey) ?? ['runner'];
    _unlockedCharacters.clear();
    _unlockedCharacters.addAll(unlockedList);

    // Load selected character
    _selectedCharacterId = prefs.getString(_selectedKey) ?? 'runner';

    // Ensure selected character is unlocked
    if (!_unlockedCharacters.contains(_selectedCharacterId)) {
      _selectedCharacterId = 'runner';
    }

    // Load total coins
    _totalCoins = prefs.getInt('total_coins') ?? 0;

    notifyListeners();
  }

  /// Save data to SharedPreferences
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_unlockedKey, _unlockedCharacters.toList());
    await prefs.setString(_selectedKey, _selectedCharacterId);
    await prefs.setInt('total_coins', _totalCoins);
  }

  /// Add coins (called when game ends)
  void addCoins(int coins) {
    _totalCoins += coins;
    _save();
    notifyListeners();
  }

  /// Try to unlock a character
  /// Returns true if successful, false if not enough coins or already unlocked
  bool unlockCharacter(String characterId) {
    if (_unlockedCharacters.contains(characterId)) {
      return false; // Already unlocked
    }

    final character = Characters.getById(characterId);
    if (_totalCoins < character.unlockCost) {
      return false; // Not enough coins
    }

    _totalCoins -= character.unlockCost;
    _unlockedCharacters.add(characterId);
    _save();
    notifyListeners();
    return true;
  }

  /// Select a character (must be unlocked)
  bool selectCharacter(String characterId) {
    if (!_unlockedCharacters.contains(characterId)) {
      return false;
    }

    _selectedCharacterId = characterId;
    _save();
    notifyListeners();
    return true;
  }

  /// Get the ability modifier for the current character
  double getAbilityModifier(CharacterAbility ability) {
    if (selectedCharacter.ability == ability) {
      switch (ability) {
        case CharacterAbility.longerGlide:
          return 1.5; // 50% longer glide
        case CharacterAbility.magnetAura:
          return 1.5; // 50% larger magnet range
        case CharacterAbility.lowGravity:
          return 0.8; // 20% less gravity
        case CharacterAbility.fasterFever:
          return 1.5; // 50% faster fever fill
        default:
          return 1.0;
      }
    }
    return 1.0;
  }

  /// Check if character has double dash ability
  bool get hasDoubleDash => selectedCharacter.ability == CharacterAbility.doubleDash;
}
