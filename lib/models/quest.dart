import 'dart:convert';
import 'package:flutter/material.dart';

enum QuestDifficulty {
  easy('Easy', 15, 10, 15, Color(0xFF4CAF50), Icons.shield_outlined),
  medium(
    'Medium',
    30,
    25,
    25,
    Color(0xFFFF9800),
    Icons.local_fire_department,
  ),
  hard('Hard', 50, 50, 40, Color(0xFFE63946), Icons.whatshot);

  final String label;
  final int damage;
  final int xp;
  final int penaltyGold;
  final Color color;
  final IconData icon;

  const QuestDifficulty(
    this.label,
    this.damage,
    this.xp,
    this.penaltyGold,
    this.color,
    this.icon,
  );
}

class Quest {
  final String id;
  final String title;
  final QuestDifficulty difficulty;
  final DateTime deadline;
  bool isDone;
  bool isFailed;
  DateTime? finishedAt;
  int? damageDealt;
  int? goldLost;

  Quest({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.deadline,
    this.isDone = false,
    this.isFailed = false,
    this.finishedAt,
    this.damageDealt,
    this.goldLost,
  });

  bool get isActive => !isDone && !isFailed;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'difficulty': difficulty.name,
      'deadline': deadline.toIso8601String(),
      'isDone': isDone,
      'isFailed': isFailed,
      'finishedAt': finishedAt?.toIso8601String(),
      'damageDealt': damageDealt,
      'goldLost': goldLost,
    };
  }

  factory Quest.fromMap(Map<String, dynamic> map) {
    return Quest(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: map['title']?.toString() ?? '',
      difficulty: QuestDifficulty.values.firstWhere(
        (d) => d.name == map['difficulty'],
        orElse: () => QuestDifficulty.medium,
      ),
      deadline: map['deadline'] != null
          ? DateTime.tryParse(map['deadline'].toString()) ??
              DateTime.now().add(const Duration(hours: 3))
          : DateTime.now().add(const Duration(hours: 3)),
      isDone: map['isDone'] as bool? ?? false,
      isFailed: map['isFailed'] as bool? ?? false,
      finishedAt: map['finishedAt'] != null
          ? DateTime.tryParse(map['finishedAt'].toString())
          : null,
      damageDealt: map['damageDealt'] as int?,
      goldLost: map['goldLost'] as int?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Quest.fromJson(String source) =>
      Quest.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
