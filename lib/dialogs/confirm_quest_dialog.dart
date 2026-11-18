import 'package:flutter/material.dart';
import '../models/quest.dart';

Future<bool?> showConfirmQuestDialog(
  BuildContext context, {
  required Quest quest,
  required String bossName,
  required int previewDamage,
  required int previewXp,
  required bool isCritical,
  required int bonusWeaponDamage,
  required int weaponLevel,
  required bool isRageActive,
  required bool isWisdomActive,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1C202B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.task_alt, color: Color(0xFFFFB703)),
          SizedBox(width: 10),
          Text('Konfirmasi Quest'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Apakah kamu yakin sudah menyelesaikan tugas ini sebelum tenggat waktu?',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF11131A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Total Serangan: -$previewDamage HP ke $bossName',
                  style: const TextStyle(
                    color: Color(0xFFE63946),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '• Hadiah EXP: +$previewXp XP',
                  style: const TextStyle(
                    color: Color(0xFFFFB703),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (isCritical ||
                    bonusWeaponDamage > 0 ||
                    isRageActive ||
                    isWisdomActive) ...[
                  const Divider(height: 16, color: Colors.white12),
                  const Text(
                    'Bonus Aktif:',
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                  if (bonusWeaponDamage > 0)
                    Text(
                      '  + Senjata Lv.$weaponLevel (+$bonusWeaponDamage Base DMG)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.lightBlueAccent,
                      ),
                    ),
                  if (isCritical)
                    const Text(
                      '  + Target Roulette (1.5x CRIT)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFFB703),
                      ),
                    ),
                  if (isRageActive)
                    const Text(
                      '  + Rage Potion (2x DMG)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  if (isWisdomActive)
                    const Text(
                      '  + Wisdom Elixir (2x EXP)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.purpleAccent,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal', style: TextStyle(color: Colors.white54)),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFB703),
            foregroundColor: Colors.black,
          ),
          icon: const Icon(Icons.bolt, size: 18),
          label: const Text(
            'Serang!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
