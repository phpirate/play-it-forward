import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages tutorial hints - tracks which hints have been shown
class TutorialManager extends ChangeNotifier {
  static final TutorialManager _instance = TutorialManager._();
  static TutorialManager get instance => _instance;
  TutorialManager._();

  static const String _prefsKey = 'tutorial_shown_hints';

  final Set<String> _shownHints = {};
  String? _currentHint;
  double _hintTimer = 0;
  static const double hintDuration = 4.0; // Show hint for 4 seconds

  // Hint IDs
  static const String hintTapToJump = 'tap_to_jump';
  static const String hintDoubleJump = 'double_jump';
  static const String hintSlide = 'slide';
  static const String hintBird = 'bird';
  static const String hintPowerUp = 'power_up';
  static const String hintWall = 'wall';
  static const String hintRideableBird = 'rideable_bird';
  static const String hintThrowStone = 'throw_stone';
  static const String hintDash = 'dash';
  static const String hintGlide = 'glide';
  static const String hintGroundPound = 'ground_pound';
  static const String hintTreasureChest = 'treasure_chest';
  static const String hintFever = 'fever';
  static const String hintSoul = 'soul';
  static const String hintRiskyPath = 'risky_path';

  // Hint messages
  static const Map<String, TutorialHintData> hints = {
    hintTapToJump: TutorialHintData(
      title: 'TAP TO JUMP',
      message: 'Tap anywhere to jump over obstacles',
      icon: '👆',
    ),
    hintDoubleJump: TutorialHintData(
      title: 'DOUBLE JUMP',
      message: 'Tap again mid-air for a second jump!',
      icon: '⬆️',
    ),
    hintSlide: TutorialHintData(
      title: 'SLIDE',
      message: 'Press DOWN to slide under obstacles',
      icon: '⬇️',
    ),
    hintBird: TutorialHintData(
      title: 'WATCH OUT!',
      message: 'Slide under birds or stomp them from above!',
      icon: '🐦',
    ),
    hintPowerUp: TutorialHintData(
      title: 'POWER-UP!',
      message: 'Collect power-ups for special abilities',
      icon: '⚡',
    ),
    hintWall: TutorialHintData(
      title: 'WALL JUMP',
      message: 'Jump off walls to reach higher!',
      icon: '🧱',
    ),
    hintRideableBird: TutorialHintData(
      title: 'GOLDEN BIRD!',
      message: 'Jump on it to ride! Fly over obstacles!',
      icon: '🦅',
    ),
    hintThrowStone: TutorialHintData(
      title: 'THROW STONES',
      message: 'Tap to throw stones at obstacles!',
      icon: '🪨',
    ),
    hintDash: TutorialHintData(
      title: 'DASH',
      message: 'Press E or SHIFT for a speed boost!',
      icon: '💨',
    ),
    hintGlide: TutorialHintData(
      title: 'GLIDE',
      message: 'Hold JUMP while falling to glide',
      icon: '🪂',
    ),
    hintGroundPound: TutorialHintData(
      title: 'GROUND POUND',
      message: 'Press DOWN mid-air to slam down!',
      icon: '💥',
    ),
    hintTreasureChest: TutorialHintData(
      title: 'TREASURE!',
      message: 'Collect chests for coins and power-ups!',
      icon: '📦',
    ),
    hintFever: TutorialHintData(
      title: 'FEVER MODE!',
      message: 'You\'re invincible! Coins worth 3x!',
      icon: '🔥',
    ),
    hintSoul: TutorialHintData(
      title: 'SOUL',
      message: 'Souls give you an extra life!',
      icon: '👻',
    ),
    hintRiskyPath: TutorialHintData(
      title: 'RISKY PATH',
      message: 'Take the high road for more rewards!',
      icon: '⬆️',
    ),
  };

  String? get currentHint => _currentHint;
  TutorialHintData? get currentHintData =>
      _currentHint != null ? hints[_currentHint] : null;
  double get hintProgress => _hintTimer / hintDuration;
  bool get isShowingHint => _currentHint != null;

  /// Load saved tutorial progress
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getStringList(_prefsKey) ?? [];
    _shownHints.clear();
    _shownHints.addAll(shown);
  }

  /// Save tutorial progress
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _shownHints.toList());
  }

  /// Check if a hint has been shown before
  bool hasShown(String hintId) => _shownHints.contains(hintId);

  /// Try to show a hint (only shows if not shown before)
  bool tryShowHint(String hintId) {
    // Don't show if already shown before
    if (_shownHints.contains(hintId)) return false;

    // Don't interrupt current hint
    if (_currentHint != null) return false;

    // Show the hint
    _currentHint = hintId;
    _hintTimer = 0;
    _shownHints.add(hintId);
    _save();
    notifyListeners();
    return true;
  }

  /// Force show a hint (even if shown before)
  void forceShowHint(String hintId) {
    _currentHint = hintId;
    _hintTimer = 0;
    notifyListeners();
  }

  /// Update hint timer
  void update(double dt) {
    if (_currentHint != null) {
      _hintTimer += dt;
      if (_hintTimer >= hintDuration) {
        _currentHint = null;
        _hintTimer = 0;
        notifyListeners();
      }
    }
  }

  /// Dismiss current hint early
  void dismissHint() {
    if (_currentHint != null) {
      _currentHint = null;
      _hintTimer = 0;
      notifyListeners();
    }
  }

  /// Reset all tutorial progress (for testing)
  Future<void> resetAll() async {
    _shownHints.clear();
    _currentHint = null;
    _hintTimer = 0;
    await _save();
    notifyListeners();
  }
}

/// Data for a tutorial hint
class TutorialHintData {
  final String title;
  final String message;
  final String icon;

  const TutorialHintData({
    required this.title,
    required this.message,
    required this.icon,
  });
}
