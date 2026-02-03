import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/audio_manager.dart';
import '../managers/score_manager.dart';
import '../managers/effects_manager.dart';

class SettingsOverlay extends StatefulWidget {
  final PlayItForwardGame game;

  const SettingsOverlay({super.key, required this.game});

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  bool _soundEnabled = AudioManager.instance.soundEnabled;
  bool _musicEnabled = AudioManager.instance.musicEnabled;
  double _initialSpeed = ScoreManager.instance.initialSpeed;
  bool _particlesEnabled = EffectsManager.instance.particlesEnabled;
  bool _screenShakeEnabled = EffectsManager.instance.screenShakeEnabled;
  bool _animationsEnabled = EffectsManager.instance.animationsEnabled;
  bool _dayNightCycleEnabled = EffectsManager.instance.dayNightCycleEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => widget.game.hideSettings(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Sound toggle
                _SettingsTile(
                  icon: Icons.volume_up,
                  title: 'Sound Effects',
                  value: _soundEnabled,
                  onChanged: (value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                    AudioManager.instance.setSoundEnabled(value);
                  },
                ),

                const SizedBox(height: 15),

                // Music toggle
                _SettingsTile(
                  icon: Icons.music_note,
                  title: 'Music',
                  value: _musicEnabled,
                  onChanged: (value) {
                    setState(() {
                      _musicEnabled = value;
                    });
                    AudioManager.instance.setMusicEnabled(value);
                  },
                ),

                const SizedBox(height: 15),

                // Particle Effects toggle
                _SettingsTile(
                  icon: Icons.auto_awesome,
                  title: 'Particle Effects',
                  value: _particlesEnabled,
                  onChanged: (value) {
                    setState(() {
                      _particlesEnabled = value;
                    });
                    EffectsManager.instance.setParticlesEnabled(value);
                  },
                ),

                const SizedBox(height: 15),

                // Screen Shake toggle
                _SettingsTile(
                  icon: Icons.vibration,
                  title: 'Screen Shake',
                  value: _screenShakeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _screenShakeEnabled = value;
                    });
                    EffectsManager.instance.setScreenShakeEnabled(value);
                  },
                ),

                const SizedBox(height: 15),

                // Animations toggle
                _SettingsTile(
                  icon: Icons.animation,
                  title: 'Animations',
                  value: _animationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _animationsEnabled = value;
                    });
                    EffectsManager.instance.setAnimationsEnabled(value);
                  },
                ),

                const SizedBox(height: 15),

                // Day/Night Cycle toggle
                _SettingsTile(
                  icon: Icons.dark_mode,
                  title: 'Day/Night Cycle',
                  value: _dayNightCycleEnabled,
                  onChanged: (value) {
                    setState(() {
                      _dayNightCycleEnabled = value;
                    });
                    EffectsManager.instance.setDayNightCycleEnabled(value);
                  },
                ),

                const SizedBox(height: 15),

                // Initial Speed slider
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.speed, color: Colors.white, size: 28),
                          const SizedBox(width: 15),
                          const Text(
                            'Initial Speed',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _initialSpeed.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _initialSpeed,
                        min: 200,
                        max: 500,
                        divisions: 6,
                        activeColor: Colors.green,
                        inactiveColor: Colors.grey.shade600,
                        onChanged: (value) {
                          setState(() {
                            _initialSpeed = value;
                          });
                          ScoreManager.instance.setInitialSpeed(value);
                        },
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Slow', style: TextStyle(color: Colors.white38, fontSize: 12)),
                          Text('Fast', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Stats
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'High Score: ${ScoreManager.instance.highScore}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Total Coins: ${ScoreManager.instance.totalCoins}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Reset Data button
                TextButton(
                  onPressed: () => _showResetDialog(context),
                  child: const Text(
                    'Reset All Data',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Version
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Reset All Data?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will delete your high score and all progress. This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ScoreManager.instance.resetAll();
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }
}
