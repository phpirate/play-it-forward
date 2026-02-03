import 'package:flutter/foundation.dart';
import 'character_manager.dart';
import 'mission_manager.dart';
import '../models/character.dart';

/// Manages the Fever Mode system
/// Fever meter fills from collecting coins, combos, near-misses, and stomps
/// When full, player becomes invincible with bonus coin multiplier
class FeverManager extends ChangeNotifier {
  static final FeverManager _instance = FeverManager._();
  static FeverManager get instance => _instance;
  FeverManager._();

  double _feverMeter = 0; // 0-100
  bool _isFeverActive = false;
  double _feverDuration = 0;

  static const double maxMeter = 100;
  static const double feverActiveDuration = 10.0; // seconds
  static const double coinBonus = 5.0;
  static const double comboBonus = 10.0;
  static const double nearMissBonus = 8.0;
  static const double stompBonus = 15.0;

  double get feverMeter => _feverMeter;
  double get feverProgress => _feverMeter / maxMeter;
  bool get isFeverActive => _isFeverActive;
  double get feverTimeRemaining => _feverDuration;
  double get feverTimeProgress => _feverDuration / feverActiveDuration;

  /// Add to fever meter from collecting a coin
  void onCoinCollected() {
    if (_isFeverActive) return;
    _addToMeter(coinBonus);
  }

  /// Add to fever meter from combo
  void onCombo(int comboCount) {
    if (_isFeverActive) return;
    _addToMeter(comboBonus * (comboCount / 3).clamp(1, 3));
  }

  /// Add to fever meter from near-miss
  void onNearMiss() {
    if (_isFeverActive) return;
    _addToMeter(nearMissBonus);
  }

  /// Add to fever meter from stomping a bird
  void onStomp() {
    if (_isFeverActive) return;
    _addToMeter(stompBonus);
  }

  void _addToMeter(double amount) {
    // Phoenix ability: fever meter fills 50% faster
    final hasPhoenixAbility = CharacterManager.instance.selectedCharacter.ability == CharacterAbility.fasterFever;
    final modifier = hasPhoenixAbility ? 1.5 : 1.0;

    _feverMeter = (_feverMeter + amount * modifier).clamp(0, maxMeter);
    notifyListeners();

    // Auto-activate when full
    if (_feverMeter >= maxMeter && !_isFeverActive) {
      _activateFever();
    }
  }

  void _activateFever() {
    _isFeverActive = true;
    _feverDuration = feverActiveDuration;
    _feverMeter = 0;

    // Track for missions
    MissionManager.instance.onFeverActivated();

    notifyListeners();
  }

  /// Update fever timer each frame
  void update(double dt) {
    if (_isFeverActive) {
      _feverDuration -= dt;
      if (_feverDuration <= 0) {
        _isFeverActive = false;
        _feverDuration = 0;
      }
      notifyListeners();
    }
  }

  /// Get coin multiplier (3x during fever)
  int get coinMultiplier => _isFeverActive ? 3 : 1;

  void reset() {
    _feverMeter = 0;
    _isFeverActive = false;
    _feverDuration = 0;
    notifyListeners();
  }
}
