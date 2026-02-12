import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/player.dart';
import '../components/ground.dart';
import '../components/obstacle_manager.dart';
import '../components/parallax_background.dart';
import '../components/npc.dart';
import '../components/follower.dart';
import 'dart:math';
import '../managers/score_manager.dart';
import '../managers/audio_manager.dart';
import '../managers/power_up_manager.dart';
import '../managers/fever_manager.dart';
import '../managers/character_manager.dart';
import '../managers/world_manager.dart';
import '../managers/mission_manager.dart';
import '../managers/tutorial_manager.dart';
import '../managers/level_manager.dart';
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
import '../data/level_data.dart';

enum GameState { menu, playing, paused, gameOver, levelIntro, levelComplete }

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

  // Level/Campaign system
  final List<Follower> _followers = [];
  NPC? _levelNpc;
  bool _npcSpawned = false;

  // Lives system for campaign mode
  int _lives = 5;
  static const int maxLives = 5;
  static const double respawnInvincibilityDuration = 3.0;

  int get lives => _lives;

  GameState gameState = GameState.menu;

  late double gameSpeed;

  /// Returns game speed accounting for slow motion power-up and mud slow
  double get effectiveGameSpeed {
    double speed = gameSpeed;

    // Slow motion power-up
    if (powerUpManager.isActive(PowerUpType.slowMotion)) {
      speed *= 0.5;
    }

    // Mud slow effect
    if (player.isInMud) {
      speed *= player.mudSpeedMultiplier;
    }

    return speed;
  }
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
  static const double baseComboWindow = 1.5; // Seconds to maintain combo

  /// Get effective combo window with follower bonuses
  double get comboWindow {
    if (LevelManager.instance.isPlayingCampaign) {
      final bonus = LevelManager.instance.cumulativeBonus;
      return baseComboWindow * (1 + bonus.comboTimerBonus);
    }
    return baseComboWindow;
  }

  /// Get follower coin value multiplier
  double get followerCoinMultiplier {
    if (LevelManager.instance.isPlayingCampaign) {
      final bonus = LevelManager.instance.cumulativeBonus;
      return 1 + bonus.coinValueBonus;
    }
    return 1.0;
  }

  /// Get follower score multiplier
  double get followerScoreMultiplier {
    if (LevelManager.instance.isPlayingCampaign) {
      final bonus = LevelManager.instance.cumulativeBonus;
      return 1 + bonus.scoreMultiplierBonus;
    }
    return 1.0;
  }

  /// Check if bird warning is active (from Skyler the bird)
  bool get hasBirdWarning {
    if (LevelManager.instance.isPlayingCampaign) {
      return LevelManager.instance.cumulativeBonus.birdWarning;
    }
    return false;
  }

  /// Get extra coin magnet range from followers
  double get extraCoinMagnetRange {
    if (LevelManager.instance.isPlayingCampaign) {
      return LevelManager.instance.cumulativeBonus.coinMagnetRange;
    }
    return 0.0;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize character, world, mission, tutorial, and level managers
    await CharacterManager.instance.load();
    await WorldManager.instance.load();
    await MissionManager.instance.load();
    await TutorialManager.instance.load();
    await LevelManager.instance.load();

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

      // Campaign level tracking
      if (LevelManager.instance.isPlayingCampaign) {
        // Calculate distance based on game time and speed
        final distance = _gameTime * (effectiveGameSpeed / 10);
        LevelManager.instance.setDistance(distance);
        LevelManager.instance.updateTime(dt);

        // Check if we should spawn the NPC (goal marker)
        _checkNpcSpawn(distance);

        // Check if player reached the NPC
        _checkLevelComplete();
      }

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
    // Check if we're in campaign mode with lives remaining
    if (LevelManager.instance.isPlayingCampaign && _lives > 1) {
      // Lose a life and respawn
      _lives--;
      _respawnPlayer();
      return;
    }

    gameState = GameState.gameOver;

    // Save high score
    ScoreManager.instance.checkAndSaveHighScore(score);

    // Save coins earned to total coins for character purchases
    CharacterManager.instance.addCoins(coins);

    // Update highest distance for world unlocks (score / 10 as rough distance)
    WorldManager.instance.updateDistance(score ~/ 10);

    // Check and complete missions
    lastCompletedMissions = MissionManager.instance.endRun(score, coins);

    // End campaign run if active (without completing the level)
    if (LevelManager.instance.isPlayingCampaign) {
      LevelManager.instance.endRun();
    }

    // Remove followers
    for (final follower in _followers) {
      follower.removeFromParent();
    }
    _followers.clear();

    AudioManager.instance.stopBgm();

    overlays.remove('hud');
    overlays.remove('tutorialHint');
    overlays.add('gameOver');
  }

  /// Respawn player after losing a life in campaign mode
  void _respawnPlayer() {
    // Clear nearby obstacles
    obstacleManager.clearNearbyObstacles(player.position.x, 200);

    // Reset player state
    player.respawn();

    // Give temporary invincibility
    _isInvincible = true;
    _invincibilityTimer = respawnInvincibilityDuration;

    // Visual feedback
    triggerScreenShake(5, 0.2);

    // Show lives remaining popup
    final popupPos = Vector2(player.position.x, player.position.y - 60);
    add(ScorePopup(
      position: popupPos,
      text: '$_lives Lives Left',
      color: const Color(0xFFFF6B6B),
      fontSize: 22,
    ));

    // Resume game state
    gameState = GameState.playing;
  }

  void returnToMenu() {
    // End campaign run if active
    if (LevelManager.instance.isPlayingCampaign) {
      LevelManager.instance.endRun();
    }

    gameState = GameState.menu;
    _resetGameState();

    overlays.remove('gameOver');
    overlays.remove('hud');
    overlays.remove('pause');
    overlays.remove('tutorialHint');
    overlays.remove('levelIntro');
    overlays.remove('levelComplete');
    overlays.remove('levelSelect');
    overlays.add('mainMenu');

    AudioManager.instance.playBgm('menu_music.mp3');
  }

  void restartGame() {
    overlays.remove('gameOver');
    startGame();
  }

  void collectCoin() {
    // Apply fever multiplier and follower bonus to coins
    final feverMultiplier = feverManager.coinMultiplier;
    final coinMultiplier = (feverMultiplier * followerCoinMultiplier).round();
    coins += coinMultiplier;

    // Track for missions
    MissionManager.instance.onCoinCollected();

    // Update combo
    if (comboTimer > 0) {
      comboCount++;
    } else {
      comboCount = 1;
    }
    comboTimer = comboWindow; // Uses effective combo window with bonuses

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

    // Show score popup with fever bonus and follower bonus
    final popupPos = Vector2(player.position.x + 30, player.position.y - 50);
    final coinValue = (10 * coinMultiplier).round();
    add(ScorePopup(
      position: popupPos,
      text: '+$coinValue',
      color: feverManager.isFeverActive
          ? const Color(0xFFFF1493) // Hot pink during fever
          : followerCoinMultiplier > 1.0
              ? const Color(0xFFFFB6C1) // Light pink when follower bonus active
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

  // ============== CAMPAIGN/LEVEL SYSTEM ==============

  /// Show level select overlay
  void showLevelSelect() {
    overlays.remove('mainMenu');
    overlays.add('levelSelect');
  }

  /// Hide level select overlay
  void hideLevelSelect() {
    overlays.remove('levelSelect');
    overlays.add('mainMenu');
  }

  /// Select a level and show intro
  void selectLevel(int levelNumber) {
    LevelManager.instance.startLevel(levelNumber);
    overlays.remove('levelSelect');
    gameState = GameState.levelIntro;
    overlays.add('levelIntro');
  }

  /// Start the actual gameplay for campaign level
  void startCampaignLevel() {
    final levelManager = LevelManager.instance;
    final level = levelManager.currentLevel;
    if (level == null) return;

    gameState = GameState.playing;

    // Set initial speed from level difficulty
    gameSpeed = level.difficulty.speed;
    score = 0;
    coins = 0;
    souls = 0;
    // Apply extra starting lives from followers (Flora, Doctor Grace)
    final extraLives = LevelManager.instance.cumulativeBonus.extraStartingLives;
    _lives = maxLives + extraLives;
    _isInvincible = false;
    _invincibilityTimer = 0;
    _gameTime = 0;
    _timeSinceLastSpeedIncrease = 0;
    comboCount = 0;
    comboTimer = 0;
    _npcSpawned = false;
    _levelNpc = null;

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

    // Spawn followers from previously completed levels
    _spawnFollowers();

    overlays.remove('levelIntro');
    overlays.add('hud');
    overlays.add('tutorialHint');

    AudioManager.instance.playBgm('game_music.mp3');
  }

  /// Spawn followers for completed levels
  void _spawnFollowers() {
    // Remove existing followers
    for (final follower in _followers) {
      follower.removeFromParent();
    }
    _followers.clear();

    // Get unlocked followers
    final unlockedFollowers = LevelManager.instance.getUnlockedFollowers();
    final groundY = ground.getGroundYAt(player.position.x);
    for (int i = 0; i < unlockedFollowers.length; i++) {
      final npcData = unlockedFollowers[i];
      final follower = Follower(
        data: npcData,
        index: i,
        position: Vector2(player.position.x - 55 - i * 45, groundY),
      );
      _followers.add(follower);
      add(follower);
    }
  }

  /// Check if NPC should spawn (near goal distance)
  void _checkNpcSpawn(double currentDistance) {
    if (_npcSpawned || _levelNpc != null) return;

    final level = LevelManager.instance.currentLevel;
    if (level == null) return;

    // Spawn NPC when player is 100m from goal
    if (currentDistance >= level.targetDistance - 100) {
      _spawnLevelNpc();
    }
  }

  /// Spawn the NPC at the goal
  void _spawnLevelNpc() {
    final level = LevelManager.instance.currentLevel;
    if (level == null) return;

    _npcSpawned = true;
    final groundY = ground.getGroundYAt(size.x + 100);
    _levelNpc = NPC(
      data: level.npcToHelp,
      position: Vector2(size.x + 100, groundY),
    );
    add(_levelNpc!);
  }

  /// Check if player has reached the NPC
  void _checkLevelComplete() {
    if (_levelNpc == null || _levelNpc!.isCollected) return;

    // If player is riding a bird and NPC is close, end the ride
    // so player can land and rescue the NPC
    if (player.isRidingBird) {
      final xDistance = (_levelNpc!.position.x - player.position.x).abs();
      if (xDistance < 100) {
        player.endRiding();
      }
      return; // Wait for player to land before checking collision
    }

    // Check collision with NPC
    final playerBounds = player.toRect();
    final npcBounds = _levelNpc!.toRect();

    if (playerBounds.overlaps(npcBounds)) {
      _onLevelComplete();
    }
  }

  /// Handle level completion
  void _onLevelComplete() {
    if (_levelNpc == null) return;

    _levelNpc!.collect();

    // Add coins to level manager
    LevelManager.instance.addCoins(coins);

    // Complete the level
    LevelManager.instance.completeLevel();

    // Trigger celebration
    triggerScreenShake(8, 0.3);
    AudioManager.instance.playSfx('powerup.mp3');

    // Show level complete overlay
    gameState = GameState.levelComplete;
    overlays.remove('hud');
    overlays.remove('tutorialHint');
    overlays.add('levelComplete');
  }

  /// Start the next level
  void startNextLevel(int levelNumber) {
    overlays.remove('levelComplete');
    selectLevel(levelNumber);
  }

  /// Return to level select from level complete
  void showLevelSelectFromComplete() {
    overlays.remove('levelComplete');
    LevelManager.instance.endRun();
    gameState = GameState.menu;

    // Reset game state
    _resetGameState();

    overlays.add('levelSelect');
  }

  /// Helper to reset game state
  void _resetGameState() {
    gameSpeed = initialGameSpeed;
    score = 0;
    coins = 0;
    souls = 0;
    _isInvincible = false;
    _invincibilityTimer = 0;
    _gameTime = 0;
    comboCount = 0;
    comboTimer = 0;
    _npcSpawned = false;
    _levelNpc = null;

    // Remove followers
    for (final follower in _followers) {
      follower.removeFromParent();
    }
    _followers.clear();

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

    if (paused) {
      resumeEngine();
    }
  }

  /// Get current distance for HUD display
  double get currentDistance {
    if (LevelManager.instance.isPlayingCampaign) {
      return LevelManager.instance.currentDistance;
    }
    return _gameTime * (effectiveGameSpeed / 10);
  }

  /// Get level progress for HUD (0.0 to 1.0)
  double get levelProgress => LevelManager.instance.levelProgress;

  /// Get follower count for HUD
  int get followerCount => LevelManager.instance.completedLevels;
}
