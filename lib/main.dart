import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'dialogs/add_quest_dialog.dart';
import 'dialogs/boss_defeated_dialog.dart';
import 'dialogs/confirm_quest_dialog.dart';
import 'dialogs/punishment_dialog.dart';
import 'models/boss_profile.dart';
import 'models/quest.dart';
import 'screens/arena_tab.dart';
import 'screens/history_tab.dart';
import 'screens/shop_tab.dart';
import 'services/storage_service.dart';

export 'models/boss_profile.dart';
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

  final List<BossProfile> _bossRoster = defaultBossRoster;

  // RPG Boss & Player State
  int _bossLevel = 1;
  int _bossMaxHp = 100;
  int _bossCurrentHp = 100;
  int _playerLevel = 1;
  int _playerXp = 0;
  int _gold = 50;

  // Equipment & Support Buff State
  int _weaponLevel = 0;
  int _bonusWeaponDamage = 0;
  bool _isRageActive = false;
  bool _isWisdomActive = false;

  // Roulette & Timer State
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

    _deadlineTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkDeadlines();
    });
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    _deadlineTicker?.cancel();
    super.dispose();
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

  BossProfile get _currentBoss =>
      _bossRoster[(_bossLevel - 1) % _bossRoster.length];

  int get _xpToNextLevel => _playerLevel * 100;
  int get _currentBossGoldReward => 50 + (_bossLevel * 25);
  int get _weaponUpgradeCost => 50 + (_weaponLevel * 35);

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

  void _checkDeadlines() {
    if (_isLoading) return;
    final now = DateTime.now();
    final expiredQuests = _quests
        .where((q) => q.isActive && now.isAfter(q.deadline))
        .toList();

    if (expiredQuests.isEmpty) {
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

    showPunishmentDialog(
      context,
      expiredQuests: expiredQuests,
      bossName: _currentBoss.name,
      actualGoldDeducted: actualGoldDeducted,
      remainingGold: _gold,
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

  Future<void> _confirmCompleteQuest(Quest quest) async {
    if (!quest.isActive || _isSpinning) return;

    final isConfirmed = await showConfirmQuestDialog(
      context,
      quest: quest,
      bossName: _currentBoss.name,
      previewDamage: _calculateDamage(quest),
      previewXp: _calculateXp(quest),
      isCritical: quest.id == _lockedQuestId,
      bonusWeaponDamage: _bonusWeaponDamage,
      weaponLevel: _weaponLevel,
      isRageActive: _isRageActive,
      isWisdomActive: _isWisdomActive,
    );

    if (isConfirmed == true && mounted) {
      _executeQuestCompletion(quest);
    }
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

    showBossDefeatedDialog(
      context,
      defeatedBoss: defeatedBoss,
      defeatedLevel: defeatedLevel,
      earnedGold: earnedGold,
      nextBoss: nextBoss,
      nextBossLevel: _bossLevel,
      nextBossMaxHp: _bossMaxHp,
    );
  }

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

  Future<void> _openAddQuestDialog() async {
    final newQuest = await showAddQuestDialog(context);
    if (newQuest != null && mounted) {
      setState(() {
        _quests.insert(0, newQuest);
      });
      _saveQuests();
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
          ArenaTab(
            boss: _currentBoss,
            bossLevel: _bossLevel,
            bossCurrentHp: _bossCurrentHp,
            bossMaxHp: _bossMaxHp,
            currentBossGoldReward: _currentBossGoldReward,
            weaponLevel: _weaponLevel,
            bonusWeaponDamage: _bonusWeaponDamage,
            isRageActive: _isRageActive,
            isWisdomActive: _isWisdomActive,
            activeQuests: activeQuests,
            lockedQuestId: _lockedQuestId,
            spinningHighlightId: _spinningHighlightId,
            isSpinning: _isSpinning,
            onSpinRoulette: _spinRoulette,
            onCompleteQuest: _confirmCompleteQuest,
            onDeleteQuest: (quest) {
              setState(() {
                if (_lockedQuestId == quest.id) {
                  _lockedQuestId = null;
                }
                _quests.removeWhere((q) => q.id == quest.id);
              });
              _saveQuests();
              _saveGameState();
            },
            calculateDamage: _calculateDamage,
          ),
          ShopTab(
            gold: _gold,
            weaponLevel: _weaponLevel,
            bonusWeaponDamage: _bonusWeaponDamage,
            weaponUpgradeCost: _weaponUpgradeCost,
            isRageActive: _isRageActive,
            isWisdomActive: _isWisdomActive,
            onBuyWeaponUpgrade: _buyWeaponUpgrade,
            onBuyRagePotion: _buyRagePotion,
            onBuyWisdomElixir: _buyWisdomElixir,
            onBuyMeteorScroll: _buyMeteorScroll,
          ),
          HistoryTab(
            historyQuests: historyQuests,
            onClearHistory: () {
              setState(() {
                _quests.removeWhere((q) => !q.isActive);
              });
              _saveQuests();
              _showFeedback('Riwayat quest dibersihkan.');
            },
          ),
        ],
      ),
      floatingActionButton: _selectedTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _openAddQuestDialog,
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
          NavigationDestination(
            icon: Badge(
              isLabelVisible: activeQuests.isNotEmpty,
              label: Text('${activeQuests.length}'),
              child: const Icon(Icons.sports_kabaddi_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: activeQuests.isNotEmpty,
              label: Text('${activeQuests.length}'),
              child: const Icon(Icons.sports_kabaddi, color: Color(0xFFFFB703)),
            ),
            label: 'Arena',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: Color(0xFFFFB703)),
            label: 'Shop',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Color(0xFFFFB703)),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
