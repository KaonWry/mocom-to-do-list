import 'dart:async';
import 'dart:math';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const QuestRouletteApp());
}

class QuestRouletteApp extends StatelessWidget {
  const QuestRouletteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quest Roulette',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF11131A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFB703),
          secondary: Color(0xFFE63946),
          surface: Color(0xFF1C202B),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1C202B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const QuestBoardScreen(),
    );
  }
}

enum QuestDifficulty {
  easy('Easy (Goblin)', 15, 10, Color(0xFF4CAF50), Icons.shield_outlined),
  medium('Medium (Orc)', 30, 25, Color(0xFFFF9800), Icons.local_fire_department),
  hard('Hard (Dragon)', 50, 50, Color(0xFFE63946), Icons.whatshot);

  final String label;
  final int damage;
  final int xp;
  final Color color;
  final IconData icon;

  const QuestDifficulty(
    this.label,
    this.damage,
    this.xp,
    this.color,
    this.icon,
  );
}

class Quest {
  final String id;
  final String title;
  final QuestDifficulty difficulty;
  bool isDone;

  Quest({
    required this.id,
    required this.title,
    required this.difficulty,
    this.isDone = false,
  });
}

class QuestBoardScreen extends StatefulWidget {
  const QuestBoardScreen({super.key});

  @override
  State<QuestBoardScreen> createState() => _QuestBoardScreenState();
}

class _QuestBoardScreenState extends State<QuestBoardScreen> {
  final List<Quest> _quests = [
    Quest(
      id: '1',
      title: 'Rapikan catatan kuliah hari ini',
      difficulty: QuestDifficulty.easy,
    ),
    Quest(
      id: '2',
      title: 'Kerjakan UI aplikasi To-Do List',
      difficulty: QuestDifficulty.medium,
    ),
    Quest(
      id: '3',
      title: 'Selesaikan laporan praktikum',
      difficulty: QuestDifficulty.hard,
    ),
  ];

  // State RPG Boss & Player
  int _bossLevel = 1;
  int _bossMaxHp = 100;
  int _bossCurrentHp = 100;
  int _playerLevel = 1;
  int _playerXp = 0;

  final List<String> _bossTitles = [
    'Slime Raja Wacana',
    'Golem Penunda Waktu',
    'Ksatria Kantuk Berat',
    'Naga Revisi Mendadak',
    'Overlord Deadline',
  ];

  // State Roulette
  String? _lockedQuestId;
  String? _spinningHighlightId;
  bool _isSpinning = false;
  Timer? _spinTimer;
  final Random _random = Random();

  @override
  void dispose() {
    _spinTimer?.cancel();
    super.dispose();
  }

  String get _currentBossName =>
      _bossTitles[(_bossLevel - 1) % _bossTitles.length];

  int get _xpToNextLevel => _playerLevel * 100;

