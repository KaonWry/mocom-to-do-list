import 'package:flutter/material.dart';

import '../models/quest.dart';

class RouletteBanner extends StatelessWidget {
  final Quest? lockedQuest;
  final bool isSpinning;
  final int critRollsUsed;
  final int maxCritRolls;
  final VoidCallback onSpin;

  const RouletteBanner({
    super.key,
    required this.lockedQuest,
    required this.isSpinning,
    required this.critRollsUsed,
    this.maxCritRolls = 2,
    required this.onSpin,
  });

  @override
  Widget build(BuildContext context) {
    final int remainingRolls = (maxCritRolls - critRollsUsed).clamp(
      0,
      maxCritRolls,
    );
    final bool canSpin =
        !isSpinning && lockedQuest == null && remainingRolls > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB703).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFB703).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TARGET ROULETTE (1.5x CRIT) • $remainingRolls/$maxCritRolls Roll',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFB703),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSpinning
                      ? 'Mengacak takdir quest...'
                      : (lockedQuest != null
                            ? lockedQuest!.title
                            : (remainingRolls > 0
                                  ? 'Putar roulette untuk bonus damage!'
                                  : 'Jatah Crit Roll habis untuk Boss ini!')),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: canSpin ? onSpin : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFB703),
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.casino),
            label: Text(isSpinning ? 'Spinning...' : 'Spin'),
          ),
        ],
      ),
    );
  }
}
