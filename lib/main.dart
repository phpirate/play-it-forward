import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/play_it_forward_game.dart';
import 'overlays/main_menu_overlay.dart';
import 'overlays/game_over_overlay.dart';
import 'overlays/pause_overlay.dart';
import 'overlays/hud_overlay.dart';
import 'overlays/donation_overlay.dart';
import 'overlays/settings_overlay.dart';
import 'overlays/character_select_overlay.dart';
import 'overlays/world_select_overlay.dart';
import 'overlays/missions_overlay.dart';
import 'managers/audio_manager.dart';
import 'managers/effects_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow both portrait and landscape modes
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide status bar for fullscreen
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize audio
  await AudioManager.instance.init();

  // Initialize effects settings
  await EffectsManager.instance.init();

  runApp(const PlayItForwardApp());
}

class PlayItForwardApp extends StatelessWidget {
  const PlayItForwardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Play It Forward',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: const GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late PlayItForwardGame game;

  @override
  void initState() {
    super.initState();
    game = PlayItForwardGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<PlayItForwardGame>(
        game: game,
        overlayBuilderMap: {
          'mainMenu': (context, game) => MainMenuOverlay(game: game),
          'hud': (context, game) => HudOverlay(game: game),
          'gameOver': (context, game) => GameOverOverlay(game: game),
          'pause': (context, game) => PauseOverlay(game: game),
          'donation': (context, game) => DonationOverlay(game: game),
          'settings': (context, game) => SettingsOverlay(game: game),
          'characterSelect': (context, game) => CharacterSelectOverlay(game: game),
          'worldSelect': (context, game) => WorldSelectOverlay(game: game),
          'missions': (context, game) => MissionsOverlay(game: game),
        },
        initialActiveOverlays: const ['mainMenu'],
      ),
    );
  }
}
