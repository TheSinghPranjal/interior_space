import 'package:flutter/material.dart';

enum WallId { front, back, left, right }

enum SurfaceType { solidColor, texture, wallpaper }

enum WallTexture {
  brick,
  concrete,
  marble,
  wood,
  stone,
  fabric,
}

enum FloorPattern { grid, staggered, herringbone, diagonal }

enum FloorMaterial { marble, granite, wooden, vinyl, ceramic, porcelain }

enum CeilingMaterial { matte, glossy, pop, gypsum }

enum FalseCeilingType {
  none,
  singleLayer,
  doubleLayer,
  cove,
  tray,
  floating,
}

enum DoorMaterial { wood, metal, glass, laminate }

enum CupboardTexture { matte, glossy, laminate, veneer }

enum LightType { ceiling, spot, ledStrip, chandelier, wall }

enum LightTemperature { warmWhite, coolWhite, neutralWhite }

enum CameraMode {
  orbit,
  walk,
  firstPerson,
  top,
  front,
  side,
  isometric,
}

enum FurnitureType { bed, sofa, table, tvUnit, chair, wardrobe, cupboard }

extension FurnitureTypePlacement on FurnitureType {
  bool get isWallMounted => false;
}

extension WallIdLabel on WallId {
  String get label => switch (this) {
        WallId.front => 'Front Wall',
        WallId.back => 'Back Wall',
        WallId.left => 'Left Wall',
        WallId.right => 'Right Wall',
      };
}

extension FurnitureTypeLabel on FurnitureType {
  String get label => switch (this) {
        FurnitureType.bed => 'Bed',
        FurnitureType.sofa => 'Sofa',
        FurnitureType.table => 'Table',
        FurnitureType.tvUnit => 'TV Unit',
        FurnitureType.chair => 'Chair',
        FurnitureType.wardrobe => 'Wardrobe',
        FurnitureType.cupboard => 'Cupboard',
      };

  IconData get icon => switch (this) {
        FurnitureType.bed => Icons.bed,
        FurnitureType.sofa => Icons.weekend,
        FurnitureType.table => Icons.table_restaurant,
        FurnitureType.tvUnit => Icons.tv,
        FurnitureType.chair => Icons.chair,
        FurnitureType.wardrobe => Icons.door_sliding,
        FurnitureType.cupboard => Icons.kitchen,
      };
}
