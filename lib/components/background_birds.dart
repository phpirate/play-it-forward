import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';

class BackgroundBirds extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final List<_BirdFlock> _flocks = [];
  final Random _random = Random();
  double _spawnTimer = 0;
  final double _spawnInterval = 8.0; // Spawn a new flock every 8 seconds

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Start with one flock
    _spawnFlock();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      _spawnFlock();
    }

    // Remove flocks that are off-screen
    _flocks.removeWhere((flock) {
      if (flock.position.x < -150) {
        flock.removeFromParent();
        return true;
      }
      return false;
    });
  }

  void _spawnFlock() {
    final flock = _BirdFlock(
      position: Vector2(
        gameRef.size.x + 50,
        50 + _random.nextDouble() * 150, // Random height in upper portion
      ),
      birdCount: 3 + _random.nextInt(3), // 3-5 birds
      speed: 80 + _random.nextDouble() * 40, // Varied speed
      gameRef: gameRef,
    );
    _flocks.add(flock);
    add(flock);
  }

  void reset() {
    for (final flock in _flocks) {
      flock.removeFromParent();
    }
    _flocks.clear();
    _spawnTimer = 0;
  }
}

class _BirdFlock extends PositionComponent with HasGameRef<PlayItForwardGame> {
  final int birdCount;
  final double speed;
  @override
  final PlayItForwardGame gameRef;
  final List<_SmallBird> _birds = [];

  _BirdFlock({
    required Vector2 position,
    required this.birdCount,
    required this.speed,
    required this.gameRef,
  }) : super(position: position);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Create V-formation
    for (int i = 0; i < birdCount; i++) {
      final isLeft = i % 2 == 0;
      final row = (i + 1) ~/ 2;

      final bird = _SmallBird(
        position: Vector2(
          row * 15.0, // Offset back
          isLeft ? -row * 10.0 : row * 10.0, // V-formation offset
        ),
        flapOffset: i * 0.3, // Stagger wing flaps
      );
      _birds.add(bird);
      add(bird);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    // Move flock left
    position.x -= speed * dt;
  }
}

class _SmallBird extends PositionComponent {
  final double flapOffset;
  double _flapTimer = 0;
  bool _wingUp = true;

  late RectangleComponent _body;
  late RectangleComponent _wing;

  _SmallBird({
    required Vector2 position,
    required this.flapOffset,
  }) : super(position: position, size: Vector2(12, 6));

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _flapTimer = flapOffset;

    // Small bird body (dark silhouette)
    _body = RectangleComponent(
      size: Vector2(10, 4),
      position: Vector2(1, 1),
      paint: Paint()..color = const Color(0xFF2F2F2F),
    );
    add(_body);

    // Wing
    _wing = RectangleComponent(
      size: Vector2(6, 3),
      position: Vector2(3, -2),
      paint: Paint()..color = const Color(0xFF1F1F1F),
    );
    add(_wing);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Animate wing flapping
    _flapTimer += dt;
    if (_flapTimer >= 0.12) {
      _flapTimer = 0;
      _wingUp = !_wingUp;
      _wing.position.y = _wingUp ? -2 : 2;
    }
  }
}
