import 'dart:math';
import 'package:flame/components.dart';
import '../managers/effects_manager.dart';

class ScreenShake extends Component {
  double _intensity = 0;
  double _duration = 0;
  double _elapsed = 0;
  final Random _random = Random();

  Vector2 _currentOffset = Vector2.zero();

  /// Triggers a screen shake effect
  /// [intensity] - Maximum pixel offset (typically 5-20)
  /// [duration] - Duration in seconds (typically 0.1-0.5)
  void shake(double intensity, double duration) {
    if (!EffectsManager.instance.screenShakeEnabled) return;

    // Only override if new shake is stronger
    if (intensity > _intensity || _elapsed >= _duration) {
      _intensity = intensity;
      _duration = duration;
      _elapsed = 0;
    }
  }

  /// Returns the current shake offset to apply to the camera
  Vector2 getOffset() => _currentOffset;

  @override
  void update(double dt) {
    super.update(dt);

    if (_elapsed < _duration && _intensity > 0) {
      _elapsed += dt;

      // Calculate decay (shake gets weaker over time)
      final progress = _elapsed / _duration;
      final decay = 1.0 - progress;
      final currentIntensity = _intensity * decay;

      // Random offset within current intensity
      _currentOffset = Vector2(
        (_random.nextDouble() * 2 - 1) * currentIntensity,
        (_random.nextDouble() * 2 - 1) * currentIntensity,
      );
    } else {
      // Shake finished
      _currentOffset = Vector2.zero();
      _intensity = 0;
    }
  }

  /// Reset the shake effect
  void reset() {
    _intensity = 0;
    _duration = 0;
    _elapsed = 0;
    _currentOffset = Vector2.zero();
  }
}
