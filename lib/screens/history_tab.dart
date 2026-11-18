import 'package:flutter/material.dart';

import '../models/quest.dart';
import '../utils/formatters.dart';

class HistoryTab extends StatelessWidget {
  final List<Quest> historyQuests;
  final int totalDamageDealt;
  final VoidCallback onClearHistory;

  const HistoryTab({
    super.key,
    required this.historyQuests,
    required this.totalDamageDealt,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = historyQuests.where((q) => q.isDone).length;
    final failedCount = historyQuests.where((q) => q.isFailed).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C202B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '$completedCount',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                    const Text(
                      'Selesai',
                      style: TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                  ],
                ),
                Container(width: 1, height: 30, color: Colors.white12),
                Column(
                  children: [
                    Text(
                      '$failedCount',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    const Text(
                      'Gagal',
                      style: TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                  ],
                ),
                Container(width: 1, height: 30, color: Colors.white12),
                Column(
                  children: [
                    Text(
                      '$totalDamageDealt',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFB703),
                      ),
                    ),
                    const Text(
                      'Total DMG',
                      style: TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RIWAYAT QUEST',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Colors.white70,
                ),
              ),
              if (historyQuests.isNotEmpty)
                TextButton.icon(
                  onPressed: onClearHistory,
                  icon: const Icon(
                    Icons.delete_sweep,
                    size: 18,
                    color: Colors.white54,
                  ),
                  label: const Text(
                    'Bersihkan',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: historyQuests.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada riwayat quest.\nSelesaikan quest di tab Arena untuk mencatat sejarah!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: historyQuests.length,
                    itemBuilder: (context, index) {
                      final quest = historyQuests[index];
                      final isFailed = quest.isFailed;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(
                            isFailed ? Icons.cancel : Icons.check_circle,
                            color: isFailed
                                ? Colors.redAccent
                                : Colors.greenAccent,
                          ),
                          title: Text(
                            quest.title,
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: isFailed
                                  ? Colors.redAccent.withValues(alpha: 0.85)
                                  : Colors.white70,
                            ),
                          ),
                          subtitle: Text(
                            isFailed
                                ? 'GAGAL (Lewat Tenggat) • Penalti: Reset HP Boss\nWaktu: ${formatDateTime(quest.finishedAt)}'
                                : '${quest.difficulty.label} • -${quest.damageDealt ?? quest.difficulty.damage} DMG\nSelesai: ${formatDateTime(quest.finishedAt)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isFailed
                                  ? Colors.redAccent.withValues(alpha: 0.75)
                                  : Colors.white54,
                            ),
                          ),
                          isThreeLine: true,
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
