import 'dart:math';
import 'package:flame/components.dart';
import '../game/play_it_forward_game.dart';
import '../managers/power_up_manager.dart';
import 'obstacle.dart';
import 'coin.dart';
import 'bird.dart';
import 'power_up.dart';
import 'wall.dart';
import 'platforms/bouncy_platform.dart';
import 'soul.dart';
import 'treasure_chest.dart';
import 'risky_path.dart';
import 'rideable_bird.dart';

class ObstacleManager extends Component with HasGameRef<PlayItForwardGame> {
  final Random _random = Random();

  double _timeSinceLastObstacle = 0;
  double _timeSinceLastCoin = 0;
  double _timeSinceLastPowerUp = 0;
  double _timeSinceLastSoul = 0;
  double _timeSinceLastChest = 0;
  double _timeSinceLastRiskyPath = 0;
  double _timeSinceLastRideableBird = 0;

  double get spawnInterval => 2.0 - (gameRef.gameSpeed - 200) / 400; // Faster spawn as speed increases
  double get minSpawnInterval => 1.0;
  double get coinSpawnInterval => 1.5;
  double get powerUpSpawnInterval => 8.0;
  double get powerUpSpawnChance => 0.25;
  double get soulSpawnInterval => 15.0; // Souls are rare
  double get soulSpawnChance => 0.3; // 30% chance when interval triggers
  double get chestSpawnInterval => 20.0; // Treasure chests are rare
  double get chestSpawnChance => 0.15; // 15% chance when interval triggers (roughly 2-3% effective)
  double get riskyPathSpawnInterval => 30.0; // Risky paths every 30 seconds
  double get riskyPathSpawnChance => 0.4; // 40% chance when interval triggers
  double get rideableBirdSpawnInterval => 25.0; // Rideable birds every 25 seconds
  double get rideableBirdSpawnChance => 0.35; // 35% chance when interval triggers

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.gameState != GameState.playing) return;

    _timeSinceLastObstacle += dt;
    _timeSinceLastCoin += dt;
    _timeSinceLastPowerUp += dt;

    // Spawn obstacles
    final currentInterval = max(minSpawnInterval, spawnInterval);
    if (_timeSinceLastObstacle >= currentInterval) {
      _spawnObstacle();
      _timeSinceLastObstacle = 0;
    }

    // Spawn coins
    if (_timeSinceLastCoin >= coinSpawnInterval) {
      if (_random.nextDouble() < 0.4) {
        _spawnCoin();
      }
      _timeSinceLastCoin = 0;
    }

    // Spawn power-ups
    if (_timeSinceLastPowerUp >= powerUpSpawnInterval) {
      if (_random.nextDouble() < powerUpSpawnChance) {
        _spawnPowerUp();
      }
      _timeSinceLastPowerUp = 0;
    }

    // Spawn souls (rare)
    _timeSinceLastSoul += dt;
    if (_timeSinceLastSoul >= soulSpawnInterval) {
      if (_random.nextDouble() < soulSpawnChance) {
        _spawnSoul();
      }
      _timeSinceLastSoul = 0;
    }

    // Spawn treasure chests (rare)
    _timeSinceLastChest += dt;
    if (_timeSinceLastChest >= chestSpawnInterval) {
      if (_random.nextDouble() < chestSpawnChance) {
        _spawnTreasureChest();
      }
      _timeSinceLastChest = 0;
    }

    // Spawn risky paths (occasional)
    _timeSinceLastRiskyPath += dt;
    if (_timeSinceLastRiskyPath >= riskyPathSpawnInterval) {
      if (_random.nextDouble() < riskyPathSpawnChance) {
        _spawnRiskyPath();
      }
      _timeSinceLastRiskyPath = 0;
    }

    // Spawn rideable birds (occasional)
    _timeSinceLastRideableBird += dt;
    if (_timeSinceLastRideableBird >= rideableBirdSpawnInterval) {
      if (_random.nextDouble() < rideableBirdSpawnChance) {
        _spawnRideableBird();
      }
      _timeSinceLastRideableBird = 0;
    }
  }

  void _spawnSoul() {
    final spawnX = gameRef.size.x + 50;
    final groundY = gameRef.ground.getGroundYAt(spawnX);

    // Souls float at medium height
    final soulY = groundY - 80 - _random.nextDouble() * 60;

    final soul = Soul(position: Vector2(spawnX, soulY));
    gameRef.add(soul);
  }

  void _spawnTreasureChest() {
    final spawnX = gameRef.size.x + 50;
    final groundY = gameRef.ground.getGroundYAt(spawnX);

    // Determine chest tier
    // Bronze: 60%, Silver: 30%, Gold: 10%
    final roll = _random.nextDouble();
    ChestTier tier;
    if (roll < 0.60) {
      tier = ChestTier.bronze;
    } else if (roll < 0.90) {
      tier = ChestTier.silver;
    } else {
      tier = ChestTier.gold;
    }

    final chest = TreasureChest(
      position: Vector2(spawnX, groundY),
      tier: tier,
    );
    gameRef.add(chest);
  }

  void _spawnRiskyPath() {
    final spawnX = gameRef.size.x + 100;

    final riskyPath = RiskyPath(position: Vector2(spawnX, 0));
    gameRef.add(riskyPath);
  }

  void _spawnRideableBird() {
    final spawnX = gameRef.size.x + 100;
    final groundY = gameRef.ground.getGroundYAt(spawnX);

    // Rideable bird flies higher than regular birds
    final birdY = groundY - 70;

    final bird = RideableBird();
    bird.position = Vector2(spawnX, birdY);
    gameRef.add(bird);
  }

  void _spawnObstacle() {
    final spawnX = gameRef.size.x + 50;
    final groundY = gameRef.ground.getGroundYAt(spawnX);

    final roll = _random.nextDouble();

    // 25% chance to spawn a bird
    if (roll < 0.25) {
      _spawnBird();
      return;
    }

    // 10% chance to spawn a wall (for wall jumping)
    if (roll < 0.35) {
      _spawnWall();
      return;
    }

    // 10% chance to spawn a bouncy platform
    if (roll < 0.45) {
      _spawnBouncyPlatform();
      return;
    }

    // Regular obstacle
    final types = ObstacleType.values;
    final type = types[_random.nextInt(types.length)];

    final obstacle = Obstacle(
      type: type,
      position: Vector2(spawnX, groundY),
    );

    gameRef.add(obstacle);
  }

  void _spawnWall() {
    final spawnX = gameRef.size.x + 50;
    final groundY = gameRef.ground.getGroundYAt(spawnX);

    final wall = Wall(position: Vector2(spawnX, groundY));
    gameRef.add(wall);

    // Add coins above the wall to reward wall jumping
    for (int i = 0; i < 3; i++) {
      final coinY = groundY - 80 - i * 30;
      final coin = Coin(position: Vector2(spawnX + 30, coinY));
      gameRef.add(coin);
    }
  }

  void _spawnBouncyPlatform() {
    final spawnX = gameRef.size.x + 50;
    final groundY = gameRef.ground.getGroundYAt(spawnX);

    final platform = BouncyPlatform(position: Vector2(spawnX, groundY));
    gameRef.add(platform);

    // Add coins above the platform to reward bouncing
    for (int i = 0; i < 4; i++) {
      final coinY = groundY - 150 - i * 25;
      final coin = Coin(position: Vector2(spawnX, coinY));
      gameRef.add(coin);
    }
  }

  void _spawnBird() {
    final spawnX = gameRef.size.x + 50;
    final groundY = gameRef.ground.getGroundYAt(spawnX);

    // Bird flies at head height (must slide under)
    final birdY = groundY - 45;

    final bird = Bird();
    bird.position = Vector2(spawnX, birdY);
    gameRef.add(bird);
  }

  void _spawnCoin() {
    final spawnX = gameRef.size.x + 50;
    final groundY = gameRef.ground.getGroundYAt(spawnX);

    // Random height for coin (above ground)
    final coinY = groundY - 50 - _random.nextDouble() * 100;

    final coin = Coin(position: Vector2(spawnX, coinY));
    gameRef.add(coin);
  }

  void _spawnPowerUp() {
    final spawnX = gameRef.size.x + 50;
    final groundY = gameRef.ground.getGroundYAt(spawnX);

    // Random height for power-up (above ground)
    final powerUpY = groundY - 60 - _random.nextDouble() * 80;

    // Weighted random type selection
    // Shield: 30%, Magnet: 25%, DoubleScore: 25%, SlowMotion: 20%
    final roll = _random.nextDouble();
    PowerUpType type;
    if (roll < 0.30) {
      type = PowerUpType.shield;
    } else if (roll < 0.55) {
      type = PowerUpType.magnet;
    } else if (roll < 0.80) {
      type = PowerUpType.doubleScore;
    } else {
      type = PowerUpType.slowMotion;
    }

    final powerUp = PowerUp(type: type, position: Vector2(spawnX, powerUpY));
    gameRef.add(powerUp);
  }

  void reset() {
    _timeSinceLastObstacle = 0;
    _timeSinceLastCoin = 0;
    _timeSinceLastPowerUp = 0;
    _timeSinceLastSoul = 0;
    _timeSinceLastChest = 0;
    _timeSinceLastRiskyPath = 0;
    _timeSinceLastRideableBird = 0;

    // Remove all existing obstacles, birds, coins, power-ups, walls, platforms, souls, chests, risky paths, rideable birds
    gameRef.children.whereType<Obstacle>().forEach((o) => o.removeFromParent());
    gameRef.children.whereType<Bird>().forEach((b) => b.removeFromParent());
    gameRef.children.whereType<Coin>().forEach((c) => c.removeFromParent());
    gameRef.children.whereType<PowerUp>().forEach((p) => p.removeFromParent());
    gameRef.children.whereType<Wall>().forEach((w) => w.removeFromParent());
    gameRef.children.whereType<BouncyPlatform>().forEach((bp) => bp.removeFromParent());
    gameRef.children.whereType<Soul>().forEach((s) => s.removeFromParent());
    gameRef.children.whereType<TreasureChest>().forEach((tc) => tc.removeFromParent());
    gameRef.children.whereType<RiskyPath>().forEach((rp) => rp.removeFromParent());
    gameRef.children.whereType<RideableBird>().forEach((rb) => rb.removeFromParent());
  }
}
