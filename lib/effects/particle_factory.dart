import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../managers/effects_manager.dart';

class ParticleFactory {
  static final Random _random = Random();

  /// Get scaled particle count based on performance settings
  static int _getCount(int baseCount) {
    return (baseCount * EffectsManager.instance.particleMultiplier).round().clamp(1, baseCount);
  }

  /// Creates dust trail particles while running
  /// Brown/tan colored particles that spread downward
  static ParticleSystemComponent? createDustTrail(Vector2 position) {
    if (!EffectsManager.instance.particlesEnabled) return null;

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: _getCount(3), // Reduced from 5
        lifespan: 0.4,
        generator: (i) => AcceleratedParticle(
          acceleration: Vector2(0, 100),
          speed: Vector2(
            _random.nextDouble() * 40 - 20,
            _random.nextDouble() * -30,
          ),
          position: position.clone(),
          child: CircleParticle(
            radius: 2 + _random.nextDouble() * 2,
            paint: Paint()
              ..color = Color.lerp(
                const Color(0xFF8B7355),
                const Color(0xFFD2B48C),
                _random.nextDouble(),
              )!.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  /// Creates gold sparkle particles when collecting a coin
  /// 12 particles in a burst pattern
  static ParticleSystemComponent? createCoinSparkle(Vector2 position) {
    if (!EffectsManager.instance.particlesEnabled) return null;

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: _getCount(8), // Reduced from 12
        lifespan: 0.5,
        generator: (i) {
          final angle = (i / 12) * 2 * pi;
          final speed = 80 + _random.nextDouble() * 40;
          return AcceleratedParticle(
            acceleration: Vector2(0, 200),
            speed: Vector2(cos(angle) * speed, sin(angle) * speed),
            position: position.clone(),
            child: CircleParticle(
              radius: 3 + _random.nextDouble() * 2,
              paint: Paint()
                ..color = Color.lerp(
                  const Color(0xFFFFD700),
                  const Color(0xFFFFEC8B),
                  _random.nextDouble(),
                )!,
            ),
          );
        },
      ),
    );
  }

  /// Creates colored burst particles for power-up collection
  /// 16 particles in a starburst pattern
  static ParticleSystemComponent? createPowerUpBurst(Vector2 position, Color color) {
    if (!EffectsManager.instance.particlesEnabled) return null;

    final lighterColor = Color.lerp(color, Colors.white, 0.4)!;

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: _getCount(10), // Reduced from 16
        lifespan: 0.6,
        generator: (i) {
          final angle = (i / 16) * 2 * pi;
          final speed = 100 + _random.nextDouble() * 60;
          return AcceleratedParticle(
            acceleration: Vector2(0, 150),
            speed: Vector2(cos(angle) * speed, sin(angle) * speed),
            position: position.clone(),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = 1.0 - particle.progress;
                final size = 4 + (1 - particle.progress) * 3;
                final paint = Paint()
                  ..color = Color.lerp(color, lighterColor, _random.nextDouble())!
                      .withOpacity(opacity);
                canvas.drawRect(
                  Rect.fromCenter(center: Offset.zero, width: size, height: size),
                  paint,
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Creates blue shard particles when shield breaks
  /// 20 particles spreading outward
  static ParticleSystemComponent? createShieldBreak(Vector2 position) {
    if (!EffectsManager.instance.particlesEnabled) return null;

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: _getCount(12), // Reduced from 20
        lifespan: 0.7,
        generator: (i) {
          final angle = _random.nextDouble() * 2 * pi;
          final speed = 120 + _random.nextDouble() * 80;
          return AcceleratedParticle(
            acceleration: Vector2(0, 300),
            speed: Vector2(cos(angle) * speed, sin(angle) * speed),
            position: position.clone(),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = 1.0 - particle.progress;
                final size = 5 + _random.nextDouble() * 4;
                final paint = Paint()
                  ..color = Color.lerp(
                    const Color(0xFF4169E1),
                    const Color(0xFF87CEEB),
                    _random.nextDouble(),
                  )!.withOpacity(opacity);
                // Draw shard-like shape
                canvas.drawRect(
                  Rect.fromCenter(
                    center: Offset.zero,
                    width: size * 0.6,
                    height: size,
                  ),
                  paint,
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Creates white spark particles for near-miss effect
  /// 8 particles in quick burst
  static ParticleSystemComponent? createNearMissEffect(Vector2 position) {
    if (!EffectsManager.instance.particlesEnabled) return null;

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: _getCount(6), // Reduced from 8
        lifespan: 0.3,
        generator: (i) {
          final angle = (i / 8) * 2 * pi;
          final speed = 60 + _random.nextDouble() * 30;
          return AcceleratedParticle(
            acceleration: Vector2(0, 100),
            speed: Vector2(cos(angle) * speed, sin(angle) * speed),
            position: position.clone(),
            child: CircleParticle(
              radius: 2 + _random.nextDouble() * 2,
              paint: Paint()
                ..color = Colors.white.withOpacity(0.8),
            ),
          );
        },
      ),
    );
  }

  /// Creates speed trail particles for dashing
  /// White/cyan streaks behind player
  static ParticleSystemComponent? createDashTrail(Vector2 position) {
    if (!EffectsManager.instance.particlesEnabled) return null;

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: _getCount(5), // Reduced from 8
        lifespan: 0.25,
        generator: (i) {
          return AcceleratedParticle(
            acceleration: Vector2(-200, 0),
            speed: Vector2(
              -100 - _random.nextDouble() * 50,
              _random.nextDouble() * 40 - 20,
            ),
            position: position.clone() + Vector2(0, _random.nextDouble() * 40 - 20),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = 1.0 - particle.progress;
                final width = 15 * (1.0 - particle.progress * 0.5);
                final height = 3.0;

                final gradient = LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: opacity),
                    const Color(0xFF00BFFF).withValues(alpha: opacity * 0.5),
                    Colors.transparent,
                  ],
                );
                final rect = Rect.fromCenter(
                  center: Offset.zero,
                  width: width,
                  height: height,
                );
                canvas.drawRect(
                  rect,
                  Paint()..shader = gradient.createShader(rect),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Creates ground pound impact ring
  /// Large expanding ring on ground
  static ParticleSystemComponent? createGroundPoundImpact(Vector2 position) {
    if (!EffectsManager.instance.particlesEnabled) return null;

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: _getCount(12), // Reduced from 24
        lifespan: 0.4,
        generator: (i) {
          final angle = (i / 24) * 2 * pi;
          final speed = 200 + _random.nextDouble() * 100;
          return AcceleratedParticle(
            acceleration: Vector2(0, 50),
            speed: Vector2(cos(angle) * speed, sin(angle) * speed * 0.3 - 50),
            position: position.clone(),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = 1.0 - particle.progress;
                final size = 4 + (1 - particle.progress) * 4;
                final color = Color.lerp(
                  const Color(0xFFFFD700),
                  const Color(0xFFFF6B35),
                  particle.progress,
                )!.withValues(alpha: opacity);
                canvas.drawCircle(Offset.zero, size, Paint()..color = color);
              },
            ),
          );
        },
      ),
    );
  }

  /// Creates a ring effect for double jump
  /// Circle that expands outward
  static ParticleSystemComponent? createDoubleJumpRing(Vector2 position) {
    if (!EffectsManager.instance.particlesEnabled) return null;

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: _getCount(10), // Reduced from 16
        lifespan: 0.35,
        generator: (i) {
          final angle = (i / 16) * 2 * pi;
          final speed = 80;
          return AcceleratedParticle(
            acceleration: Vector2.zero(),
            speed: Vector2(cos(angle) * speed, sin(angle) * speed),
            position: position.clone(),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = 1.0 - particle.progress;
                final paint = Paint()
                  ..color = const Color(0xFF4A90D9).withValues(alpha: opacity);
                canvas.drawCircle(Offset.zero, 3, paint);
              },
            ),
          );
        },
      ),
    );
  }

