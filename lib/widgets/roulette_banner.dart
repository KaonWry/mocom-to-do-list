import 'package:flutter/material.dart';
import '../models/quest.dart';

class RouletteBanner extends StatelessWidget {
  final Quest? lockedQuest;
  final bool isSpinning;
  final VoidCallback onSpin;

  const RouletteBanner({
    super.key,
    required this.lockedQuest,
    required this.isSpinning,
    required this.onSpin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFB703).withValues(alpha: 0.18),
            const Color(0xFF1C202B),
          ],
        ),
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
                const Text(
                  'TARGET ROULETTE (1.5x CRIT)',
                  style: TextStyle(
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
                            : 'Putar roulette untuk bonus damage!'),
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
            onPressed: isSpinning ? null : onSpin,
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
