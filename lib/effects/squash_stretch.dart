import 'package:flame/components.dart';
import '../managers/effects_manager.dart';

enum PlayerAnimState {
  idle,
  running,
  jumping,
  falling,
  landing,
  sliding,
}

class SquashStretchController {
  PlayerAnimState _currentState = PlayerAnimState.idle;
  PlayerAnimState get currentState => _currentState;

  // Current scale values
  double _scaleX = 1.0;
  double _scaleY = 1.0;

  // Target scale values
  double _targetScaleX = 1.0;
  double _targetScaleY = 1.0;

  // Animation speed
  final double _interpolationSpeed = 12.0;

  // Scale values for each state
  static const Map<PlayerAnimState, List<double>> _stateScales = {
    PlayerAnimState.idle: [1.0, 1.0],
    PlayerAnimState.running: [1.0, 1.0], // Handled separately with bob
    PlayerAnimState.jumping: [0.85, 1.2], // Squash then stretch
    PlayerAnimState.falling: [0.9, 1.1], // Slight stretch
    PlayerAnimState.landing: [1.2, 0.75], // Squash on impact
    PlayerAnimState.sliding: [1.3, 0.7], // Wide and flat
  };

  // Track jump phases
  bool _jumpSquashDone = false;
  double _jumpPhaseTimer = 0;
  static const double _jumpSquashDuration = 0.08;

  // Landing recovery timer
  double _landingTimer = 0;
  static const double _landingDuration = 0.15;

  // Running bob effect
  double _runBobTimer = 0;
  static const double _runBobSpeed = 15.0;
  static const double _runBobAmount = 0.05;

  double get scaleX => _scaleX;
  double get scaleY => _scaleY;

  void setState(PlayerAnimState newState) {
    if (!EffectsManager.instance.animationsEnabled) {
      _scaleX = 1.0;
      _scaleY = 1.0;
      _targetScaleX = 1.0;
      _targetScaleY = 1.0;
      return;
    }

    if (newState != _currentState) {
      _currentState = newState;

      // Handle state transitions
      if (newState == PlayerAnimState.jumping) {
        // Start with squash
        _jumpSquashDone = false;
        _jumpPhaseTimer = 0;
        _targetScaleX = 1.15;
        _targetScaleY = 0.85;
      } else if (newState == PlayerAnimState.landing) {
        _landingTimer = 0;
      } else if (newState == PlayerAnimState.running) {
        _runBobTimer = 0;
      }

      // Only set target from map if not special case
      if (newState != PlayerAnimState.jumping) {
        final scales = _stateScales[newState]!;
        _targetScaleX = scales[0];
        _targetScaleY = scales[1];
      }
    }
  }

  void update(double dt) {
    if (!EffectsManager.instance.animationsEnabled) {
      _scaleX = 1.0;
      _scaleY = 1.0;
      return;
    }

    // Handle jump animation phases
    if (_currentState == PlayerAnimState.jumping) {
      _jumpPhaseTimer += dt;
      if (!_jumpSquashDone && _jumpPhaseTimer >= _jumpSquashDuration) {
        // Transition from squash to stretch
        _jumpSquashDone = true;
        final scales = _stateScales[PlayerAnimState.jumping]!;
        _targetScaleX = scales[0];
        _targetScaleY = scales[1];
      }
    }

    // Handle landing recovery
    if (_currentState == PlayerAnimState.landing) {
      _landingTimer += dt;
      if (_landingTimer >= _landingDuration) {
        setState(PlayerAnimState.running);
      }
    }

    // Handle running bob
    if (_currentState == PlayerAnimState.running) {
      _runBobTimer += dt * _runBobSpeed;
      final bob = (1 + (_runBobTimer % 1.0 < 0.5 ? 1 : -1) * _runBobAmount);
      _targetScaleY = bob;
      _targetScaleX = 2.0 - bob; // Inverse for squash/stretch
    }

    // Smooth interpolation toward target
    _scaleX = _lerp(_scaleX, _targetScaleX, dt * _interpolationSpeed);
    _scaleY = _lerp(_scaleY, _targetScaleY, dt * _interpolationSpeed);
  }

  double _lerp(double a, double b, double t) {
    return a + (b - a) * t.clamp(0.0, 1.0);
  }

  void applyToComponent(PositionComponent component) {
    component.scale = Vector2(_scaleX, _scaleY);
  }

  void reset() {
    _currentState = PlayerAnimState.idle;
    _scaleX = 1.0;
    _scaleY = 1.0;
    _targetScaleX = 1.0;
    _targetScaleY = 1.0;
    _jumpSquashDone = false;
    _jumpPhaseTimer = 0;
    _landingTimer = 0;
    _runBobTimer = 0;
  }
}
