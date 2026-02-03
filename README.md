# Play It Forward

An open source endless runner game built with Flutter and Flame engine. Run, jump, and dash your way through challenging obstacles while collecting coins and power-ups!

## Features

### Core Gameplay
- **Jump & Double Jump** - Tap to jump, tap again mid-air for double jump
- **Slide** - Press down to slide under obstacles
- **Dash** - Quick speed burst with cooldown
- **Glide** - Hold jump while falling to float down slowly
- **Ground Pound** - Press down mid-air to slam down quickly
- **Wall Jump** - Jump off walls to reach new heights

### Characters
Unlock unique characters with special abilities:
| Character | Cost | Ability |
|-----------|------|---------|
| Runner | Free | Balanced stats |
| Ninja | 500 | Double dash |
| Robot | 750 | Longer glide |
| Wizard | 1000 | Coin magnet aura |
| Astronaut | 1500 | Low gravity |
| Phoenix | 2000 | Faster fever charge |

### Worlds
Progress through themed worlds:
- **Forest** - Default starting world
- **Desert** - Unlocks at 1000m distance
- **Snow** - Unlocks at 2500m distance
- **Space** - Unlocks at 5000m distance

### Power-Ups
- **Shield** - Protects from one hit
- **Magnet** - Attracts nearby coins
- **Double Score** - 2x points
- **Slow Motion** - Slows game speed

### Special Features
- **Fever Mode** - Fill the meter for 10 seconds of invincibility with 3x coins
- **Treasure Chests** - Bronze, Silver, and Gold chests with coin rewards
- **Rideable Birds** - Stomp golden birds to ride them and throw stones at obstacles
- **Risky Paths** - Take the high road for more rewards
- **Missions** - Complete challenges to earn bonus coins
- **Souls** - Collect souls for extra lives

### Visual Effects
- Day/night cycle
- Dynamic weather (rain, snow, sandstorm)
- Ambient particles (fireflies, butterflies, dust)
- Screen shake and impact effects
- Shooting stars at night

## Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK

### Installation

1. Clone the repository:
```bash
git clone https://github.com/phpirate/play-it-forward.git
cd play-it-forward
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the game:
```bash
# Web
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios

# Desktop
flutter run -d windows
flutter run -d macos
flutter run -d linux
```

### Building for Production

**Web:**
```bash
flutter build web --release
```

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## Controls

### Mobile / Touch
- **Tap** - Jump (tap again for double jump)
- **Swipe Down** - Slide (on ground) / Ground Pound (in air)
- **Tap while riding bird** - Throw stone

### Keyboard
- **Space / W / Up Arrow** - Jump
- **S / Down Arrow** - Slide / Ground Pound
- **E / Shift** - Dash
- **Hold Jump Key** - Glide (while falling)

## Project Structure

```
lib/
├── components/          # Game objects
│   ├── player.dart
│   ├── obstacle.dart
│   ├── coin.dart
│   ├── bird.dart
│   ├── rideable_bird.dart
│   ├── treasure_chest.dart
│   └── ...
├── effects/             # Visual effects
│   ├── particle_factory.dart
│   ├── weather_system.dart
│   ├── day_night_cycle.dart
│   └── ...
├── managers/            # Game state managers
│   ├── character_manager.dart
│   ├── world_manager.dart
│   ├── mission_manager.dart
│   └── ...
├── models/              # Data models
│   ├── character.dart
│   ├── mission.dart
│   └── world_theme.dart
├── overlays/            # UI screens
│   ├── main_menu_overlay.dart
│   ├── hud_overlay.dart
│   └── ...
└── game/
    └── play_it_forward_game.dart
```

## Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Game engine: [Flame](https://flame-engine.org/)
- Audio: [flame_audio](https://pub.dev/packages/flame_audio)
