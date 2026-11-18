import 'package:flutter/material.dart';

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

const List<BossProfile> defaultBossRoster = [
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
