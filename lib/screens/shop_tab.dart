import 'package:flutter/material.dart';
import '../widgets/shop_item_card.dart';

class ShopTab extends StatelessWidget {
  final int gold;
  final int weaponLevel;
  final int bonusWeaponDamage;
  final int weaponUpgradeCost;
  final bool isRageActive;
  final bool isWisdomActive;
  final VoidCallback onBuyWeaponUpgrade;
  final VoidCallback onBuyRagePotion;
  final VoidCallback onBuyWisdomElixir;
  final VoidCallback onBuyMeteorScroll;

  const ShopTab({
    super.key,
    required this.gold,
    required this.weaponLevel,
    required this.bonusWeaponDamage,
    required this.weaponUpgradeCost,
    required this.isRageActive,
    required this.isWisdomActive,
    required this.onBuyWeaponUpgrade,
    required this.onBuyRagePotion,
    required this.onBuyWisdomElixir,
    required this.onBuyMeteorScroll,
  });

  @override
  Widget build(BuildContext context) {
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
        ShopItemCard(
          icon: Icons.hardware,
          iconColor: Colors.lightBlueAccent,
          title: 'Asah Pedang (Lv.$weaponLevel → Lv.${weaponLevel + 1})',
          description:
              'Menambah +5 Base Damage secara permanen untuk setiap quest. (Saat ini: +$bonusWeaponDamage DMG)',
          price: weaponUpgradeCost,
          buttonLabel: 'Upgrade',
          canAfford: gold >= weaponUpgradeCost,
          onBuy: onBuyWeaponUpgrade,
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
        ShopItemCard(
          icon: Icons.local_fire_department,
          iconColor: Colors.orangeAccent,
          title: 'Rage Potion (2x Damage)',
          description:
              'Menggandakan total damage pada 1 quest berikutnya. Bisa ditumpuk dengan Crit Roulette!',
          price: 40,
          buttonLabel: isRageActive ? 'Aktif' : 'Beli',
          isDisabled: isRageActive,
          canAfford: gold >= 40,
          onBuy: onBuyRagePotion,
        ),
        const SizedBox(height: 10),
        ShopItemCard(
          icon: Icons.auto_awesome,
          iconColor: Colors.purpleAccent,
          title: 'Wisdom Elixir (2x EXP)',
          description:
              'Menggandakan perolehan EXP pada 1 quest berikutnya agar Hero lebih cepat naik level.',
          price: 35,
          buttonLabel: isWisdomActive ? 'Aktif' : 'Beli',
          isDisabled: isWisdomActive,
          canAfford: gold >= 35,
          onBuy: onBuyWisdomElixir,
        ),
        const SizedBox(height: 10),
        ShopItemCard(
          icon: Icons.flash_on,
          iconColor: const Color(0xFFE63946),
          title: 'Meteor Scroll (-50 HP Boss)',
          description:
              'Menyerang Boss secara instan sebesar 50 HP tanpa harus menyelesaikan quest.',
          price: 65,
          buttonLabel: 'Gunakan',
          canAfford: gold >= 65,
          onBuy: onBuyMeteorScroll,
        ),
      ],
    );
  }
}
