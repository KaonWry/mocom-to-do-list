import 'package:flutter/material.dart';
import '../models/boss_profile.dart';
import '../models/quest.dart';
import '../utils/formatters.dart';
import '../widgets/boss_card.dart';
import '../widgets/roulette_banner.dart';

class ArenaTab extends StatelessWidget {
  final BossProfile boss;
  final int bossLevel;
  final int bossCurrentHp;
  final int bossMaxHp;
  final int currentBossGoldReward;
  final int weaponLevel;
  final int bonusWeaponDamage;
  final bool isRageActive;
  final bool isWisdomActive;
  final List<Quest> activeQuests;
  final String? lockedQuestId;
  final String? spinningHighlightId;
  final bool isSpinning;
  final VoidCallback onSpinRoulette;
  final ValueChanged<Quest> onCompleteQuest;
  final ValueChanged<Quest> onDeleteQuest;
  final int Function(Quest) calculateDamage;

  const ArenaTab({
    super.key,
    required this.boss,
    required this.bossLevel,
    required this.bossCurrentHp,
    required this.bossMaxHp,
    required this.currentBossGoldReward,
    required this.weaponLevel,
    required this.bonusWeaponDamage,
    required this.isRageActive,
    required this.isWisdomActive,
    required this.activeQuests,
    required this.lockedQuestId,
    required this.spinningHighlightId,
    required this.isSpinning,
    required this.onSpinRoulette,
    required this.onCompleteQuest,
    required this.onDeleteQuest,
    required this.calculateDamage,
  });

  @override
  Widget build(BuildContext context) {
    final lockedQuest = activeQuests.cast<Quest?>().firstWhere(
          (q) => q?.id == lockedQuestId,
          orElse: () => null,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          BossCard(
            boss: boss,
            bossLevel: bossLevel,
            bossCurrentHp: bossCurrentHp,
            bossMaxHp: bossMaxHp,
            goldReward: currentBossGoldReward,
            weaponLevel: weaponLevel,
            bonusWeaponDamage: bonusWeaponDamage,
            isRageActive: isRageActive,
            isWisdomActive: isWisdomActive,
          ),
          const SizedBox(height: 10),
          RouletteBanner(
            lockedQuest: lockedQuest,
            isSpinning: isSpinning,
            onSpin: onSpinRoulette,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'QUEST AKTIF',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Colors.white70,
                ),
              ),
              Text(
                '${activeQuests.length} Tersisa',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: activeQuests.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada quest aktif.\nCek tab History atau tekan + Quest Baru.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: activeQuests.length,
                    itemBuilder: (context, index) {
                      final quest = activeQuests[index];
                      final isLockedTarget = quest.id == lockedQuestId;
                      final isHighlighted = quest.id == spinningHighlightId;
                      final calculatedDmg = calculateDamage(quest);
                      final remaining = quest.deadline.difference(
                        DateTime.now(),
                      );
                      final isUrgent = remaining.inMinutes < 10;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? const Color(0xFFFFB703).withValues(alpha: 0.25)
                              : const Color(0xFF1C202B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isLockedTarget || isHighlighted
                                ? const Color(0xFFFFB703)
                                : (isUrgent
                                      ? Colors.redAccent.withValues(alpha: 0.6)
                                      : Colors.transparent),
                            width: 1.8,
                          ),
                        ),
                        child: ListTile(
                          leading: IconButton(
                            icon: Icon(
                              Icons.radio_button_unchecked,
                              color: isLockedTarget
                                  ? const Color(0xFFFFB703)
                                  : Colors.white54,
                            ),
                            onPressed: () => onCompleteQuest(quest),
                          ),
                          title: Text(
                            quest.title,
                            style: TextStyle(
                              fontWeight: isLockedTarget
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    quest.difficulty.icon,
                                    size: 13,
                                    color: quest.difficulty.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${quest.difficulty.label} • $calculatedDmg DMG',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isLockedTarget
                                          ? const Color(0xFFFFB703)
                                          : quest.difficulty.color,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 13,
                                    color: isUrgent
                                        ? Colors.redAccent
                                        : Colors.white54,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tenggat: ${formatRemainingTime(quest.deadline)} (Penalti -${quest.difficulty.penaltyGold}G)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isUrgent
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isUrgent
                                          ? Colors.redAccent
                                          : Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.white38,
                            ),
                            onPressed: () => onDeleteQuest(quest),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
