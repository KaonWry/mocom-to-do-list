import 'package:flutter/material.dart';
import '../models/quest.dart';
import '../utils/formatters.dart';

Future<Quest?> showAddQuestDialog(BuildContext context) {
  return showDialog<Quest>(
    context: context,
    builder: (context) => const AddQuestDialog(),
  );
}

class AddQuestDialog extends StatefulWidget {
  const AddQuestDialog({super.key});

  @override
  State<AddQuestDialog> createState() => _AddQuestDialogState();
}

class _AddQuestDialogState extends State<AddQuestDialog> {
  final TextEditingController _titleController = TextEditingController();
  QuestDifficulty _selectedDifficulty = QuestDifficulty.medium;
  DateTime _selectedDeadline = DateTime.now().add(const Duration(hours: 3));

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickCustomDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline.isAfter(now) ? _selectedDeadline : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDeadline),
    );
    if (pickedTime == null || !mounted) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (combined.isBefore(DateTime.now())) {
      _showFeedback('Tenggat waktu tidak boleh di masa lalu!');
      return;
    }

    setState(() {
      _selectedDeadline = combined;
    });
  }

  void _saveQuest() {
    final text = _titleController.text.trim();
    if (text.isEmpty) return;

    final quest = Quest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: text,
      difficulty: _selectedDifficulty,
      deadline: _selectedDeadline,
    );
    Navigator.pop(context, quest);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1C202B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.add_task,
                        color: Color(0xFFFFB703),
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Tambah Quest Baru',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: Colors.white54,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _titleController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Contoh: Selesaikan bab 2 skripsi...',
                          filled: true,
                          fillColor: const Color(0xFF11131A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Tingkat Kesulitan (Damage vs Punishment):',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: QuestDifficulty.values.map((diff) {
                          final isSelected = _selectedDifficulty == diff;
                          return ChoiceChip(
                            label: Text(
                              '${diff.label} (${diff.damage} DMG | -${diff.penaltyGold}G)',
                            ),
                            selected: isSelected,
                            selectedColor: diff.color.withValues(alpha: 0.25),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: isSelected ? diff.color : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (_) {
                              setState(() {
                                _selectedDifficulty = diff;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Tenggat Waktu (Deadline):',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            avatar: const Icon(
                              Icons.timer,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              '+1 Menit (Demo)',
                              style: TextStyle(fontSize: 12),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedDeadline = DateTime.now().add(
                                  const Duration(minutes: 1),
                                );
                              });
                            },
                          ),
                          ActionChip(
                            label: const Text(
                              '+1 Jam',
                              style: TextStyle(fontSize: 12),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedDeadline = DateTime.now().add(
                                  const Duration(hours: 1),
                                );
                              });
                            },
                          ),
                          ActionChip(
                            label: const Text(
                              '+3 Jam',
                              style: TextStyle(fontSize: 12),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedDeadline = DateTime.now().add(
                                  const Duration(hours: 3),
                                );
                              });
                            },
                          ),
                          ActionChip(
                            label: const Text(
                              'Besok',
                              style: TextStyle(fontSize: 12),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedDeadline = DateTime.now().add(
                                  const Duration(days: 1),
                                );
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _pickCustomDateTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF11131A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFFFFB703,
                              ).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.event_available,
                                color: Color(0xFFFFB703),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Batas: ${formatDateTime(_selectedDeadline)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const Text(
                                'Ubah',
                                style: TextStyle(
                                  color: Color(0xFFFFB703),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white60,
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _saveQuest,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB703),
                        foregroundColor: Colors.black,
                      ),
                      icon: const Icon(Icons.add_task),
                      label: const Text(
                        'Simpan Quest',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
