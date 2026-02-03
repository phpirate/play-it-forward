import 'package:flutter/foundation.dart';

enum PowerUpType { shield, magnet, doubleScore, slowMotion }

class ActivePowerUp {
  final PowerUpType type;
  double remainingTime;
  final double totalDuration;

  ActivePowerUp({
    required this.type,
    required this.remainingTime,
    required this.totalDuration,
  });

  double get progress => remainingTime / totalDuration;
}

class PowerUpManager extends ChangeNotifier {
  static final PowerUpManager instance = PowerUpManager._();
  PowerUpManager._();

  // Duration constants in seconds
  static const double shieldDuration = 8.0;
  static const double magnetDuration = 10.0;
  static const double doubleScoreDuration = 12.0;
  static const double slowMotionDuration = 6.0;

  final Map<PowerUpType, ActivePowerUp> _activePowerUps = {};

  Map<PowerUpType, ActivePowerUp> get activePowerUps =>
      Map.unmodifiable(_activePowerUps);

  void activate(PowerUpType type) {
    final duration = _getDuration(type);
    _activePowerUps[type] = ActivePowerUp(
      type: type,
      remainingTime: duration,
      totalDuration: duration,
    );
    notifyListeners();
  }

  double _getDuration(PowerUpType type) {
    switch (type) {
      case PowerUpType.shield:
        return shieldDuration;
      case PowerUpType.magnet:
        return magnetDuration;
      case PowerUpType.doubleScore:
        return doubleScoreDuration;
      case PowerUpType.slowMotion:
        return slowMotionDuration;
    }
  }

  void update(double dt) {
    final toRemove = <PowerUpType>[];

    for (final entry in _activePowerUps.entries) {
      entry.value.remainingTime -= dt;
      if (entry.value.remainingTime <= 0) {
        toRemove.add(entry.key);
      }
    }

    if (toRemove.isNotEmpty) {
      for (final type in toRemove) {
        _activePowerUps.remove(type);
      }
      notifyListeners();
    }
  }

  bool isActive(PowerUpType type) {
    return _activePowerUps.containsKey(type);
  }

  /// Consumes shield if active. Returns true if shield was consumed.
  bool consumeShield() {
    if (_activePowerUps.containsKey(PowerUpType.shield)) {
      _activePowerUps.remove(PowerUpType.shield);
      notifyListeners();
      return true;
    }
    return false;
  }

  void reset() {
    _activePowerUps.clear();
    notifyListeners();
  }
}
