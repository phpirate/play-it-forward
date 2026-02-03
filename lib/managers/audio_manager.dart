import 'package:flame_audio/flame_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioManager {
  static final AudioManager instance = AudioManager._();
  AudioManager._();

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _initialized = false;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _musicEnabled = prefs.getBool('musicEnabled') ?? true;

    // Preload audio files for web
    try {
      await FlameAudio.audioCache.loadAll([
        'jump.mp3',
        'coin.mp3',
        'death.mp3',
        'game_music.mp3',
        'menu_music.mp3',
        'powerup.mp3',
        'shield_break.mp3',
      ]);
      _initialized = true;
    } catch (e) {
      // Audio files might not exist yet
      _initialized = false;
    }
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', enabled);
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('musicEnabled', enabled);

    if (!enabled) {
      stopBgm();
    }
  }

  void playSfx(String filename) {
    if (_soundEnabled && _initialized) {
      try {
        FlameAudio.play(filename);
      } catch (e) {
        // Audio file not found, ignore
      }
    }
  }

  void playBgm(String filename) {
    if (_musicEnabled && _initialized) {
      try {
        FlameAudio.bgm.stop();
        FlameAudio.bgm.play(filename, volume: 0.5);
      } catch (e) {
        // Audio file not found, ignore
      }
    }
  }

  void stopBgm() {
    try {
      FlameAudio.bgm.stop();
    } catch (e) {
      // Ignore
    }
  }

  void pauseBgm() {
    try {
      FlameAudio.bgm.pause();
    } catch (e) {
      // Ignore
    }
  }

  void resumeBgm() {
    if (_musicEnabled) {
      try {
        FlameAudio.bgm.resume();
      } catch (e) {
        // Ignore
      }
    }
  }
}
