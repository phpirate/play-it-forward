import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';
import '../managers/mission_manager.dart';
import '../models/mission.dart';

class MissionsOverlay extends StatefulWidget {
  final PlayItForwardGame game;

  const MissionsOverlay({super.key, required this.game});

  @override
  State<MissionsOverlay> createState() => _MissionsOverlayState();
}

class _MissionsOverlayState extends State<MissionsOverlay>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => widget.game.hideMissions(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'MISSIONS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Progress summary
            ListenableBuilder(
              listenable: MissionManager.instance,
              builder: (context, child) {
                final manager = MissionManager.instance;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        icon: Icons.check_circle,
                        label: 'Completed',
                        value: '${manager.completedCount}/${manager.totalMissions}',
                        color: Colors.green,
                      ),
                      _StatItem(
                        icon: Icons.gamepad,
                        label: 'Games Played',
                        value: '${manager.totalGamesPlayed}',
                        color: Colors.blue,
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Mission list
            Expanded(
              child: ListenableBuilder(
                listenable: MissionManager.instance,
                builder: (context, child) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _MissionList(
                        missions: MissionManager.instance.activeMissions,
                        showProgress: true,
                      ),
                      _MissionList(
                        missions: MissionManager.instance.completedMissionsList,
                        showProgress: false,
                        isCompleted: true,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}

class _MissionList extends StatelessWidget {
  final List<Mission> missions;
  final bool showProgress;
  final bool isCompleted;

  const _MissionList({
    required this.missions,
    this.showProgress = false,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted ? Icons.emoji_events : Icons.assignment,
              size: 64,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              isCompleted
                  ? 'No completed missions yet'
                  : 'All missions completed!',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      );
    }

    // Group missions by tier
    final bronzeMissions =
        missions.where((m) => m.tier == MissionTier.bronze).toList();
    final silverMissions =
        missions.where((m) => m.tier == MissionTier.silver).toList();
    final goldMissions =
        missions.where((m) => m.tier == MissionTier.gold).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (bronzeMissions.isNotEmpty) ...[
          _TierHeader(tier: MissionTier.bronze),
          ...bronzeMissions.map((m) => _MissionCard(
                mission: m,
                showProgress: showProgress,
                isCompleted: isCompleted,
              )),
        ],
        if (silverMissions.isNotEmpty) ...[
          _TierHeader(tier: MissionTier.silver),
          ...silverMissions.map((m) => _MissionCard(
                mission: m,
                showProgress: showProgress,
                isCompleted: isCompleted,
              )),
        ],
        if (goldMissions.isNotEmpty) ...[
          _TierHeader(tier: MissionTier.gold),
          ...goldMissions.map((m) => _MissionCard(
                mission: m,
                showProgress: showProgress,
                isCompleted: isCompleted,
              )),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _TierHeader extends StatelessWidget {
  final MissionTier tier;

  const _TierHeader({required this.tier});

  @override
  Widget build(BuildContext context) {
    String name;
    Color color;
    IconData icon;

    switch (tier) {
      case MissionTier.bronze:
        name = 'BRONZE';
        color = const Color(0xFFCD7F32);
        icon = Icons.military_tech;
        break;
      case MissionTier.silver:
        name = 'SILVER';
        color = const Color(0xFFC0C0C0);
        icon = Icons.military_tech;
        break;
      case MissionTier.gold:
        name = 'GOLD';
        color = const Color(0xFFFFD700);
        icon = Icons.military_tech;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: color.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final Mission mission;
  final bool showProgress;
  final bool isCompleted;

  const _MissionCard({
    required this.mission,
    this.showProgress = false,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = MissionManager.instance.getMissionProgress(mission);
    final currentValue = MissionManager.instance.getCurrentProgress(mission);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.5)
              : mission.tierColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: mission.tierColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted ? Icons.check : mission.icon,
              color: isCompleted ? Colors.green : mission.tierColor,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mission.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                if (showProgress && !isCompleted) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation(mission.tierColor),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$currentValue/${mission.targetValue}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Reward
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCompleted ? Icons.check : Icons.monetization_on,
                  color: isCompleted ? Colors.green : Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  isCompleted ? 'Done' : '+${mission.coinReward}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green : Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
