import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/level.dart';
import '../data/level_data.dart';

/// Stats for a completed level
class LevelStats {
  final int levelNumber;
  final int coinsCollected;
  final int score;
  final int timeInSeconds;
  final DateTime completedAt;

  LevelStats({
    required this.levelNumber,
    required this.coinsCollected,
    required this.score,
    required this.timeInSeconds,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'levelNumber': levelNumber,
        'coinsCollected': coinsCollected,
        'score': score,
        'timeInSeconds': timeInSeconds,
        'completedAt': completedAt.toIso8601String(),
      };

  factory LevelStats.fromJson(Map<String, dynamic> json) {
    return LevelStats(
      levelNumber: json['levelNumber'] as int,
      coinsCollected: json['coinsCollected'] as int,
      score: json['score'] as int,
      timeInSeconds: json['timeInSeconds'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }
}

/// Manages campaign level progression and state
class LevelManager extends ChangeNotifier {
  static final LevelManager _instance = LevelManager._internal();
  static LevelManager get instance => _instance;

  LevelManager._internal();

  // Persistence keys
  static const String _keyHighestLevel = 'campaign_highest_level';
  static const String _keyLevelStats = 'campaign_level_stats_';
  static const String _keyFollowerUnlocks = 'campaign_followers';

  // State
  int _highestUnlockedLevel = 1;
  Level? _currentLevel;
  bool _isPlayingCampaign = false;
  double _currentDistance = 0;
  int _currentLevelCoins = 0;
  double _currentLevelTime = 0;

  // Level stats (best runs)
  final Map<int, LevelStats> _levelStats = {};

  // Followers unlocked (completed levels)
  final Set<int> _unlockedFollowers = {};

  // Getters
  int get highestUnlockedLevel => _highestUnlockedLevel;
  Level? get currentLevel => _currentLevel;
  bool get isPlayingCampaign => _isPlayingCampaign;
  double get currentDistance => _currentDistance;
  int get currentLevelCoins => _currentLevelCoins;
  double get currentLevelTime => _currentLevelTime;

  /// Progress toward current level goal (0.0 to 1.0)
  double get levelProgress {
    if (_currentLevel == null) return 0.0;
    return (_currentDistance / _currentLevel!.targetDistance).clamp(0.0, 1.0);
  }

  /// Check if player has reached the goal
  bool get hasReachedGoal {
    if (_currentLevel == null) return false;
    return _currentDistance >= _currentLevel!.targetDistance;
  }

  /// Number of completed levels (followers collected)
  int get completedLevels => _unlockedFollowers.length;

  /// Get combined follower bonuses
  FollowerBonus get cumulativeBonus =>
      LevelData.getCumulativeBonus(completedLevels);

  /// Get world saturation level
  double get worldSaturation =>
      LevelData.getWorldSaturation(completedLevels);

  /// Get current world transformation
  WorldTransform get currentWorldTransform =>
      LevelData.getCurrentWorldTransform(completedLevels);

  /// Check if a level is unlocked
  bool isLevelUnlocked(int levelNumber) {
    return levelNumber <= _highestUnlockedLevel;
  }

  /// Check if a level is completed
  bool isLevelCompleted(int levelNumber) {
    return _unlockedFollowers.contains(levelNumber);
  }

  /// Get stats for a level (null if not completed)
  LevelStats? getLevelStats(int levelNumber) {
    return _levelStats[levelNumber];
  }

  /// Get follower data for completed levels before the current level
  /// When replaying Level 1, no followers appear (you're at the beginning)
  /// When playing Level 3, only followers from Levels 1 & 2 appear
  List<NPCData> getUnlockedFollowers() {
    final followers = <NPCData>[];
    for (final levelNum in _unlockedFollowers.toList()..sort()) {
      // Only include followers from levels BEFORE the current level
      // This makes narrative sense: you can only have followers you've
      // already rescued on this journey
      if (_currentLevel != null && levelNum >= _currentLevel!.number) {
        continue;
      }
      final level = LevelData.getLevel(levelNum);
      if (level != null) {
        followers.add(level.npcToHelp);
      }
    }
    return followers;
  }

  /// Load saved progress
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _highestUnlockedLevel = prefs.getInt(_keyHighestLevel) ?? 1;

    // Load followers
    final followersString = prefs.getString(_keyFollowerUnlocks);
    if (followersString != null && followersString.isNotEmpty) {
      _unlockedFollowers.clear();
      for (final numStr in followersString.split(',')) {
        final num = int.tryParse(numStr);
        if (num != null) {
          _unlockedFollowers.add(num);
        }
      }
    }

    // Load level stats
    for (int i = 1; i <= LevelData.totalLevels; i++) {
      final statsJson = prefs.getString('$_keyLevelStats$i');
      if (statsJson != null) {
        try {
          // Simple parsing since we can't use dart:convert in this context
          // Store stats in a simpler format: coins|score|time|date
          final parts = statsJson.split('|');
          if (parts.length >= 4) {
            _levelStats[i] = LevelStats(
              levelNumber: i,
              coinsCollected: int.tryParse(parts[0]) ?? 0,
              score: int.tryParse(parts[1]) ?? 0,
              timeInSeconds: int.tryParse(parts[2]) ?? 0,
              completedAt: DateTime.tryParse(parts[3]) ?? DateTime.now(),
            );
          }
        } catch (e) {
          debugPrint('Error loading level stats for level $i: $e');
        }
      }
    }

    notifyListeners();
  }

  /// Save progress
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_keyHighestLevel, _highestUnlockedLevel);
    await prefs.setString(_keyFollowerUnlocks, _unlockedFollowers.join(','));

    // Save level stats
    for (final entry in _levelStats.entries) {
      final stats = entry.value;
      final statsString = '${stats.coinsCollected}|${stats.score}|${stats.timeInSeconds}|${stats.completedAt.toIso8601String()}';
      await prefs.setString('$_keyLevelStats${entry.key}', statsString);
    }
  }

