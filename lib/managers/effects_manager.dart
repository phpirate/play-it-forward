import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class EffectsManager {
  static final EffectsManager instance = EffectsManager._();
  EffectsManager._();

  bool _particlesEnabled = true;
  bool _screenShakeEnabled = true;
  bool _animationsEnabled = true;
  bool _dayNightCycleEnabled = true;
  bool _reducedEffects = false; // For low-end devices

  bool get particlesEnabled => _particlesEnabled;
  bool get screenShakeEnabled => _screenShakeEnabled;
  bool get animationsEnabled => _animationsEnabled;
  bool get dayNightCycleEnabled => _dayNightCycleEnabled;
  bool get reducedEffects => _reducedEffects || kIsWeb; // Auto-reduce on web

  /// Get particle count multiplier (0.3 for web/reduced, 1.0 for full)
  double get particleMultiplier => reducedEffects ? 0.3 : 1.0;

  /// Get max particles multiplier for weather/ambient systems
  double get maxParticleMultiplier => reducedEffects ? 0.4 : 1.0;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _particlesEnabled = prefs.getBool('particlesEnabled') ?? true;
    _screenShakeEnabled = prefs.getBool('screenShakeEnabled') ?? true;
    _animationsEnabled = prefs.getBool('animationsEnabled') ?? true;
    _dayNightCycleEnabled = prefs.getBool('dayNightCycleEnabled') ?? true;
  }

  Future<void> setParticlesEnabled(bool enabled) async {
    _particlesEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('particlesEnabled', enabled);
  }

  Future<void> setScreenShakeEnabled(bool enabled) async {
    _screenShakeEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('screenShakeEnabled', enabled);
  }

  Future<void> setAnimationsEnabled(bool enabled) async {
    _animationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('animationsEnabled', enabled);
  }

  Future<void> setDayNightCycleEnabled(bool enabled) async {
    _dayNightCycleEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dayNightCycleEnabled', enabled);
  }

  Future<void> setReducedEffects(bool enabled) async {
    _reducedEffects = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reducedEffects', enabled);
  }
}