  void _spinRoulette() {
    final activeQuests = _quests.where((q) => !q.isDone).toList();

    if (activeQuests.isEmpty) {
      _showFeedback('Semua quest selesai! Tambahkan quest baru terlebih dahulu.');
      return;
    }

    if (activeQuests.length == 1) {
      setState(() {
        _lockedQuestId = activeQuests.first.id;
      });
      _showFeedback('Target dikunci: "${activeQuests.first.title}" (1.5x CRIT!)');
      return;
    }

    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _lockedQuestId = null;
    });

    int ticks = 0;
    const maxTicks = 18;

    _spinTimer = Timer.periodic(const Duration(milliseconds: 85), (timer) {
      ticks++;
      final randomQuest = activeQuests[_random.nextInt(activeQuests.length)];

      setState(() {
        _spinningHighlightId = randomQuest.id;
      });

      if (ticks >= maxTicks) {
        timer.cancel();
        setState(() {
          _isSpinning = false;
          _lockedQuestId = randomQuest.id;
          _spinningHighlightId = null;
        });
        _showFeedback(
          'ROULETTE LOCKED: "${randomQuest.title}" (1.5x CRITICAL DMG!)',
        );
      }
    });
  }

  void _completeQuest(Quest quest) {
    if (quest.isDone || _isSpinning) return;

    final bool isCritical = quest.id == _lockedQuestId;
    final int finalDamage = isCritical
        ? (quest.difficulty.damage * 1.5).round()
        : quest.difficulty.damage;
    final int gainedXp = isCritical
        ? (quest.difficulty.xp * 1.5).round()
        : quest.difficulty.xp;

    setState(() {
      quest.isDone = true;
      if (isCritical) {
        _lockedQuestId = null;
      }

      // Tambah XP & Cek Level Up Player
      _playerXp += gainedXp;
      while (_playerXp >= _xpToNextLevel) {
        _playerXp -= _xpToNextLevel;
        _playerLevel++;
      }

      // Kurangi HP Boss
      _bossCurrentHp = max(0, _bossCurrentHp - finalDamage);
    });

    if (_bossCurrentHp == 0) {
      _handleBossDefeated();
    } else {
      _showFeedback(
        isCritical
            ? 'CRITICAL HIT! -$finalDamage DMG ke Boss (+$gainedXp XP)'
            : 'Serangan berhasil! -$finalDamage DMG ke Boss (+$gainedXp XP)',
      );
    }
  }

  void _handleBossDefeated() {
    final defeatedBossName = _currentBossName;
    final defeatedLevel = _bossLevel;

    setState(() {
      _bossLevel++;
      _bossMaxHp = 100 + (_bossLevel - 1) * 40;
      _bossCurrentHp = _bossMaxHp;
    });

    showDialog(
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
        content: Text(
          'Selamat! Kamu berhasil mengalahkan Lv.$defeatedLevel $defeatedBossName.\n\n'
          'Boss berikutnya (Lv.$_bossLevel $_currentBossName) telah muncul dengan $_bossMaxHp HP!',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Lanjut Bertarung'),
          ),
        ],
      ),
    );
  }

  void _showAddQuestSheet() {
    final titleController = TextEditingController();
    QuestDifficulty selectedDifficulty = QuestDifficulty.medium;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C202B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tambah Quest Baru',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
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
                  const SizedBox(height: 16),
                  const Text(
                    'Tingkat Kesulitan (Damage ke Boss):',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: QuestDifficulty.values.map((diff) {
                      final isSelected = selectedDifficulty == diff;
                      return ChoiceChip(
                        label: Text('${diff.label} (${diff.damage} DMG)'),
                        selected: isSelected,
                        selectedColor: diff.color.withValues(alpha: 0.25),
                        labelStyle: TextStyle(
                          color: isSelected ? diff.color : Colors.white70,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) {
                          setModalState(() {
                            selectedDifficulty = diff;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        final text = titleController.text.trim();
                        if (text.isEmpty) return;

                        setState(() {
                          _quests.insert(
                            0,
                            Quest(
                              id: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                              title: text,
                              difficulty: selectedDifficulty,
                            ),
                          );
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.add_task),
                      label: const Text('Simpan Quest'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    final hpRatio = _bossCurrentHp / _bossMaxHp;
    final lockedQuest = _quests.cast<Quest?>().firstWhere(
          (q) => q?.id == _lockedQuestId && !(q?.isDone ?? true),
          orElse: () => null,
        );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'QUEST ROULETTE',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB703).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFB703).withValues(alpha: 0.5),
              ),
            ),
            child: Center(
              child: Text(
                'Hero Lv.$_playerLevel • $_playerXp/$_xpToNextLevel XP',
                style: const TextStyle(
                  color: Color(0xFFFFB703),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // 1. BOSS ARENA CARD
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFE63946).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.bug_report_rounded,
                            color: Color(0xFFE63946),
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BOSS LV.$_bossLevel',
                                style: const TextStyle(
                                  color: Color(0xFFE63946),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                _currentBossName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$_bossCurrentHp / $_bossMaxHp HP',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFE63946),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 2. ROULETTE ACTION PANEL
            Container(
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
                          _isSpinning
                              ? 'Mengacak takdir quest...'
                              : (lockedQuest != null
                                  ? lockedQuest.title
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
                    onPressed: _isSpinning ? null : _spinRoulette,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB703),
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.casino),
                    label: Text(_isSpinning ? 'Spinning...' : 'Spin'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. QUEST LIST HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'QUEST LOG',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  '${_quests.where((q) => !q.isDone).length} Aktif',
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 4. QUEST LIST
            Expanded(
              child: _quests.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada quest.\nTekan tombol + untuk mulai berpetualang!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _quests.length,
                      itemBuilder: (context, index) {
                        final quest = _quests[index];
                        final isLockedTarget =
                            quest.id == _lockedQuestId && !quest.isDone;
                        final isHighlighted = quest.id == _spinningHighlightId;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isHighlighted
                                ? const Color(0xFFFFB703)
                                    .withValues(alpha: 0.25)
                                : const Color(0xFF1C202B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isLockedTarget || isHighlighted
                                  ? const Color(0xFFFFB703)
                                  : Colors.transparent,
                              width: 1.8,
                            ),
                          ),
                          child: ListTile(
                            leading: IconButton(
                              icon: Icon(
                                quest.isDone
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: quest.isDone
                                    ? Colors.greenAccent
                                    : (isLockedTarget
                                        ? const Color(0xFFFFB703)
                                        : Colors.white54),
                              ),
                              onPressed: () => _completeQuest(quest),
                            ),
                            title: Text(
                              quest.title,
                              style: TextStyle(
                                decoration: quest.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: quest.isDone
                                    ? Colors.white38
                                    : Colors.white,
                                fontWeight: isLockedTarget
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Icon(
                                  quest.difficulty.icon,
                                  size: 14,
                                  color: quest.difficulty.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${quest.difficulty.label} • ${isLockedTarget ? "${(quest.difficulty.damage * 1.5).round()} CRIT DMG" : "${quest.difficulty.damage} DMG"}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isLockedTarget
                                        ? const Color(0xFFFFB703)
                                        : quest.difficulty.color,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.white38,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (_lockedQuestId == quest.id) {
                                    _lockedQuestId = null;
                                  }
                                  _quests.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddQuestSheet,
        backgroundColor: const Color(0xFFFFB703),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Quest Baru',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}