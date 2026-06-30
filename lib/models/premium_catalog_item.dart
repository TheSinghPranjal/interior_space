import 'package:flutter/material.dart';

import 'enums.dart';

/// Premium-only catalog entries — separate from standard [FurnitureType] chips.
enum PremiumCatalogId {
  bathtubWithWater,
  bathtubVintage,
  pottedPlant,
  indoorPlant,
  monstera,
  luxuryBed,
}

class PremiumCatalogDefinition {
  const PremiumCatalogDefinition({
    required this.id,
    required this.name,
    required this.baseType,
    required this.icon,
    required this.previewTop,
    required this.previewBottom,
    required this.previewAccent,
    this.width = 6.0,
    this.height = 2.5,
    this.depth = 6.0,
    this.color = '#795548',
  });

  final PremiumCatalogId id;
  final String name;
  final FurnitureType baseType;
  final IconData icon;
  final Color previewTop;
  final Color previewBottom;
  final Color previewAccent;
  final double width;
  final double height;
  final double depth;
  final String color;

  String get idKey => id.name;
}

extension PremiumCatalogIdLookup on PremiumCatalogId {
  PremiumCatalogDefinition get definition =>
      premiumFurnitureCatalog.firstWhere((d) => d.id == this);
}

/// All premium catalog items shown in the Add More panel.
const premiumFurnitureCatalog = <PremiumCatalogDefinition>[
  PremiumCatalogDefinition(
    id: PremiumCatalogId.bathtubWithWater,
    name: 'Bathtub with Water',
    baseType: FurnitureType.bathtub,
    icon: Icons.bathtub_outlined,
    previewTop: Color(0xFF81D4FA),
    previewBottom: Color(0xFFF5F5F5),
    previewAccent: Color(0xFFB0BEC5),
    width: 2.8,
    height: 2.2,
    depth: 5.2,
    color: '#FAFAFA',
  ),
  PremiumCatalogDefinition(
    id: PremiumCatalogId.bathtubVintage,
    name: 'Bathtub Vintage',
    baseType: FurnitureType.bathtub,
    icon: Icons.bathtub_outlined,
    previewTop: Color(0xFFFFF8E1),
    previewBottom: Color(0xFFEFEBE9),
    previewAccent: Color(0xFF8D6E63),
    width: 3.0,
    height: 2.4,
    depth: 5.5,
    color: '#FFF8E1',
  ),
  PremiumCatalogDefinition(
    id: PremiumCatalogId.pottedPlant,
    name: 'Potted Plant',
    baseType: FurnitureType.flowerPot,
    icon: Icons.local_florist_outlined,
    previewTop: Color(0xFF66BB6A),
    previewBottom: Color(0xFFBF360C),
    previewAccent: Color(0xFF8D6E63),
    width: 1.4,
    height: 3.0,
    depth: 1.4,
    color: '#BF360C',
  ),
  PremiumCatalogDefinition(
    id: PremiumCatalogId.indoorPlant,
    name: 'Indoor Plant',
    baseType: FurnitureType.flowerPot,
    icon: Icons.yard_outlined,
    previewTop: Color(0xFF43A047),
    previewBottom: Color(0xFFECEFF1),
    previewAccent: Color(0xFF78909C),
    width: 1.6,
    height: 3.5,
    depth: 1.6,
    color: '#78909C',
  ),
  PremiumCatalogDefinition(
    id: PremiumCatalogId.monstera,
    name: 'Monstera',
    baseType: FurnitureType.flowerPot,
    icon: Icons.eco_outlined,
    previewTop: Color(0xFF2E7D32),
    previewBottom: Color(0xFFBDBDBD),
    previewAccent: Color(0xFF1B5E20),
    width: 1.8,
    height: 4.2,
    depth: 1.8,
    color: '#9E9E9E',
  ),
  PremiumCatalogDefinition(
    id: PremiumCatalogId.luxuryBed,
    name: 'Luxury Bed',
    baseType: FurnitureType.bed,
    icon: Icons.king_bed_outlined,
    previewTop: Color(0xFF5D4037),
    previewBottom: Color(0xFF3E2723),
    previewAccent: Color(0xFFD7CCC8),
    width: 6.5,
    height: 3.0,
    depth: 6.8,
    color: '#5D4037',
  ),
];

PremiumCatalogDefinition? premiumCatalogByIdKey(String? key) {
  if (key == null || key.isEmpty) return null;
  for (final item in premiumFurnitureCatalog) {
    if (item.idKey == key) return item;
  }
  return null;
}
