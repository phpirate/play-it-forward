import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/player.dart';
import '../components/ground.dart';
import '../components/obstacle_manager.dart';
import '../components/parallax_background.dart';
import 'dart:math';
import '../managers/score_manager.dart';
import '../managers/audio_manager.dart';
import '../managers/power_up_manager.dart';
import '../managers/fever_manager.dart';
import '../managers/character_manager.dart';
import '../managers/world_manager.dart';
import '../managers/mission_manager.dart';
import '../managers/tutorial_manager.dart';
import '../effects/screen_shake.dart';
import '../effects/day_night_cycle.dart';
import '../effects/speed_trail.dart';
import '../effects/particle_factory.dart';
import '../effects/weather_system.dart';
import '../effects/speed_lines.dart';
import '../effects/ambient_particles.dart';
import '../effects/shooting_stars.dart';
import '../effects/score_popup.dart';
import '../effects/impact_effects.dart';
import '../components/background_birds.dart';

enum GameState { menu, playing, paused, gameOver }

class PlayItForwardGame extends FlameGame with TapCallbacks, KeyboardEvents, HasCollisionDetection {
  late Player player;
  late Ground ground;
  late ObstacleManager obstacleManager;
  late ParallaxBackground background;
  late PowerUpManager powerUpManager;
  late ScreenShake screenShake;
  DayNightCycle? _dayNightCycle;
  DayNightCycle get dayNightCycle => _dayNightCycle!;
  late SpeedTrail speedTrail;
  late BackgroundBirds backgroundBirds;

  // New visual effects
  late WeatherSystem weatherSystem;
  late SpeedLines speedLines;
  late AmbientParticles ambientParticles;
  late ShootingStars shootingStars;

  // Fever mode
  late FeverManager feverManager;

  GameState gameState = GameState.menu;

  late double gameSpeed;

  /// Returns game speed accounting for slow motion power-up
  double get effectiveGameSpeed =>
      powerUpManager.isActive(PowerUpType.slowMotion)
          ? gameSpeed * 0.5
          : gameSpeed;
  double get initialGameSpeed => ScoreManager.instance.initialSpeed;
  final double maxGameSpeed = 800;
  final double speedIncrement = 10;
  final double speedIncrementInterval = 5; // seconds

  double _timeSinceLastSpeedIncrease = 0;
  double _gameTime = 0;
  double _cleanupTimer = 0;
  static const double _cleanupInterval = 1.0; // Cleanup every second

  int score = 0;
  int coins = 0;
  int souls = 0;

  // Invincibility after using a soul
  bool _isInvincible = false;
  double _invincibilityTimer = 0;
  static const double invincibilityDuration = 2.0;

  // Combo system
  int comboCount = 0;
  double comboTimer = 0;
  static const double comboWindow = 1.5; // Seconds to maintain combo

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize character, world, mission, and tutorial managers
    await CharacterManager.instance.load();
    await WorldManager.instance.load();
    await MissionManager.instance.load();
    await TutorialManager.instance.load();

    // Initialize day/night cycle (must be before background)
    _dayNightCycle = DayNightCycle();
    add(_dayNightCycle!);

    // Add parallax background
    background = ParallaxBackground();
    add(background);

    // Add background birds
    backgroundBirds = BackgroundBirds();
    add(backgroundBirds);

    // Add speed trail (rendered behind player)
    speedTrail = SpeedTrail();
    add(speedTrail);

    // Add ground
    ground = Ground();
    add(ground);

    // Add player
    player = Player();
    add(player);

    // Add obstacle manager
    obstacleManager = ObstacleManager();
    add(obstacleManager);

    // Initialize power-up manager
    powerUpManager = PowerUpManager.instance;

    // Initialize screen shake
    screenShake = ScreenShake();
    add(screenShake);

    // Add weather system
    weatherSystem = WeatherSystem();
    add(weatherSystem);

    // Add speed lines
    speedLines = SpeedLines();
    add(speedLines);

    // Add ambient particles (dust, fireflies, butterflies)
    ambientParticles = AmbientParticles();
    add(ambientParticles);

    // Add shooting stars
    shootingStars = ShootingStars();
    add(shootingStars);

    // Initialize fever manager
    feverManager = FeverManager.instance;

