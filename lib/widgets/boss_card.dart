import 'package:flutter/material.dart';
import '../models/boss_profile.dart';

class BossCard extends StatelessWidget {
  final BossProfile boss;
  final int bossLevel;
  final int bossCurrentHp;
  final int bossMaxHp;
  final int goldReward;
  final int weaponLevel;
  final int bonusWeaponDamage;
  final bool isRageActive;
  final bool isWisdomActive;

  const BossCard({
    super.key,
    required this.boss,
    required this.bossLevel,
    required this.bossCurrentHp,
    required this.bossMaxHp,
    required this.goldReward,
    required this.weaponLevel,
    required this.bonusWeaponDamage,
    required this.isRageActive,
    required this.isWisdomActive,
  });

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hpRatio = bossCurrentHp / bossMaxHp;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: boss.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: boss.color.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Icon(
                    boss.icon,
                    color: boss.color,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'BOSS LV.$bossLevel',
                            style: TextStyle(
                              color: boss.color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• Loot: $goldReward G',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        boss.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$bossCurrentHp / $bossMaxHp',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: hpRatio, end: hpRatio),
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 12,
                    backgroundColor: const Color(0xFF11131A),
                    valueColor: AlwaysStoppedAnimation<Color>(boss.color),
                  );
                },
              ),
            ),
            if (bonusWeaponDamage > 0 || isRageActive || isWisdomActive) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (bonusWeaponDamage > 0)
                      _buildStatusBadge(
                        'Pedang Lv.$weaponLevel (+$bonusWeaponDamage DMG)',
                        Colors.lightBlueAccent,
                      ),
                    if (isRageActive)
                      _buildStatusBadge(
                        'Rage 2x DMG',
                        Colors.orangeAccent,
                      ),
                    if (isWisdomActive)
                      _buildStatusBadge(
                        'Wisdom 2x EXP',
                        Colors.purpleAccent,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