  /// Creates feather burst when bird is stomped
  /// Brown feathers flying in all directions
  static ParticleSystemComponent? createFeatherBurst(Vector2 position) {
    if (!EffectsManager.instance.particlesEnabled) return null;

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: _getCount(8), // Reduced from 15
        lifespan: 0.8,
        generator: (i) {
          final angle = _random.nextDouble() * 2 * pi;
          final speed = 80 + _random.nextDouble() * 60;
          final rotationSpeed = _random.nextDouble() * 5 - 2.5;

          return AcceleratedParticle(
            acceleration: Vector2(0, 250), // Gravity
            speed: Vector2(
              cos(angle) * speed,
              sin(angle) * speed - 50, // Upward bias
            ),
            position: position.clone(),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = 1.0 - particle.progress * 0.7;
                final rotation = particle.progress * rotationSpeed * pi;

                // Feather colors (brown tones)
                final color = Color.lerp(
                  const Color(0xFF8B4513), // Brown
                  const Color(0xFFA0522D), // Sienna
                  _random.nextDouble(),
                )!.withValues(alpha: opacity);

                canvas.save();
                canvas.rotate(rotation);

                // Draw feather shape (elongated oval)
                final paint = Paint()..color = color;
                canvas.drawOval(
                  Rect.fromCenter(
                    center: Offset.zero,
                    width: 3,
                    height: 8 + _random.nextDouble() * 4,
                  ),
                  paint,
                );

                // Feather shaft
                canvas.drawLine(
                  const Offset(0, -5),
                  const Offset(0, 5),
                  Paint()
                    ..color = const Color(0xFF5D4037).withValues(alpha: opacity)
                    ..strokeWidth = 0.5,
                );

                canvas.restore();
              },
            ),
          );
        },
      ),
    );
  }

  /// Creates coin pop effect when stomping birds
  /// Coins flying upward from stomp location
  static ParticleSystemComponent? createCoinPop(Vector2 position, int count) {
    if (!EffectsManager.instance.particlesEnabled) return null;

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 0.6,
        generator: (i) {
          final spreadX = _random.nextDouble() * 60 - 30;
          final speedY = -150 - _random.nextDouble() * 100;

          return AcceleratedParticle(
            acceleration: Vector2(0, 400), // Gravity
            speed: Vector2(spreadX, speedY),
            position: position.clone(),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = 1.0 - particle.progress * 0.5;
                final scale = 1.0 - particle.progress * 0.3;

                // Gold coin
                final gradient = RadialGradient(
                  colors: [
                    const Color(0xFFFFE082).withValues(alpha: opacity),
                    const Color(0xFFFFD700).withValues(alpha: opacity),
                  ],
                );
                final rect = Rect.fromCircle(center: Offset.zero, radius: 6 * scale);
                canvas.drawCircle(
                  Offset.zero,
                  6 * scale,
                  Paint()..shader = gradient.createShader(rect),
                );

                // Shine
                canvas.drawCircle(
                  Offset(-2 * scale, -2 * scale),
                  2 * scale,
                  Paint()..color = Colors.white.withValues(alpha: opacity * 0.6),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
