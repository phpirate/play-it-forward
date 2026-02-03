import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/world_theme.dart';

/// Manages world unlocks, selection, and current world state
class WorldManager extends ChangeNotifier {
  static final WorldManager _instance = WorldManager._();
  static WorldManager get instance => _instance;
  WorldManager._();

  static const String _unlockedKey = 'unlocked_worlds';
  static const String _selectedKey = 'selected_world';
  static const String _highDistanceKey = 'high_distance';

  final Set<String> _unlockedWorlds = {'forest'}; // Forest is always unlocked
  String _selectedWorldId = 'forest';
  int _highestDistance = 0;

  WorldTheme get currentWorld => WorldThemes.getById(_selectedWorldId);
  String get selectedWorldId => _selectedWorldId;
  int get highestDistance => _highestDistance;

  bool isUnlocked(String worldId) => _unlockedWorlds.contains(worldId);

  List<WorldTheme> get allWorlds => WorldThemes.all;

  List<WorldTheme> get unlockedWorlds =>
      WorldThemes.all.where((w) => isUnlocked(w.id)).toList();

  /// Load saved data
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Load unlocked worlds
    final unlockedList = prefs.getStringList(_unlockedKey) ?? ['forest'];
    _unlockedWorlds.clear();
    _unlockedWorlds.addAll(unlockedList);

    // Load selected world
    _selectedWorldId = prefs.getString(_selectedKey) ?? 'forest';

    // Ensure selected world is unlocked
    if (!_unlockedWorlds.contains(_selectedWorldId)) {
      _selectedWorldId = 'forest';
    }

    // Load highest distance
    _highestDistance = prefs.getInt(_highDistanceKey) ?? 0;

    // Check for newly unlocked worlds
    _checkUnlocks();

    notifyListeners();
  }

  /// Save data
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_unlockedKey, _unlockedWorlds.toList());
    await prefs.setString(_selectedKey, _selectedWorldId);
    await prefs.setInt(_highDistanceKey, _highestDistance);
  }

  /// Update highest distance and check for unlocks
  void updateDistance(int distance) {
    if (distance > _highestDistance) {
      _highestDistance = distance;
      _checkUnlocks();
      _save();
      notifyListeners();
    }
  }

  /// Check and unlock worlds based on distance
  void _checkUnlocks() {
    bool newUnlock = false;
    for (final world in WorldThemes.all) {
      if (!_unlockedWorlds.contains(world.id) &&
          _highestDistance >= world.unlockDistance) {
        _unlockedWorlds.add(world.id);
        newUnlock = true;
      }
    }
    if (newUnlock) {
      _save();
    }
  }

  /// Select a world (must be unlocked)
  bool selectWorld(String worldId) {
    if (!_unlockedWorlds.contains(worldId)) {
      return false;
    }

    _selectedWorldId = worldId;
    _save();
    notifyListeners();
    return true;
  }

  /// Get distance required to unlock a world
  int getUnlockDistance(String worldId) {
    return WorldThemes.getById(worldId).unlockDistance;
  }

  /// Get progress towards unlocking a world (0.0 to 1.0)
  double getUnlockProgress(String worldId) {
    final required = getUnlockDistance(worldId);
    if (required == 0) return 1.0;
    return (_highestDistance / required).clamp(0.0, 1.0);
  }
}
