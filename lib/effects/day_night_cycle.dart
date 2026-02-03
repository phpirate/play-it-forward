import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../managers/effects_manager.dart';

enum TimeOfDay { dawn, day, dusk, night }

class DayNightCycle extends Component {
  double _cycleTime = 0;
  final double cycleDuration = 60.0; // Full cycle in seconds

  // Phase durations (as fraction of cycle)
  static const double dawnDuration = 0.15;
  static const double dayDuration = 0.35;
  static const double duskDuration = 0.15;
  static const double nightDuration = 0.35;

  // Color palettes for each phase
  static const Color dawnSkyStart = Color(0xFFFF9966);
  static const Color dawnSkyEnd = Color(0xFF87CEEB);
  static const Color daySky = Color(0xFF87CEEB);
  static const Color duskSkyStart = Color(0xFF87CEEB);
  static const Color duskSkyEnd = Color(0xFF4B0082);
  static const Color nightSky = Color(0xFF191970);

  static const Color dawnHills = Color(0xFF2E5D1E);
  static const Color dayHills = Color(0xFF228B22);
  static const Color duskHills = Color(0xFF1A4314);
  static const Color nightHills = Color(0xFF0D260D);

  static const Color dawnTrees = Color(0xFF3DA032);
  static const Color dayTrees = Color(0xFF32CD32);
  static const Color duskTrees = Color(0xFF228B22);
  static const Color nightTrees = Color(0xFF145214);

  double get cycleProgress => _cycleTime / cycleDuration;

  TimeOfDay get currentPhase {
    final progress = cycleProgress;
    if (progress < dawnDuration) {
      return TimeOfDay.dawn;
    } else if (progress < dawnDuration + dayDuration) {
      return TimeOfDay.day;
    } else if (progress < dawnDuration + dayDuration + duskDuration) {
      return TimeOfDay.dusk;
    } else {
      return TimeOfDay.night;
    }
  }

  bool get isNightTime => currentPhase == TimeOfDay.night;

  double get nightProgress {
    if (!isNightTime) return 0;
    final nightStart = dawnDuration + dayDuration + duskDuration;
    return (cycleProgress - nightStart) / nightDuration;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!EffectsManager.instance.dayNightCycleEnabled) {
      _cycleTime = cycleDuration * dawnDuration; // Stay at day start
      return;
    }

    _cycleTime += dt;
    if (_cycleTime >= cycleDuration) {
      _cycleTime -= cycleDuration;
    }
  }

  Color getCurrentSkyColor() {
    if (!EffectsManager.instance.dayNightCycleEnabled) {
      return daySky;
    }

    final progress = cycleProgress;

    if (progress < dawnDuration) {
      // Dawn: transition from night to day
      final t = progress / dawnDuration;
      return Color.lerp(dawnSkyStart, dawnSkyEnd, t)!;
    } else if (progress < dawnDuration + dayDuration) {
      // Day: solid blue
      return daySky;
    } else if (progress < dawnDuration + dayDuration + duskDuration) {
      // Dusk: transition to night
      final t = (progress - dawnDuration - dayDuration) / duskDuration;
      return Color.lerp(duskSkyStart, duskSkyEnd, t)!;
    } else {
      // Night: dark blue
      return nightSky;
    }
  }

  Color getHillColor() {
    if (!EffectsManager.instance.dayNightCycleEnabled) {
      return dayHills;
    }

    final progress = cycleProgress;

    if (progress < dawnDuration) {
      final t = progress / dawnDuration;
      return Color.lerp(nightHills, dawnHills, t)!;
    } else if (progress < dawnDuration + dayDuration) {
      final t = (progress - dawnDuration) / dayDuration;
      return Color.lerp(dawnHills, dayHills, t.clamp(0, 0.3) / 0.3)!;
    } else if (progress < dawnDuration + dayDuration + duskDuration) {
      final t = (progress - dawnDuration - dayDuration) / duskDuration;
      return Color.lerp(dayHills, duskHills, t)!;
    } else {
      final t = (progress - dawnDuration - dayDuration - duskDuration) / nightDuration;
      return Color.lerp(duskHills, nightHills, t.clamp(0, 0.3) / 0.3)!;
    }
  }

  Color getTreeColor() {
    if (!EffectsManager.instance.dayNightCycleEnabled) {
      return dayTrees;
    }

    final progress = cycleProgress;

    if (progress < dawnDuration) {
      final t = progress / dawnDuration;
      return Color.lerp(nightTrees, dawnTrees, t)!;
    } else if (progress < dawnDuration + dayDuration) {
      final t = (progress - dawnDuration) / dayDuration;
      return Color.lerp(dawnTrees, dayTrees, t.clamp(0, 0.3) / 0.3)!;
    } else if (progress < dawnDuration + dayDuration + duskDuration) {
      final t = (progress - dawnDuration - dayDuration) / duskDuration;
      return Color.lerp(dayTrees, duskTrees, t)!;
    } else {
      final t = (progress - dawnDuration - dayDuration - duskDuration) / nightDuration;
      return Color.lerp(duskTrees, nightTrees, t.clamp(0, 0.3) / 0.3)!;
    }
  }

  void reset() {
    _cycleTime = 0;
  }

  /// Get shadow offset based on sun/moon position
  /// Returns (x offset, shadow length multiplier)
  (double, double) getShadowOffset() {
    final progress = cycleProgress;

    // During day, sun moves from left to right
    // During night, moon also moves
    double sunPosition; // 0 = left (sunrise), 0.5 = top (noon), 1 = right (sunset)

    if (progress < dawnDuration) {
      // Dawn: sun rising from left
      sunPosition = 0.1 + (progress / dawnDuration) * 0.2;
    } else if (progress < dawnDuration + dayDuration) {
      // Day: sun moves across
      final dayProgress = (progress - dawnDuration) / dayDuration;
      sunPosition = 0.3 + dayProgress * 0.4;
    } else if (progress < dawnDuration + dayDuration + duskDuration) {
      // Dusk: sun setting to right
      final duskProgress = (progress - dawnDuration - dayDuration) / duskDuration;
      sunPosition = 0.7 + duskProgress * 0.2;
    } else {
      // Night: moon (less pronounced shadows)
      final nightProgress = (progress - dawnDuration - dayDuration - duskDuration) / nightDuration;
      sunPosition = nightProgress; // Moon goes across
    }

    // Shadow offset: negative when sun is on left, positive when on right
    // At noon (0.5), shadow is directly below (0 offset)
    final xOffset = (sunPosition - 0.5) * 20;

    // Shadow length: longer at dawn/dusk, shorter at noon
    final lengthMultiplier = 1.0 + (0.5 - (sunPosition - 0.5).abs()) * -0.5;

    // At night, shadows are more subtle
    if (isNightTime) {
      return (xOffset * 0.3, lengthMultiplier * 0.5);
    }

    return (xOffset, lengthMultiplier);
  }
}
