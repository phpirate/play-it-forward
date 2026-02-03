import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../managers/effects_manager.dart';

class SpeedTrail extends PositionComponent {
  final List<Vector2> _positions = [];
  final int maxPositions = 6;
  final double speedThreshold = 400;
  final double recordInterval = 0.03; // Record position every 30ms

  double _recordTimer = 0;
  double _currentSpeed = 0;

  // Player visual dimensions (matching player body)
  final double bodyWidth = 40;
  final double bodyHeight = 50;
  final Color playerColor = const Color(0xFF4A90D9);

  void updateSpeed(double speed) {
    _currentSpeed = speed;
  }

  void recordPosition(Vector2 pos, double dt) {
    if (!EffectsManager.instance.animationsEnabled) {
      _positions.clear();
      return;
    }

    if (_currentSpeed < speedThreshold) {
      // Below threshold, fade out trail
      if (_positions.isNotEmpty) {
        _recordTimer += dt;
        if (_recordTimer >= recordInterval * 2) {
          _recordTimer = 0;
          _positions.removeLast();
        }
      }
      return;
    }

    _recordTimer += dt;
    if (_recordTimer >= recordInterval) {
      _recordTimer = 0;
      _positions.insert(0, pos.clone());
      if (_positions.length > maxPositions) {
        _positions.removeLast();
      }
    }
  }

  void clear() {
    _positions.clear();
  }

  @override
  void render(Canvas canvas) {
    if (!EffectsManager.instance.animationsEnabled || _positions.isEmpty) {
      return;
    }

    for (int i = 0; i < _positions.length; i++) {
      // Calculate opacity based on position in trail (newest = most opaque)
      final progress = i / _positions.length;
      final opacity = 0.4 * (1 - progress);

      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = playerColor.withValues(alpha: opacity);

      // Draw ghost body at this position
      // Offset to match player anchor (bottomCenter) and body position
      final pos = _positions[i];
      final rect = Rect.fromLTWH(
        pos.x - bodyWidth / 2 + 5, // Account for body offset in player
        pos.y - bodyHeight - 10, // Account for anchor and body position
        bodyWidth,
        bodyHeight,
      );

      canvas.drawRect(rect, paint);
    }
  }
}
