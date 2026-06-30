import 'package:flutter/material.dart';

enum WallId { front, back, left, right }

/// Rectangular (width × length) or user-drawn polygon on the custom room grid.
enum RoomShapeMode { rectangular, polygon }

/// Which segment of a wall remains visible when [WallConfig.visibleFraction] &lt; 1.
enum WallVisibleAlign { start, center, end }

/// Barrier style for a wall edge in custom wall mode.
enum WallBarrierType { solid, fence, balconyRailing }

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
  top,
  front,
  side,
  isometric,
}

enum FurnitureType {
  bathtub,
  bed,
  chair,
  diningTable,
  flowerPot,
  fridge,
  kitchenChimney,
  shoeRack,
  sink,
  sofa,
  storageUnit,
  table,
  tvUnit,
  wardrobe,
  washingMachine,
  toilet,
}

enum DiningTableShape { rectangular, round }

enum StorageUnitStyle { singleDoor, doubleDoor, drawerUnit, openShelf }

enum KitchenChimneyStyle { wallMounted, glass, stainlessSteel }

enum FurnitureMaterialPreset {
  wood,
  whiteMatte,
  glossy,
  metallic,
  stainlessSteel,
  black,
  white,
}

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

  String get shortLabel => switch (this) {
        WallId.front => 'Front',
        WallId.back => 'Back',
        WallId.left => 'Left',
        WallId.right => 'Right',
      };
}

extension WallBarrierTypeLabel on WallBarrierType {
  String get label => switch (this) {
        WallBarrierType.solid => 'Solid wall',
        WallBarrierType.fence => 'Fence',
        WallBarrierType.balconyRailing => 'Balcony railing',
      };
}

extension FurnitureTypeLabel on FurnitureType {
  String get label => switch (this) {
        FurnitureType.bed => 'Bed',
        FurnitureType.sofa => 'Sofa',
        FurnitureType.table => 'Table',
        FurnitureType.diningTable => 'Dining Table',
        FurnitureType.tvUnit => 'TV Unit',
        FurnitureType.chair => 'Chair',
        FurnitureType.wardrobe => 'Wardrobe',
        FurnitureType.storageUnit => 'Storage Unit',
        FurnitureType.kitchenChimney => 'Kitchen Chimney',
        FurnitureType.sink => 'Sink / Wash Basin',
        FurnitureType.toilet => 'Western Toilet',
        FurnitureType.washingMachine => 'Washing Machine',
        FurnitureType.bathtub => 'Bathtub',
        FurnitureType.flowerPot => 'Flower Pot',
        FurnitureType.fridge => 'Fridge',
        FurnitureType.shoeRack => 'Shoe Rack',
      };

  IconData get icon => switch (this) {
        FurnitureType.bed => Icons.bed,
        FurnitureType.sofa => Icons.weekend,
        FurnitureType.table => Icons.table_restaurant,
        FurnitureType.diningTable => Icons.dining,
        FurnitureType.tvUnit => Icons.tv,
        FurnitureType.chair => Icons.chair,
        FurnitureType.wardrobe => Icons.door_sliding,
        FurnitureType.storageUnit => Icons.countertops,
        FurnitureType.kitchenChimney => Icons.air,
        FurnitureType.sink => Icons.wash,
        FurnitureType.toilet => Icons.wc,
        FurnitureType.washingMachine => Icons.local_laundry_service,
        FurnitureType.bathtub => Icons.bathtub,
        FurnitureType.flowerPot => Icons.local_florist,
        FurnitureType.fridge => Icons.inventory_2,
        FurnitureType.shoeRack => Icons.grid_view,
      };
}

extension DiningTableShapeLabel on DiningTableShape {
  String get label => switch (this) {
        DiningTableShape.rectangular => 'Rectangular',
        DiningTableShape.round => 'Round',
      };
}

extension StorageUnitStyleLabel on StorageUnitStyle {
  String get label => switch (this) {
        StorageUnitStyle.singleDoor => 'Single Door',
        StorageUnitStyle.doubleDoor => 'Double Door',
        StorageUnitStyle.drawerUnit => 'Drawer Unit',
        StorageUnitStyle.openShelf => 'Open Shelf Unit',
      };
}

extension KitchenChimneyStyleLabel on KitchenChimneyStyle {
  String get label => switch (this) {
        KitchenChimneyStyle.wallMounted => 'Wall Mounted',
        KitchenChimneyStyle.glass => 'Glass Chimney',
        KitchenChimneyStyle.stainlessSteel => 'Stainless Steel',
      };
}

extension FurnitureMaterialPresetLabel on FurnitureMaterialPreset {
  String get label => switch (this) {
        FurnitureMaterialPreset.wood => 'Wood',
        FurnitureMaterialPreset.whiteMatte => 'White Matte',
        FurnitureMaterialPreset.glossy => 'Glossy Finish',
        FurnitureMaterialPreset.metallic => 'Metallic',
        FurnitureMaterialPreset.stainlessSteel => 'Stainless Steel',
        FurnitureMaterialPreset.black => 'Black Finish',
        FurnitureMaterialPreset.white => 'White Finish',
      };
}
