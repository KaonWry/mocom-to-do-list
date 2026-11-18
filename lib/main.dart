import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'models/quest.dart';
import 'services/storage_service.dart';
export 'models/quest.dart';
export 'services/storage_service.dart';

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

class BossProfile {
  final String name;
  final IconData icon;
  final Color color;

  const BossProfile({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class MainGameShell extends StatefulWidget {
  const MainGameShell({super.key});

  @override
  State<MainGameShell> createState() => _MainGameShellState();
}

class _MainGameShellState extends State<MainGameShell> {
  final StorageService _storageService = StorageService();
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  List<Quest> _quests = [];

  // 5 Boss
  final List<BossProfile> _bossRoster = const [
    BossProfile(
      name: 'Slime King',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF2EC4B6),
    ),
    BossProfile(
      name: 'Time Golem',
      icon: Icons.hourglass_bottom_rounded,
      color: Color(0xFFFF9F1C),
    ),
    BossProfile(
      name: 'Dark Knight',
      icon: Icons.shield_rounded,
      color: Color(0xFF5E60CE),
    ),
    BossProfile(
      name: 'Dragon Lord',
      icon: Icons.whatshot_rounded,
      color: Color(0xFFE63946),
    ),
    BossProfile(
      name: 'Overworld of Shadows',
      icon: Icons.nights_stay_rounded,
      color: Color(0xFFB5179E),
    ),
  ];

  // State RPG Boss & Player
  int _bossLevel = 1;
  int _bossMaxHp = 100;
  int _bossCurrentHp = 100;
  int _playerLevel = 1;
  int _playerXp = 0;
  int _gold = 50; 

  // State Equipment & Support Buffs
  int _weaponLevel = 0;
  int _bonusWeaponDamage = 0;
  bool _isRageActive = false;
  bool _isWisdomActive = false;

  // State Roulette & Deadline Checker
  String? _lockedQuestId;
  String? _spinningHighlightId;
  bool _isSpinning = false;
  Timer? _spinTimer;
  Timer? _deadlineTicker;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadSavedData();

    // Timer setiap 1 detik untuk menghitung mundur deadline & cek punishment
    _deadlineTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkDeadlines();
    });
  }

  Future<void> _loadSavedData() async {
    final loadedQuests = await _storageService.loadQuests();
    final loadedState = await _storageService.loadGameState();

    if (!mounted) return;
    setState(() {
      _quests = loadedQuests;
      _playerLevel = loadedState.playerLevel;
      _playerXp = loadedState.playerXp;
      _gold = loadedState.gold;
      _bossLevel = loadedState.bossLevel;
      _bossCurrentHp = loadedState.bossCurrentHp;
      _bossMaxHp = loadedState.bossMaxHp;
      _weaponLevel = loadedState.weaponLevel;
      _bonusWeaponDamage = loadedState.bonusWeaponDamage;
      _isRageActive = loadedState.isRageActive;
      _isWisdomActive = loadedState.isWisdomActive;
      _lockedQuestId = loadedState.lockedQuestId;
      _isLoading = false;
    });
  }

  void _saveQuests() {
    if (_isLoading) return;
    _storageService.saveQuests(_quests);
  }

  void _saveGameState() {
    if (_isLoading) return;
    _storageService.saveGameState(
      GameStateData(
        playerLevel: _playerLevel,
        playerXp: _playerXp,
        gold: _gold,
        bossLevel: _bossLevel,
        bossCurrentHp: _bossCurrentHp,
        bossMaxHp: _bossMaxHp,
        weaponLevel: _weaponLevel,
        bonusWeaponDamage: _bonusWeaponDamage,
        isRageActive: _isRageActive,
        isWisdomActive: _isWisdomActive,
        lockedQuestId: _lockedQuestId,
      ),
    );
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    _deadlineTicker?.cancel();
    super.dispose();
  }

  BossProfile get _currentBoss =>
      _bossRoster[(_bossLevel - 1) % _bossRoster.length];

  int get _xpToNextLevel => _playerLevel * 100;

  int get _currentBossGoldReward => 50 + (_bossLevel * 25);

  int get _weaponUpgradeCost => 50 + (_weaponLevel * 35);

  void _checkDeadlines() {
    if (_isLoading) return;
    final now = DateTime.now();
    final expiredQuests = _quests
        .where((q) => q.isActive && now.isAfter(q.deadline))
        .toList();

    if (expiredQuests.isEmpty) {
      // Setstate perbaruin detik waktu tenggat
      if (_quests.any((q) => q.isActive) && mounted) {
        setState(() {});
      }
      return;
    }

    int totalPenalty = 0;
    for (final quest in expiredQuests) {
      quest.isFailed = true;
      quest.finishedAt = now;
      quest.goldLost = quest.difficulty.penaltyGold;
      totalPenalty += quest.difficulty.penaltyGold;

      if (_lockedQuestId == quest.id) {
        _lockedQuestId = null;
      }
    }

    final int actualGoldDeducted = min(_gold, totalPenalty);

    setState(() {
      _gold = max(0, _gold - totalPenalty);
    });
    _saveQuests();
    _saveGameState();

    if (!mounted) return;

    showDialog(
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
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${expiredQuests.length} quest telah melewati tenggat waktu! ${_currentBoss.name} menyerang balik saat kamu lengah:',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            ...expiredQuests.map(
              (q) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• ${q.title} (-${q.difficulty.penaltyGold} G)',
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
                  const Icon(Icons.money_off, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      actualGoldDeducted > 0
                          ? 'Gold Dirampas: -$actualGoldDeducted Gold (Sisa: $_gold G)'
                          : 'Gold kamu sudah habis (0 G)!',
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
    final activeQuests = _quests.where((q) => q.isActive).toList();

    if (activeQuests.isEmpty) {
      _showFeedback('Semua quest aktif selesai! Tambahkan quest baru dulu.');
      return;
    }

    if (activeQuests.length == 1) {
      setState(() {
        _lockedQuestId = activeQuests.first.id;
      });
      _saveGameState();
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
      final currentActive = _quests.where((q) => q.isActive).toList();
      if (currentActive.isEmpty) {
        timer.cancel();
        setState(() {
          _isSpinning = false;
          _spinningHighlightId = null;
        });
        return;
      }

      final randomQuest = currentActive[_random.nextInt(currentActive.length)];

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
        _saveGameState();
        _showFeedback(
          'ROULETTE LOCKED: "${randomQuest.title}" (1.5x CRITICAL DMG!)',
        );
      }
    });
  }

  void _confirmCompleteQuest(Quest quest) {
    if (!quest.isActive || _isSpinning) return;

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
                    '• Total Serangan: -$previewDamage HP ke ${_currentBoss.name}',
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
                    if (_isRageActive)
                      const Text(
                        '  + Rage Potion (2x DMG)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    if (_isWisdomActive)
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
      quest.finishedAt = DateTime.now();
      quest.damageDealt = finalDamage;

      if (isCritical) {
        _lockedQuestId = null;
      }

      _isRageActive = false;
      _isWisdomActive = false;

      _playerXp += gainedXp;
      while (_playerXp >= _xpToNextLevel) {
        _playerXp -= _xpToNextLevel;
        _playerLevel++;
      }

      _bossCurrentHp = max(0, _bossCurrentHp - finalDamage);
    });
    _saveQuests();
    _saveGameState();

    if (_bossCurrentHp == 0) {
      _handleBossDefeated();
    } else {
      _showFeedback(
        isCritical
            ? 'CRITICAL HIT! -$finalDamage DMG ke ${_currentBoss.name} (+$gainedXp XP)'
            : 'Serangan berhasil! -$finalDamage DMG ke ${_currentBoss.name} (+$gainedXp XP)',
      );
    }
  }

  void _handleBossDefeated() {
    final defeatedBoss = _currentBoss;
    final defeatedLevel = _bossLevel;
    final earnedGold = _currentBossGoldReward;

    setState(() {
      _gold += earnedGold;
      _bossLevel++;
      _bossMaxHp = 100 + (_bossLevel - 1) * 40;
      _bossCurrentHp = _bossMaxHp;
    });
    _saveGameState();

    final nextBoss = _currentBoss;

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
                    'Boss berikutnya: Lv.$_bossLevel ${nextBoss.name} ($_bossMaxHp HP)',
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
            child: const Text('Lanjut Bertarung'),
          ),
        ],
      ),
    );
  }

  // Item shop logic
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
    _saveGameState();
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
    _saveGameState();
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
    _saveGameState();
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
    _saveGameState();

    if (_bossCurrentHp == 0) {
      _handleBossDefeated();
    } else {
      _showFeedback('METEOR STRIKE! -$scrollDamage HP ke ${_currentBoss.name}!');
    }
  }

  // Dialog Tambah Quest + Pengaturan Tenggat Waktu (Tampil di Tengah Layar)
  void _showAddQuestDialog() {
    final titleController = TextEditingController();
    QuestDifficulty selectedDifficulty = QuestDifficulty.medium;
    DateTime selectedDeadline = DateTime.now().add(const Duration(hours: 3));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickCustomDateTime() async {
              final now = DateTime.now();
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDeadline.isAfter(now)
                    ? selectedDeadline
                    : now,
                firstDate: now,
                lastDate: now.add(const Duration(days: 365)),
              );
              if (pickedDate == null || !context.mounted) return;

              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(selectedDeadline),
              );
              if (pickedTime == null) return;

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

              setModalState(() {
                selectedDeadline = combined;
              });
            }

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
                                  final isSelected = selectedDifficulty == diff;
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
                                      setModalState(() {
                                        selectedDifficulty = diff;
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
                                      setModalState(() {
                                        selectedDeadline = DateTime.now().add(
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
                                      setModalState(() {
                                        selectedDeadline = DateTime.now().add(
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
                                      setModalState(() {
                                        selectedDeadline = DateTime.now().add(
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
                                      setModalState(() {
                                        selectedDeadline = DateTime.now().add(
                                          const Duration(days: 1),
                                        );
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: pickCustomDateTime,
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
                                          'Batas: ${_formatDateTime(selectedDeadline)}',
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
                                      deadline: selectedDeadline,
                                    ),
                                  );
                                });
                                _saveQuests();
                                Navigator.pop(context);
                              },
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
    return '$day/$month/${dt.year} • $hour:$minute';
  }

  String _formatRemainingTime(DateTime deadline) {
    final diff = deadline.difference(DateTime.now());
    if (diff.isNegative) return 'Waktu habis!';

    if (diff.inDays > 0) {
      return '${diff.inDays}h ${diff.inHours % 24}j lagi';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}j ${diff.inMinutes % 60}m lagi';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ${diff.inSeconds % 60}d lagi';
    } else {
      return '${diff.inSeconds}d lagi!';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF11131A),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFFB703),
          ),
        ),
      );
    }

    final activeQuests = _quests.where((q) => q.isActive).toList();
    final historyQuests = _quests.where((q) => !q.isActive).toList()
      ..sort(
        (a, b) => (b.finishedAt ?? DateTime.now()).compareTo(
          a.finishedAt ?? DateTime.now(),
        ),
      );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Quest Roulette',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1),
        ),
        actions: [
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
                const Icon(
                  Icons.monetization_on,
                  size: 15,
                  color: Colors.amber,
                ),
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
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.lightBlueAccent.withValues(alpha: 0.5),
              ),
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
          _buildHistoryTab(historyQuests),
        ],
      ),
      floatingActionButton: _selectedTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddQuestDialog,
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
              isLabelVisible: historyQuests.isNotEmpty,
              label: Text('${historyQuests.length}'),
              child: const Icon(Icons.history_outlined),
            ),
            selectedIcon: const Icon(Icons.history, color: Color(0xFFFFB703)),
            label: 'History',
          ),
        ],
      ),
    );
  }

  // Arena dan quest
  Widget _buildArenaTab(List<Quest> activeQuests) {
    final boss = _currentBoss;
    final hpRatio = _bossCurrentHp / _bossMaxHp;
    final lockedQuest = activeQuests.cast<Quest?>().firstWhere(
          (q) => q?.id == _lockedQuestId,
          orElse: () => null,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Boss info
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
                          color: boss.color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: boss.color.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Icon(
                          boss.icon,
                          color: boss.color,
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
                                  style: TextStyle(
                                    color: boss.color,
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
                              boss.name,
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
                          valueColor: AlwaysStoppedAnimation<Color>(boss.color),
                        );
                      },
                    ),
                  ),
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

          // 2. Gacha Tugas
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

          //Quest List
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

          // Active quests
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
                      final isLockedTarget = quest.id == _lockedQuestId;
                      final isHighlighted = quest.id == _spinningHighlightId;
                      final calculatedDmg = _calculateDamage(quest);
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
                                    'Tenggat: ${_formatRemainingTime(quest.deadline)} (Penalti -${quest.difficulty.penaltyGold}G)',
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
                            onPressed: () {
                              setState(() {
                                if (_lockedQuestId == quest.id) {
                                  _lockedQuestId = null;
                                }
                                _quests.removeWhere((q) => q.id == quest.id);
                              });
                              _saveQuests();
                              _saveGameState();
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

  // Item Shop
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
                      'Gunakan Gold hasil mengalahkan Boss untuk memperkuat seranganmu!',
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
                backgroundColor: canAfford
                    ? const Color(0xFFFFB703)
                    : Colors.white12,
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

  // Quest History
  Widget _buildHistoryTab(List<Quest> historyQuests) {
    final completedCount = historyQuests.where((q) => q.isDone).length;
    final failedCount = historyQuests.where((q) => q.isFailed).length;
    final totalDamageDealt = historyQuests
        .where((q) => q.isDone)
        .fold<int>(
          0,
          (sum, item) => sum + (item.damageDealt ?? item.difficulty.damage),
        );

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
                  onPressed: () {
                    setState(() {
                      _quests.removeWhere((q) => !q.isActive);
                    });
                    _saveQuests();
                    _showFeedback('Riwayat quest dibersihkan.');
                  },
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
                                ? 'GAGAL (Lewat Tenggat) • Penalti -${quest.goldLost ?? quest.difficulty.penaltyGold} Gold\nWaktu: ${_formatDateTime(quest.finishedAt)}'
                                : '${quest.difficulty.label} • -${quest.damageDealt ?? quest.difficulty.damage} DMG\nSelesai: ${_formatDateTime(quest.finishedAt)}',
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