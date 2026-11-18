import 'package:flutter/material.dart';

import '../models/quest.dart';

Future<void> showPunishmentDialog(
  BuildContext context, {
  required List<Quest> expiredQuests,
  required String bossName,
  required int bossMaxHp,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1C202B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 30),
          SizedBox(width: 10),
          Text(
            'PUNISHMENT!',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${expiredQuests.length} quest telah melewati tenggat waktu! $bossName memulihkan kekuatannya saat kamu lengah:',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          ...expiredQuests.map(
            (q) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• ${q.title}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'HP $bossName kembali penuh ($bossMaxHp/$bossMaxHp HP)!',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          child: const Text('Terima Hukuman'),
        ),
      ],
    ),
  );
}
