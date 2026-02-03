import 'package:shared_preferences/shared_preferences.dart';

class ScoreManager {
  static final ScoreManager instance = ScoreManager._();
  ScoreManager._();

  int _highScore = 0;
  int _totalCoins = 0;
  double _initialSpeed = 300;

  int get highScore => _highScore;
  int get totalCoins => _totalCoins;
  double get initialSpeed => _initialSpeed;

  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    _highScore = prefs.getInt('highScore') ?? 0;
    _totalCoins = prefs.getInt('totalCoins') ?? 0;
    _initialSpeed = prefs.getDouble('initialSpeed') ?? 300;
  }

  Future<void> setInitialSpeed(double speed) async {
    _initialSpeed = speed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('initialSpeed', speed);
  }

  Future<void> checkAndSaveHighScore(int score) async {
    if (score > _highScore) {
      _highScore = score;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', _highScore);
    }
  }

  Future<void> addCoins(int coins) async {
    _totalCoins += coins;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalCoins', _totalCoins);
  }

  Future<void> resetAll() async {
    _highScore = 0;
    _totalCoins = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('highScore');
    await prefs.remove('totalCoins');
  }
}
