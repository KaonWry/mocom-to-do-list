import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocom_to_do_list/models/quest.dart';
import 'package:mocom_to_do_list/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Quest Serialization Tests', () {
    test('Quest correctly converts to and from Map', () {
      final now = DateTime.now();
      final quest = Quest(
        id: 'test-1',
        title: 'Complete Math Homework',
        difficulty: QuestDifficulty.hard,
        deadline: now,
        isDone: true,
        isFailed: false,
        finishedAt: now,
        damageDealt: 50,
        goldLost: null,
      );

      final map = quest.toMap();
      expect(map['id'], 'test-1');
      expect(map['title'], 'Complete Math Homework');
      expect(map['difficulty'], 'hard');
      expect(map['isDone'], true);
      expect(map['damageDealt'], 50);

      final reconstructed = Quest.fromMap(map);
      expect(reconstructed.id, quest.id);
      expect(reconstructed.title, quest.title);
      expect(reconstructed.difficulty, QuestDifficulty.hard);
      expect(reconstructed.isDone, true);
      expect(reconstructed.isFailed, false);
      expect(reconstructed.damageDealt, 50);
    });

    test('Quest correctly converts to and from JSON string', () {
      final now = DateTime.now();
      final quest = Quest(
        id: 'test-json',
        title: 'Review PR',
        difficulty: QuestDifficulty.easy,
        deadline: now,
      );

      final jsonString = quest.toJson();
      final fromJson = Quest.fromJson(jsonString);

      expect(fromJson.id, 'test-json');
      expect(fromJson.title, 'Review PR');
      expect(fromJson.difficulty, QuestDifficulty.easy);
      expect(fromJson.isActive, isTrue);
    });
  });

  group('StorageService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loadQuests returns default quests on first launch', () async {
      final storage = StorageService();
      final quests = await storage.loadQuests();

      expect(quests.isNotEmpty, isTrue);
      expect(quests.length, 3);
    });

    test('saveQuests and loadQuests persist quest data properly', () async {
      final storage = StorageService();
      final customQuests = [
        Quest(
          id: 'custom-1',
          title: 'Custom Quest 1',
          difficulty: QuestDifficulty.medium,
          deadline: DateTime.now().add(const Duration(hours: 4)),
        ),
        Quest(
          id: 'custom-2',
          title: 'Custom Quest 2 (Done)',
          difficulty: QuestDifficulty.hard,
          deadline: DateTime.now().add(const Duration(days: 2)),
          isDone: true,
          damageDealt: 45,
        ),
      ];

      final saved = await storage.saveQuests(customQuests);
      expect(saved, isTrue);

      final loaded = await storage.loadQuests();
      expect(loaded.length, 2);
      expect(loaded[0].id, 'custom-1');
      expect(loaded[0].title, 'Custom Quest 1');
      expect(loaded[1].id, 'custom-2');
      expect(loaded[1].isDone, isTrue);
      expect(loaded[1].damageDealt, 45);
    });

    test('saveGameState and loadGameState persist RPG progress properly', () async {
      final storage = StorageService();
      const customState = GameStateData(
        playerLevel: 5,
        playerXp: 120,
        gold: 350,
        bossLevel: 3,
        bossCurrentHp: 110,
        bossMaxHp: 180,
        weaponLevel: 4,
        bonusWeaponDamage: 20,
        isRageActive: true,
        isWisdomActive: false,
        lockedQuestId: 'custom-1',
        totalDamageDealt: 750,
      );

      final saved = await storage.saveGameState(customState);
      expect(saved, isTrue);

      final loaded = await storage.loadGameState();
      expect(loaded.playerLevel, 5);
      expect(loaded.playerXp, 120);
      expect(loaded.gold, 350);
      expect(loaded.bossLevel, 3);
      expect(loaded.bossCurrentHp, 110);
      expect(loaded.bossMaxHp, 180);
      expect(loaded.weaponLevel, 4);
      expect(loaded.bonusWeaponDamage, 20);
      expect(loaded.isRageActive, isTrue);
      expect(loaded.isWisdomActive, isFalse);
      expect(loaded.lockedQuestId, 'custom-1');
      expect(loaded.totalDamageDealt, 750);
    });

    test('Corrupted data gracefully falls back to defaults without crash', () async {
      SharedPreferences.setMockInitialValues({
        StorageService.questsKey: 'invalid-json-string',
        StorageService.gameStateKey: 'invalid-json-string',
      });

      final storage = StorageService();
      final quests = await storage.loadQuests();
      expect(quests.length, 3);

      final state = await storage.loadGameState();
      expect(state.playerLevel, 1);
      expect(state.gold, 50);
    });
  });
}
