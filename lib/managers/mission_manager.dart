import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mission.dart';
import 'character_manager.dart';

/// Tracks mission progress and completion
class MissionManager extends ChangeNotifier {
  static final MissionManager _instance = MissionManager._();
  static MissionManager get instance => _instance;
  MissionManager._();

  static const String _completedKey = 'completed_missions';
  static const String _gamesPlayedKey = 'total_games_played';

  final Set<String> _completedMissions = {};
  int _totalGamesPlayed = 0;

  // Current run stats (reset each game)
  int _runCoins = 0;
  int _runScore = 0;
  int _runMaxCombo = 0;
  int _runBirdsStomped = 0;
  int _runPowerUpsUsed = 0;
  int _runSoulsCollected = 0;
  int _runFeverCount = 0;

  // Getters
  Set<String> get completedMissions => _completedMissions;
  int get totalGamesPlayed => _totalGamesPlayed;
  int get completedCount => _completedMissions.length;
  int get totalMissions => Missions.all.length;

  bool isCompleted(String missionId) => _completedMissions.contains(missionId);

  List<Mission> get activeMissions =>
      Missions.all.where((m) => !_completedMissions.contains(m.id)).toList();

  List<Mission> get completedMissionsList =>
      Missions.all.where((m) => _completedMissions.contains(m.id)).toList();

  /// Load saved data
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final completedList = prefs.getStringList(_completedKey) ?? [];
    _completedMissions.clear();
    _completedMissions.addAll(completedList);

    _totalGamesPlayed = prefs.getInt(_gamesPlayedKey) ?? 0;

    notifyListeners();
  }

  /// Save data
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_completedKey, _completedMissions.toList());
    await prefs.setInt(_gamesPlayedKey, _totalGamesPlayed);
  }

  /// Reset stats for a new run
  void startRun() {
    _runCoins = 0;
    _runScore = 0;
    _runMaxCombo = 0;
    _runBirdsStomped = 0;
    _runPowerUpsUsed = 0;
    _runSoulsCollected = 0;
    _runFeverCount = 0;
  }

  /// Called when a game ends - check and complete missions
  List<Mission> endRun(int finalScore, int finalCoins) {
    _runScore = finalScore;
    _runCoins = finalCoins;
    _totalGamesPlayed++;

    final newlyCompleted = <Mission>[];

    for (final mission in Missions.all) {
      if (_completedMissions.contains(mission.id)) continue;

      if (_checkMissionComplete(mission)) {
        _completedMissions.add(mission.id);
        CharacterManager.instance.addCoins(mission.coinReward);
        newlyCompleted.add(mission);
      }
    }

    _save();
    notifyListeners();

    return newlyCompleted;
  }

  bool _checkMissionComplete(Mission mission) {
    switch (mission.type) {
      case MissionType.collectCoins:
        return _runCoins >= mission.targetValue;
      case MissionType.reachDistance:
        return _runScore >= mission.targetValue;
      case MissionType.achieveCombo:
        return _runMaxCombo >= mission.targetValue;
      case MissionType.stompBirds:
        return _runBirdsStomped >= mission.targetValue;
      case MissionType.usePowerUps:
        return _runPowerUpsUsed >= mission.targetValue;
      case MissionType.collectSouls:
        return _runSoulsCollected >= mission.targetValue;
      case MissionType.playGames:
        return _totalGamesPlayed >= mission.targetValue;
      case MissionType.unlockCharacter:
        return CharacterManager.instance.unlockedCharacters.length > 1;
      case MissionType.reachFever:
        return _runFeverCount >= mission.targetValue;
    }
  }

  /// Get progress for a specific mission (0.0 to 1.0)
  double getMissionProgress(Mission mission) {
    int current = 0;
    switch (mission.type) {
      case MissionType.collectCoins:
        current = _runCoins;
        break;
      case MissionType.reachDistance:
        current = _runScore;
        break;
      case MissionType.achieveCombo:
        current = _runMaxCombo;
        break;
      case MissionType.stompBirds:
        current = _runBirdsStomped;
        break;
      case MissionType.usePowerUps:
        current = _runPowerUpsUsed;
        break;
      case MissionType.collectSouls:
        current = _runSoulsCollected;
        break;
      case MissionType.playGames:
        current = _totalGamesPlayed;
        break;
      case MissionType.unlockCharacter:
        current = CharacterManager.instance.unlockedCharacters.length > 1 ? 1 : 0;
        break;
      case MissionType.reachFever:
        current = _runFeverCount;
        break;
    }

    return (current / mission.targetValue).clamp(0.0, 1.0);
  }

  /// Get current progress value for display
  int getCurrentProgress(Mission mission) {
    switch (mission.type) {
      case MissionType.collectCoins:
        return _runCoins;
      case MissionType.reachDistance:
        return _runScore;
      case MissionType.achieveCombo:
        return _runMaxCombo;
      case MissionType.stompBirds:
        return _runBirdsStomped;
      case MissionType.usePowerUps:
        return _runPowerUpsUsed;
      case MissionType.collectSouls:
        return _runSoulsCollected;
      case MissionType.playGames:
        return _totalGamesPlayed;
      case MissionType.unlockCharacter:
        return CharacterManager.instance.unlockedCharacters.length > 1 ? 1 : 0;
      case MissionType.reachFever:
        return _runFeverCount;
    }
  }

  // Event handlers called during gameplay
  void onCoinCollected() {
    _runCoins++;
  }

  void onComboAchieved(int combo) {
    if (combo > _runMaxCombo) {
      _runMaxCombo = combo;
    }
  }

  void onBirdStomped() {
    _runBirdsStomped++;
  }

  void onPowerUpUsed() {
    _runPowerUpsUsed++;
  }

  void onSoulCollected() {
    _runSoulsCollected++;
  }

  void onFeverActivated() {
    _runFeverCount++;
  }

  /// Reset all progress (for testing)
  Future<void> resetAll() async {
    _completedMissions.clear();
    _totalGamesPlayed = 0;
    await _save();
    notifyListeners();
  }
}
