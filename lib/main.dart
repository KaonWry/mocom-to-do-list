import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const QuestRouletteApp());
}

class QuestRouletteApp extends StatelessWidget {
  const QuestRouletteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quest Roulette RPG',
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
      home: const MainGameShell(),
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
  DateTime? completedAt;
  int? damageDealt;

  Quest({
    required this.id,
    required this.title,
    required this.difficulty,
    this.isDone = false,
    this.completedAt,
    this.damageDealt,
  });
}

class MainGameShell extends StatefulWidget {
  const MainGameShell({super.key});

  @override
  State<MainGameShell> createState() => _MainGameShellState();
}

class _MainGameShellState extends State<MainGameShell> {
  int _selectedTabIndex = 0;

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
  int _gold = 30; // Modal awal sedikit agar bisa langsung eksplorasi

  // State Equipment & Support Buffs
  int _weaponLevel = 0;
  int _bonusWeaponDamage = 0;
  bool _isRageActive = false; // 2x Damage pada quest berikutnya
  bool _isWisdomActive = false; // 2x EXP pada quest berikutnya

  final List<String> _bossTitles = [
    'Slime King',
    'Time Golem',
    'Dark Knight',
    'Dragonlord',
    'Overlord of Shadows',
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

  int get _currentBossGoldReward => 50 + (_bossLevel * 25);

  int get _weaponUpgradeCost => 50 + (_weaponLevel * 35);

  int _calculateDamage(Quest quest) {
    final bool isCritical = quest.id == _lockedQuestId;
    final int baseDamage = quest.difficulty.damage + _bonusWeaponDamage;
    final double critMultiplier = isCritical ? 1.5 : 1.0;
    final double rageMultiplier = _isRageActive ? 2.0 : 1.0;
    return (baseDamage * critMultiplier * rageMultiplier).round();
  }

  int _calculateXp(Quest quest) {
    final bool isCritical = quest.id == _lockedQuestId;
    final double critMultiplier = isCritical ? 1.5 : 1.0;
    final double wisdomMultiplier = _isWisdomActive ? 2.0 : 1.0;
    return (quest.difficulty.xp * critMultiplier * wisdomMultiplier).round();
  }

  void _spinRoulette() {
    final activeQuests = _quests.where((q) => !q.isDone).toList();

    if (activeQuests.isEmpty) {
      _showFeedback('Semua quest aktif selesai! Tambahkan quest baru dulu.');
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

  // Konfirmasi sebelum menyelesaikan tugas
  void _confirmCompleteQuest(Quest quest) {
    if (quest.isDone || _isSpinning) return;

    final bool isCritical = quest.id == _lockedQuestId;
    final int previewDamage = _calculateDamage(quest);
    final int previewXp = _calculateXp(quest);

    showDialog(
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
              'Apakah kamu yakin sudah menyelesaikan tugas ini?',
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
                    '• Total Serangan: -$previewDamage HP ke Boss',
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
                      _bonusWeaponDamage > 0 ||
                      _isRageActive ||
                      _isWisdomActive) ...[
                    const Divider(height: 16, color: Colors.white12),
                    const Text(
                      'Bonus Aktif:',
                      style: TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                    if (_bonusWeaponDamage > 0)
                      Text(
                        '  + Senjata Lv.$_weaponLevel (+$_bonusWeaponDamage Base DMG)',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.lightBlueAccent),
                      ),
                    if (isCritical)
                      const Text(
                        '  + Target Roulette (1.5x CRIT)',
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFFFFB703)),
                      ),
                    if (_isRageActive)
                      const Text(
                        '  + Rage Potion (2x DMG)',
                        style:
                            TextStyle(fontSize: 11, color: Colors.orangeAccent),
                      ),
                    if (_isWisdomActive)
                      const Text(
                        '  + Wisdom Elixir (2x EXP)',
                        style:
                            TextStyle(fontSize: 11, color: Colors.purpleAccent),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _executeQuestCompletion(quest);
            },
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

  void _executeQuestCompletion(Quest quest) {
    final bool isCritical = quest.id == _lockedQuestId;
    final int finalDamage = _calculateDamage(quest);
    final int gainedXp = _calculateXp(quest);

    setState(() {
      quest.isDone = true;
      quest.completedAt = DateTime.now();
      quest.damageDealt = finalDamage;

      if (isCritical) {
        _lockedQuestId = null;
      }

      // Konsumsi buff sekali pakai
      _isRageActive = false;
      _isWisdomActive = false;

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
    final earnedGold = _currentBossGoldReward;

    setState(() {
      _gold += earnedGold;
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kamu berhasil menumbangkan Lv.$defeatedLevel $defeatedBossName!',
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
            Text(
              'Boss baru Lv.$_bossLevel $_currentBossName telah muncul dengan $_bossMaxHp HP!',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
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

  // Logika Pembelian Item di Shop
  void _buyWeaponUpgrade() {
    final cost = _weaponUpgradeCost;
    if (_gold < cost) {
      _showFeedback('Gold tidak cukup! Kalahkan Boss untuk mendapat Gold.');
      return;
    }

    setState(() {
      _gold -= cost;
      _weaponLevel++;
      _bonusWeaponDamage += 5;
    });
    _showFeedback(
      'Senjata ditingkatkan ke Lv.$_weaponLevel (+$_bonusWeaponDamage Base DMG)!',
    );
  }

  void _buyRagePotion() {
    const cost = 40;
    if (_isRageActive) {
      _showFeedback('Rage Potion sudah aktif untuk quest berikutnya!');
      return;
    }
    if (_gold < cost) {
      _showFeedback('Gold tidak cukup (Butuh $cost Gold).');
      return;
    }

    setState(() {
      _gold -= cost;
      _isRageActive = true;
    });
    _showFeedback('Rage Potion aktif! Quest berikutnya menghasilkan 2x DMG.');
  }

  void _buyWisdomElixir() {
    const cost = 35;
    if (_isWisdomActive) {
      _showFeedback('Wisdom Elixir sudah aktif untuk quest berikutnya!');
      return;
    }
    if (_gold < cost) {
      _showFeedback('Gold tidak cukup (Butuh $cost Gold).');
      return;
    }

    setState(() {
      _gold -= cost;
      _isWisdomActive = true;
    });
    _showFeedback('Wisdom Elixir aktif! Quest berikutnya memberi 2x EXP.');
  }

  void _buyMeteorScroll() {
    const cost = 65;
    const scrollDamage = 50;
    if (_gold < cost) {
      _showFeedback('Gold tidak cukup (Butuh $cost Gold).');
      return;
    }

    setState(() {
      _gold -= cost;
      _bossCurrentHp = max(0, _bossCurrentHp - scrollDamage);
    });

    if (_bossCurrentHp == 0) {
      _handleBossDefeated();
    } else {
      _showFeedback('METEOR STRIKE! -$scrollDamage HP langsung ke Boss!');
    }
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
                    'Tingkat Kesulitan (Base Damage):',
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

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$hour:$minute • $day/$month/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final activeQuests = _quests.where((q) => !q.isDone).toList();
    final completedQuests = _quests.where((q) => q.isDone).toList()
      ..sort((a, b) => (b.completedAt ?? DateTime.now())
          .compareTo(a.completedAt ?? DateTime.now()));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'QUEST ROULETTE',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1),
        ),
        actions: [
          // Badge Gold
          Container(
            margin: const EdgeInsets.only(right: 8, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on,
                    size: 15, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '$_gold G',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Badge Level & XP
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.lightBlueAccent.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(
                'Lv.$_playerLevel ($_playerXp/$_xpToNextLevel)',
                style: const TextStyle(
                  color: Colors.lightBlueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          _buildArenaTab(activeQuests),
          _buildShopTab(),
          _buildHistoryTab(completedQuests),
        ],
      ),
      floatingActionButton: _selectedTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddQuestSheet,
              backgroundColor: const Color(0xFFFFB703),
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add),
              label: const Text(
                'Quest Baru',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1C202B),
        indicatorColor: const Color(0xFFFFB703).withValues(alpha: 0.25),
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.sports_kabaddi_outlined),
            selectedIcon: Icon(Icons.sports_kabaddi, color: Color(0xFFFFB703)),
            label: 'Arena',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: Color(0xFFFFB703)),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: completedQuests.isNotEmpty,
              label: Text('${completedQuests.length}'),
              child: const Icon(Icons.history_outlined),
            ),
            selectedIcon:
                const Icon(Icons.history, color: Color(0xFFFFB703)),
            label: 'History',
          ),
        ],
      ),
    );
  }

  // ==================== TAB 1: ARENA & QUESTS ====================
  Widget _buildArenaTab(List<Quest> activeQuests) {
    final hpRatio = _bossCurrentHp / _bossMaxHp;
    final lockedQuest = activeQuests.cast<Quest?>().firstWhere(
          (q) => q?.id == _lockedQuestId,
          orElse: () => null,
        );

    return Padding(
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
                            Row(
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
                                const SizedBox(width: 8),
                                Text(
                                  '• Loot: $_currentBossGoldReward G',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
                        '$_bossCurrentHp / $_bossMaxHp',
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
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFE63946),
                          ),
                        );
                      },
                    ),
                  ),
                  // Status Buff Aktif (jika ada)
                  if (_bonusWeaponDamage > 0 ||
                      _isRageActive ||
                      _isWisdomActive) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (_bonusWeaponDamage > 0)
                            _buildStatusBadge(
                              'Pedang Lv.$_weaponLevel (+$_bonusWeaponDamage DMG)',
                              Colors.lightBlueAccent,
                            ),
                          if (_isRageActive)
                            _buildStatusBadge(
                              'Rage 2x DMG',
                              Colors.orangeAccent,
                            ),
                          if (_isWisdomActive)
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
          ),

          const SizedBox(height: 10),

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

          const SizedBox(height: 14),

          // 3. QUEST LIST HEADER
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

          // 4. ACTIVE QUEST LIST
          Expanded(
            child: activeQuests.isEmpty
                ? const Center(
                    child: Text(
                      'Semua quest aktif sudah selesai!\nCek tab History atau tekan + Quest Baru.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: activeQuests.length,
                    itemBuilder: (context, index) {
                      final quest = activeQuests[index];
                      final isLockedTarget = quest.id == _lockedQuestId;
                      final isHighlighted = quest.id == _spinningHighlightId;
                      final calculatedDmg = _calculateDamage(quest);

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
                                : Colors.transparent,
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
                            onPressed: () => _confirmCompleteQuest(quest),
                          ),
                          title: Text(
                            quest.title,
                            style: TextStyle(
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
                                _quests.removeWhere((q) => q.id == quest.id);
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
    );
  }

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

  // ==================== TAB 2: ITEM SHOP ====================
  Widget _buildShopTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C202B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.storefront, color: Colors.amber, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ADVENTURER SHOP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Kalahkan Boss untuk mengumpulkan Gold dan perkuat seranganmu!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'UPGRADE PERMANEN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 8),
        _buildShopItemCard(
          icon: Icons.hardware,
          iconColor: Colors.lightBlueAccent,
          title: 'Asah Pedang (Lv.$_weaponLevel → Lv.${_weaponLevel + 1})',
          description:
              'Menambah +5 Base Damage secara permanen untuk setiap quest. (Saat ini: +$_bonusWeaponDamage DMG)',
          price: _weaponUpgradeCost,
          buttonLabel: 'Upgrade',
          onBuy: _buyWeaponUpgrade,
        ),
        const SizedBox(height: 16),
        const Text(
          'ITEM SUPPORT & SIHIR (SEKALI PAKAI)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 8),
        _buildShopItemCard(
          icon: Icons.local_fire_department,
          iconColor: Colors.orangeAccent,
          title: 'Rage Potion (2x Damage)',
          description:
              'Menggandakan total damage pada 1 quest berikutnya. Bisa ditumpuk dengan Crit Roulette!',
          price: 40,
          buttonLabel: _isRageActive ? 'Aktif' : 'Beli',
          isDisabled: _isRageActive,
          onBuy: _buyRagePotion,
        ),
        const SizedBox(height: 10),
        _buildShopItemCard(
          icon: Icons.auto_awesome,
          iconColor: Colors.purpleAccent,
          title: 'Wisdom Elixir (2x EXP)',
          description:
              'Menggandakan perolehan EXP pada 1 quest berikutnya agar Hero lebih cepat naik level.',
          price: 35,
          buttonLabel: _isWisdomActive ? 'Aktif' : 'Beli',
          isDisabled: _isWisdomActive,
          onBuy: _buyWisdomElixir,
        ),
        const SizedBox(height: 10),
        _buildShopItemCard(
          icon: Icons.flash_on,
          iconColor: const Color(0xFFE63946),
          title: 'Meteor Scroll (-50 HP Boss)',
          description:
              'Menyerang Boss secara instan sebesar 50 HP tanpa harus menyelesaikan quest.',
          price: 65,
          buttonLabel: 'Gunakan',
          onBuy: _buyMeteorScroll,
        ),
      ],
    );
  }

  Widget _buildShopItemCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required int price,
    required String buttonLabel,
    required VoidCallback onBuy,
    bool isDisabled = false,
  }) {
    final canAfford = _gold >= price;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$price Gold',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: canAfford ? Colors.amber : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: isDisabled ? null : onBuy,
              style: FilledButton.styleFrom(
                backgroundColor:
                    canAfford ? const Color(0xFFFFB703) : Colors.white12,
                foregroundColor: canAfford ? Colors.black : Colors.white54,
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 3: QUEST HISTORY ====================
  Widget _buildHistoryTab(List<Quest> completedQuests) {
    final totalDamageDealt = completedQuests.fold<int>(
      0,
      (sum, item) => sum + (item.damageDealt ?? item.difficulty.damage),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Ringkasan Statistik History
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
                      '${completedQuests.length}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                    const Text(
                      'Quest Selesai',
                      style: TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                  ],
                ),
                Container(width: 1, height: 32, color: Colors.white12),
                Column(
                  children: [
                    Text(
                      '$totalDamageDealt',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE63946),
                      ),
                    ),
                    const Text(
                      'Total Damage',
                      style: TextStyle(fontSize: 12, color: Colors.white60),
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
                'RIWAYAT QUEST SELESAI',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Colors.white70,
                ),
              ),
              if (completedQuests.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _quests.removeWhere((q) => q.isDone);
                    });
                    _showFeedback('Riwayat quest dibersihkan.');
                  },
                  icon: const Icon(Icons.delete_sweep,
                      size: 18, color: Colors.white54),
                  label: const Text(
                    'Bersihkan',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: completedQuests.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada quest yang diselesaikan.\nSelesaikan quest di tab Arena untuk mencatat sejarah!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: completedQuests.length,
                    itemBuilder: (context, index) {
                      final quest = completedQuests[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(
                            Icons.check_circle,
                            color: Colors.greenAccent,
                          ),
                          title: Text(
                            quest.title,
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.white70,
                            ),
                          ),
                          subtitle: Text(
                            '${quest.difficulty.label} • -${quest.damageDealt ?? quest.difficulty.damage} DMG\nSelesai: ${_formatDateTime(quest.completedAt)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white54,
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