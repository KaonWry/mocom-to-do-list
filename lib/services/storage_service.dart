import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quest.dart';

class GameStateData {
  final int playerLevel;
  final int playerXp;
  final int gold;
  final int bossLevel;
  final int bossCurrentHp;
  final int bossMaxHp;
  final int weaponLevel;
  final int bonusWeaponDamage;
  final bool isRageActive;
  final bool isWisdomActive;
  final String? lockedQuestId;

  const GameStateData({
    this.playerLevel = 1,
    this.playerXp = 0,
    this.gold = 50,
    this.bossLevel = 1,
    this.bossCurrentHp = 100,
    this.bossMaxHp = 100,
    this.weaponLevel = 0,
    this.bonusWeaponDamage = 0,
    this.isRageActive = false,
    this.isWisdomActive = false,
    this.lockedQuestId,
  });

  Map<String, dynamic> toMap() {
    return {
      'playerLevel': playerLevel,
      'playerXp': playerXp,
      'gold': gold,
      'bossLevel': bossLevel,
      'bossCurrentHp': bossCurrentHp,
      'bossMaxHp': bossMaxHp,
      'weaponLevel': weaponLevel,
      'bonusWeaponDamage': bonusWeaponDamage,
      'isRageActive': isRageActive,
      'isWisdomActive': isWisdomActive,
      'lockedQuestId': lockedQuestId,
    };
  }

  factory GameStateData.fromMap(Map<String, dynamic> map) {
    final bossLevel = map['bossLevel'] as int? ?? 1;
    final defaultBossMaxHp = 100 + (bossLevel - 1) * 40;
    return GameStateData(
      playerLevel: map['playerLevel'] as int? ?? 1,
      playerXp: map['playerXp'] as int? ?? 0,
      gold: map['gold'] as int? ?? 50,
      bossLevel: bossLevel,
      bossCurrentHp: map['bossCurrentHp'] as int? ?? defaultBossMaxHp,
      bossMaxHp: map['bossMaxHp'] as int? ?? defaultBossMaxHp,
      weaponLevel: map['weaponLevel'] as int? ?? 0,
      bonusWeaponDamage: map['bonusWeaponDamage'] as int? ?? 0,
      isRageActive: map['isRageActive'] as bool? ?? false,
      isWisdomActive: map['isWisdomActive'] as bool? ?? false,
      lockedQuestId: map['lockedQuestId'] as String?,
    );
  }
}

class StorageService {
  static const String questsKey = 'quests_data_v1';
  static const String gameStateKey = 'game_state_v1';

  final SharedPreferences? _prefs;

  StorageService([this._prefs]);

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  Future<List<Quest>> loadQuests() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(questsKey);
    if (jsonString == null) {
      return defaultQuests();
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => Quest.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return defaultQuests();
    }
  }

  Future<bool> saveQuests(List<Quest> quests) async {
    final prefs = await _getPrefs();
    final jsonList = quests.map((q) => q.toMap()).toList();
    return prefs.setString(questsKey, jsonEncode(jsonList));
  }

  Future<GameStateData> loadGameState() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(gameStateKey);
    if (jsonString == null) {
      return const GameStateData();
    }
    try {
      final Map<String, dynamic> decoded =
          jsonDecode(jsonString) as Map<String, dynamic>;
      return GameStateData.fromMap(decoded);
    } catch (_) {
      return const GameStateData();
    }
  }

  Future<bool> saveGameState(GameStateData state) async {
    final prefs = await _getPrefs();
    return prefs.setString(gameStateKey, jsonEncode(state.toMap()));
  }

  static List<Quest> defaultQuests() {
    final now = DateTime.now();
    return [
      Quest(
        id: '1',
        title: 'Rapikan catatan kuliah hari ini',
        difficulty: QuestDifficulty.easy,
        deadline: now.add(const Duration(hours: 2)),
      ),
      Quest(
        id: '2',
        title: 'Kerjakan UI aplikasi To-Do List',
        difficulty: QuestDifficulty.medium,
        deadline: now.add(const Duration(hours: 5)),
      ),
      Quest(
        id: '3',
        title: 'Selesaikan laporan praktikum',
        difficulty: QuestDifficulty.hard,
        deadline: now.add(const Duration(days: 1)),
      ),
    ];
  }
}