  /// Start a campaign level
  void startLevel(int levelNumber) {
    final level = LevelData.getLevel(levelNumber);
    if (level == null) {
      debugPrint('Level $levelNumber does not exist');
      return;
    }

    if (!isLevelUnlocked(levelNumber)) {
      debugPrint('Level $levelNumber is not unlocked');
      return;
    }

    _currentLevel = level;
    _isPlayingCampaign = true;
    _currentDistance = 0;
    _currentLevelCoins = 0;
    _currentLevelTime = 0;

    notifyListeners();
  }

  /// Update progress during gameplay
  void updateProgress(double deltaDistance, int deltaCoins, double deltaTime) {
    if (!_isPlayingCampaign || _currentLevel == null) return;

    _currentDistance += deltaDistance;
    _currentLevelCoins += deltaCoins;
    _currentLevelTime += deltaTime;

    // Check if goal reached (will be handled by game)
    notifyListeners();
  }

  /// Set distance directly (called from game update)
  void setDistance(double distance) {
    if (!_isPlayingCampaign || _currentLevel == null) return;
    _currentDistance = distance;
    // Don't notify every frame to avoid performance issues
  }

  /// Add coins collected
  void addCoins(int coins) {
    if (!_isPlayingCampaign) return;
    _currentLevelCoins += coins;
  }

  /// Update time
  void updateTime(double dt) {
    if (!_isPlayingCampaign) return;
    _currentLevelTime += dt;
  }

  /// Complete the current level
  Future<void> completeLevel() async {
    if (_currentLevel == null || !_isPlayingCampaign) return;

    final levelNum = _currentLevel!.number;

    // Mark as completed
    _unlockedFollowers.add(levelNum);

    // Unlock next level
    if (levelNum >= _highestUnlockedLevel && levelNum < LevelData.totalLevels) {
      _highestUnlockedLevel = levelNum + 1;
    }

    // Save best stats
    final newStats = LevelStats(
      levelNumber: levelNum,
      coinsCollected: _currentLevelCoins,
      score: (_currentDistance * 10).toInt() + (_currentLevelCoins * 10),
      timeInSeconds: _currentLevelTime.toInt(),
      completedAt: DateTime.now(),
    );

    final existingStats = _levelStats[levelNum];
    if (existingStats == null || newStats.score > existingStats.score) {
      _levelStats[levelNum] = newStats;
    }

    await _save();
    notifyListeners();
  }

  /// End campaign run (called on game over or returning to menu)
  void endRun() {
    _currentLevel = null;
    _isPlayingCampaign = false;
    _currentDistance = 0;
    _currentLevelCoins = 0;
    _currentLevelTime = 0;

    notifyListeners();
  }

  /// Reset all progress (for testing)
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear all campaign data
    await prefs.remove(_keyHighestLevel);
    await prefs.remove(_keyFollowerUnlocks);
    for (int i = 1; i <= LevelData.totalLevels; i++) {
      await prefs.remove('$_keyLevelStats$i');
    }

    _highestUnlockedLevel = 1;
    _unlockedFollowers.clear();
    _levelStats.clear();
    _currentLevel = null;
    _isPlayingCampaign = false;
    _currentDistance = 0;
    _currentLevelCoins = 0;
    _currentLevelTime = 0;

    notifyListeners();
  }

  /// Get the difficulty settings for the current level
  LevelDifficulty? get currentDifficulty => _currentLevel?.difficulty;

  /// Get the target distance for the current level
  double get targetDistance => _currentLevel?.targetDistance ?? 0;
}