    // Load high score and settings
    await ScoreManager.instance.loadHighScore();
    gameSpeed = initialGameSpeed;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState == GameState.playing) {
      // Update power-up manager
      powerUpManager.update(dt);

      // Update fever manager
      feverManager.update(dt);

      // Update invincibility timer
      if (_isInvincible) {
        _invincibilityTimer -= dt;
        if (_invincibilityTimer <= 0) {
          _isInvincible = false;
        }
      }

      _gameTime += dt;
      _timeSinceLastSpeedIncrease += dt;

      // Increase speed over time
      if (_timeSinceLastSpeedIncrease >= speedIncrementInterval) {
        if (gameSpeed < maxGameSpeed) {
          gameSpeed += speedIncrement;
        }
        _timeSinceLastSpeedIncrease = 0;
      }

      // Update combo timer
      if (comboTimer > 0) {
        comboTimer -= dt;
        if (comboTimer <= 0) {
          comboCount = 0;
        }
      }

      // Update score based on distance (with 2x multiplier if active)
      final multiplier =
          powerUpManager.isActive(PowerUpType.doubleScore) ? 2 : 1;
      score = ((_gameTime * 10).toInt() + (coins * 10)) * multiplier;

      // Update speed trail
      speedTrail.updateSpeed(gameSpeed);
      speedTrail.recordPosition(player.position, dt);

      // Apply screen shake offset to camera
      final shakeOffset = screenShake.getOffset();
      if (shakeOffset.x != 0 || shakeOffset.y != 0) {
        camera.viewfinder.position = shakeOffset;
      } else {
        camera.viewfinder.position = Vector2.zero();
      }

      // Periodic cleanup of off-screen components
      _cleanupTimer += dt;
      if (_cleanupTimer >= _cleanupInterval) {
        _cleanupTimer = 0;
        _cleanupOffscreenComponents();
      }

      // Tutorial hint for dash after 5 seconds of gameplay
      if (_gameTime >= 5.0 && _gameTime < 6.0) {
        TutorialManager.instance.tryShowHint(TutorialManager.hintDash);
      }

      // Update tutorial manager
      TutorialManager.instance.update(dt);
    }
  }

  /// Remove components that are far off-screen to prevent memory buildup
  void _cleanupOffscreenComponents() {
    final leftBound = -100.0;
    final rightBound = size.x + 200;
    final topBound = -200.0;
    final bottomBound = size.y + 200;

    // Clean up all PositionComponents that are way off-screen
    final toRemove = <Component>[];
    for (final child in children) {
      if (child is PositionComponent) {
        // Skip core game components
        if (child == player ||
            child == ground ||
            child == background ||
            child == obstacleManager ||
            child == screenShake ||
            child == speedTrail ||
            child == backgroundBirds ||
            child == weatherSystem ||
            child == speedLines ||
            child == ambientParticles ||
            child == shootingStars ||
            child == _dayNightCycle) {
          continue;
        }

        final pos = child.position;
        if (pos.x < leftBound ||
            pos.x > rightBound ||
            pos.y < topBound ||
            pos.y > bottomBound) {
          toRemove.add(child);
        }
      }
    }

    for (final component in toRemove) {
      component.removeFromParent();
    }
  }

  /// Triggers a screen shake effect
  void triggerScreenShake(double intensity, double duration) {
    screenShake.shake(intensity, duration);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameState == GameState.playing) {
      if (player.isRidingBird) {
        // Throw stone while riding
        player.throwStone();
      } else {
        player.jump();
      }
    }
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (gameState == GameState.playing) {
      if (event is KeyDownEvent) {
        // Jump keys
        if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
            event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.keyW) {
          player.jump();
          // Start glide if already in air and falling
          if (!player.isOnGround) {
            player.setGliding(true);
          }
          return KeyEventResult.handled;
        }
        // Slide or Ground Pound
        if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
            event.logicalKey == LogicalKeyboardKey.keyS) {
          if (player.isOnGround) {
            player.slide();
          } else {
            player.groundPound();
          }
          return KeyEventResult.handled;
        }
        // Dash
        if (event.logicalKey == LogicalKeyboardKey.keyE ||
            event.logicalKey == LogicalKeyboardKey.shiftLeft ||
            event.logicalKey == LogicalKeyboardKey.shiftRight) {
          player.dash();
          return KeyEventResult.handled;
        }
      } else if (event is KeyUpEvent) {
        // Stop gliding when jump key released
        if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
            event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.keyW) {
          player.setGliding(false);
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  void startGame() {
    gameState = GameState.playing;
    gameSpeed = initialGameSpeed;
    score = 0;
    coins = 0;
    souls = 1000; // TODO: Change back to 0 for production
    _isInvincible = false;
    _invincibilityTimer = 0;
    _gameTime = 0;
    _timeSinceLastSpeedIncrease = 0;
    comboCount = 0;
    comboTimer = 0;

    // Start mission tracking for this run
    MissionManager.instance.startRun();

    ground.reset();
    player.reset();
    obstacleManager.reset();
    powerUpManager.reset();
    feverManager.reset();
    dayNightCycle.reset();
    speedTrail.clear();
    backgroundBirds.reset();
    weatherSystem.reset();
    speedLines.reset();
    ambientParticles.reset();
    shootingStars.reset();

    overlays.remove('mainMenu');
    overlays.add('hud');
    overlays.add('tutorialHint');

    AudioManager.instance.playBgm('game_music.mp3');

    // Show initial tutorial hint
    Future.delayed(const Duration(milliseconds: 500), () {
      TutorialManager.instance.tryShowHint(TutorialManager.hintTapToJump);
    });
  }

  void pauseGame() {
    if (gameState == GameState.playing) {
      gameState = GameState.paused;
      pauseEngine();
      overlays.add('pause');
    }
  }

  void resumeGame() {
    if (gameState == GameState.paused) {
      gameState = GameState.playing;
      resumeEngine();
      overlays.remove('pause');
    }
  }

  void gameOver() {
    // Start death animation instead of immediate game over
    if (!player.isDying) {
      player.startDeathAnimation();
      AudioManager.instance.playSfx('death.mp3');
      triggerScreenShake(15, 0.3);
    }
  }

  // Missions completed in the last run (for display in game over screen)
  List<dynamic> lastCompletedMissions = [];

  /// Called after death animation completes
  void triggerGameOver() {
    gameState = GameState.gameOver;

    // Save high score
    ScoreManager.instance.checkAndSaveHighScore(score);

    // Save coins earned to total coins for character purchases
    CharacterManager.instance.addCoins(coins);

    // Update highest distance for world unlocks (score / 10 as rough distance)
    WorldManager.instance.updateDistance(score ~/ 10);

    // Check and complete missions
    lastCompletedMissions = MissionManager.instance.endRun(score, coins);

    AudioManager.instance.stopBgm();

    overlays.remove('hud');
    overlays.remove('tutorialHint');
    overlays.add('gameOver');
  }

  void returnToMenu() {
    gameState = GameState.menu;
    gameSpeed = initialGameSpeed;
    score = 0;
    coins = 0;
    souls = 0;
    _isInvincible = false;
    _invincibilityTimer = 0;
    _gameTime = 0;
    comboCount = 0;
    comboTimer = 0;

    ground.reset();
    player.reset();
    obstacleManager.reset();
    powerUpManager.reset();
    feverManager.reset();
    dayNightCycle.reset();
    speedTrail.clear();
    backgroundBirds.reset();
    weatherSystem.reset();
    speedLines.reset();
    ambientParticles.reset();
    shootingStars.reset();

    overlays.remove('gameOver');
    overlays.remove('hud');
    overlays.remove('pause');
    overlays.remove('tutorialHint');
    overlays.add('mainMenu');

    if (paused) {
      resumeEngine();
    }

    AudioManager.instance.playBgm('menu_music.mp3');
  }

  void restartGame() {
    overlays.remove('gameOver');
    startGame();
  }

  void collectCoin() {
    // Apply fever multiplier to coins
    final feverMultiplier = feverManager.coinMultiplier;
    coins += feverMultiplier;

    // Track for missions
    MissionManager.instance.onCoinCollected();

    // Update combo
    if (comboTimer > 0) {
      comboCount++;
    } else {
      comboCount = 1;
    }
    comboTimer = comboWindow;

    // Track combo for missions
    MissionManager.instance.onComboAchieved(comboCount);

    // Add to fever meter
    feverManager.onCoinCollected();
    if (comboCount > 1) {
      feverManager.onCombo(comboCount);
    }

    // Apply combo multiplier to coin value (capped at 5x)
    final comboMultiplier = min(comboCount, 5);
    // Bonus points for combo (in addition to base coin value)
    if (comboCount > 1) {
      score += (comboMultiplier - 1) * 5;
    }

    // Show score popup with fever bonus
    final popupPos = Vector2(player.position.x + 30, player.position.y - 50);
    final coinValue = 10 * feverMultiplier;
    add(ScorePopup(
      position: popupPos,
      text: '+$coinValue',
      color: feverManager.isFeverActive
          ? const Color(0xFFFF1493) // Hot pink during fever
          : const Color(0xFFFFD700),
    ));

    // Show combo popup for high combos
    if (comboCount >= 3) {
      add(ComboPopup(
        position: Vector2(player.position.x, player.position.y - 80),
        comboCount: comboCount,
      ));

      // Excited expression for high combos
      player.setExcited();

      // Screen flash for high combos
      if (comboCount >= 5) {
        triggerScreenShake(3, 0.1);
      }
    }

    AudioManager.instance.playSfx('coin.mp3');
  }

  void collectPowerUp(PowerUpType type) {
    powerUpManager.activate(type);

    // Track for missions
    MissionManager.instance.onPowerUpUsed();

    AudioManager.instance.playSfx('powerup.mp3');
  }

  /// Collect a soul (extra life)
  void collectSoul() {
    souls++;

    // Track for missions
    MissionManager.instance.onSoulCollected();

    // Show soul collected popup
    final popupPos = Vector2(player.position.x + 30, player.position.y - 60);
    add(ScorePopup(
      position: popupPos,
      text: '+1 Soul',
      color: const Color(0xFF00FFFF),
      fontSize: 18,
    ));

    AudioManager.instance.playSfx('powerup.mp3');
  }

  /// Try to consume a soul to survive death
  /// Returns true if soul was consumed, false if no souls available
  bool consumeSoul() {
    if (souls > 0 && !_isInvincible) {
      souls--;
      _isInvincible = true;
      _invincibilityTimer = invincibilityDuration;

      // Visual feedback
      triggerScreenShake(10, 0.2);

      // Show soul used popup
      final popupPos = Vector2(player.position.x, player.position.y - 50);
      add(ScorePopup(
        position: popupPos,
        text: 'Soul Saved!',
        color: const Color(0xFF00FFFF),
        fontSize: 20,
      ));

      return true;
    }
    return false;
  }

  /// Check if player is currently invincible (from soul or fever)
  bool get isPlayerInvincible => _isInvincible || feverManager.isFeverActive;

  /// Called when player stomps on a bird
  void collectStompBonus(int bonusCoins, Vector2 position) {
    // Apply fever multiplier
    final feverMultiplier = feverManager.coinMultiplier;
    coins += bonusCoins * feverMultiplier;

    // Update score directly with stomp bonus
    score += bonusCoins * 10 * feverMultiplier;

    // Track for missions
    MissionManager.instance.onBirdStomped();

    // Add to fever meter
    feverManager.onStomp();

    // Spawn coin pop particles
    final coinPop = ParticleFactory.createCoinPop(position, bonusCoins);
    if (coinPop != null) {
      add(coinPop);
    }

    // Show stomp popup
    add(ScorePopup(
      position: position + Vector2(0, -20),
      text: '+${bonusCoins * 10}',
      color: const Color(0xFF00FF00),
      fontSize: 20,
    ));

    // Stomp impact effect
    add(StompImpact(position: position));

    // Play coin sound
    AudioManager.instance.playSfx('coin.mp3');
  }

  /// Spawn landing effects when player lands
  void spawnLandingEffect(Vector2 position, double intensity) {
    // Shockwave ring
    add(LandingShockwave(
      position: position,
      maxRadius: 30 + intensity * 20,
    ));

    // Dust cloud
    add(LandingDust(
      position: position,
      puffCount: (4 + intensity * 4).toInt(),
    ));
  }

  void showDonation() {
    overlays.add('donation');
  }

  void hideDonation() {
    overlays.remove('donation');
  }

  void showSettings() {
    overlays.add('settings');
  }

  void hideSettings() {
    overlays.remove('settings');
  }

  void showCharacterSelect() {
    overlays.add('characterSelect');
  }

  void hideCharacterSelect() {
    overlays.remove('characterSelect');
  }

  void showWorldSelect() {
    overlays.add('worldSelect');
  }

  void hideWorldSelect() {
    overlays.remove('worldSelect');
  }

  void showMissions() {
    overlays.add('missions');
  }

  void hideMissions() {
    overlays.remove('missions');
  }

  @override
  Color backgroundColor() => _dayNightCycle?.getCurrentSkyColor() ?? const Color(0xFF87CEEB);
}
