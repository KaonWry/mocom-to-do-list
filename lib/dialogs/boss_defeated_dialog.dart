import 'package:flutter/material.dart';
import '../models/boss_profile.dart';

Future<void> showBossDefeatedDialog(
  BuildContext context, {
  required BossProfile defeatedBoss,
  required int defeatedLevel,
  required int earnedGold,
  required BossProfile nextBoss,
  required int nextBossLevel,
  required int nextBossMaxHp,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1C202B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.emoji_events, color: Color(0xFFFFB703), size: 30),
          SizedBox(width: 10),
          Text('BOSS DEFEATED!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kamu berhasil menumbangkan Lv.$defeatedLevel ${defeatedBoss.name}!',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB703).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFB703).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFFFB703)),
                const SizedBox(width: 8),
                Text(
                  'Loot Didapat: +$earnedGold Gold',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFB703),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(nextBoss.icon, color: nextBoss.color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Boss berikutnya: Lv.$nextBossLevel ${nextBoss.name} ($nextBossMaxHp HP)',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFB703),
            foregroundColor: Colors.black,
          ),
          child: const Text(
            'Lanjut Bertarung',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
