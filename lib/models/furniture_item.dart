import '../core/utils/blueprint_placement.dart';
import 'enums.dart';
import 'room_dimensions.dart';

class FurnitureItem {
  const FurnitureItem({
    required this.id,
    required this.type,
    this.width = 6.0,
    this.height = 2.0,
    this.depth = 6.5,
    this.rotation = 0,
    this.blueprintX = 0.5,
    this.blueprintY = 0.5,
    this.color = '#795548',
    this.wall,
    this.positionFromEdge = 1.0,
    this.texturePath,
    this.variant,
    this.materialPreset,
    this.heightFromFloor = 0,
  });

  final String id;
  final FurnitureType type;
  final double width;
  final double height;
  final double depth;
  final double rotation;
  final double blueprintX;
  final double blueprintY;
  final String color;
  final WallId? wall;
  final double positionFromEdge;
  final String? texturePath;
  /// Style variant — shape/style enum name depending on [type].
  final String? variant;
  /// Material finish preset enum name.
  final String? materialPreset;
  /// Bottom edge height above floor (ft). Used by storage units and chimneys.
  final double heightFromFloor;

  bool get supportsHeightFromFloor =>
      type == FurnitureType.storageUnit || type == FurnitureType.kitchenChimney;

  double maxHeightFromFloorFt(RoomDimensions dims) =>
      (dims.height - height).clamp(0, dims.height).toDouble();

  DiningTableShape get diningTableShape {
    if (type != FurnitureType.diningTable) return DiningTableShape.rectangular;
    return DiningTableShape.values.firstWhere(
      (s) => s.name == variant,
      orElse: () => DiningTableShape.rectangular,
    );
  }

  StorageUnitStyle get storageUnitStyle {
    if (type != FurnitureType.storageUnit) return StorageUnitStyle.singleDoor;
    return StorageUnitStyle.values.firstWhere(
      (s) => s.name == variant,
      orElse: () => StorageUnitStyle.singleDoor,
    );
  }

  KitchenChimneyStyle get chimneyStyle {
    if (type != FurnitureType.kitchenChimney) return KitchenChimneyStyle.wallMounted;
    return KitchenChimneyStyle.values.firstWhere(
      (s) => s.name == variant,
      orElse: () => KitchenChimneyStyle.wallMounted,
    );
  }

  FurnitureMaterialPreset get material {
    return FurnitureMaterialPreset.values.firstWhere(
      (m) => m.name == materialPreset,
      orElse: () => FurnitureMaterialPreset.wood,
    );
  }

  bool get supportsTextureUpload => switch (type) {
        FurnitureType.bed ||
        FurnitureType.sofa ||
        FurnitureType.table ||
        FurnitureType.diningTable ||
        FurnitureType.tvUnit ||
        FurnitureType.chair ||
        FurnitureType.wardrobe ||
        FurnitureType.storageUnit ||
        FurnitureType.kitchenChimney ||
        FurnitureType.sink ||
        FurnitureType.toilet ||
        FurnitureType.washingMachine ||
        FurnitureType.bathtub ||
        FurnitureType.flowerPot ||
        FurnitureType.fridge =>
          true,
        _ => false,
      };

  bool get isWallMounted => type.isWallMounted;

  /// Blueprint/editor label — "Bed" alone, or "Bed 1", "Bed 2" when multiples exist.
  static String displayLabel(List<FurnitureItem> furniture, FurnitureItem item) {
    final sameType = furniture.where((f) => f.type == item.type).toList();
    if (sameType.length <= 1) return item.type.label;
    final index = sameType.indexWhere((f) => f.id == item.id);
    if (index < 0) return item.type.label;
    return '${item.type.label} ${index + 1}';
  }

  double effectiveWidthFt() =>
      BlueprintPlacement.effectiveWidthFt(width, depth, rotation);

  double effectiveDepthFt() =>
      BlueprintPlacement.effectiveDepthFt(width, depth, rotation);

  double positionFromLeftFt(RoomDimensions dims) =>
      blueprintX * dims.effectiveWidth - effectiveWidthFt() / 2;

  double positionFromFrontFt(RoomDimensions dims) =>
      blueprintY * dims.effectiveLength - effectiveDepthFt() / 2;

  double maxPositionFromLeftFt(RoomDimensions dims) =>
      (dims.effectiveWidth - effectiveWidthFt()).clamp(0, dims.effectiveWidth).toDouble();

  double maxPositionFromFrontFt(RoomDimensions dims) =>
      (dims.effectiveLength - effectiveDepthFt()).clamp(0, dims.effectiveLength).toDouble();

  double blueprintXFromLeftFt(double leftFt, RoomDimensions dims) {
    final half = normalizedHalfExtents(dims).halfX;
    return ((leftFt + effectiveWidthFt() / 2) / dims.effectiveWidth).clamp(half, 1 - half);
  }

  double blueprintYFromFrontFt(double frontFt, RoomDimensions dims) {
    final half = normalizedHalfExtents(dims).halfY;
    return ((frontFt + effectiveDepthFt() / 2) / dims.effectiveLength).clamp(half, 1 - half);
  }

  ({double halfX, double halfY}) normalizedHalfExtents(RoomDimensions dims) =>
      BlueprintPlacement.normalizedHalfExtents(
        widthFt: width,
        depthFt: depth,
        rotationDeg: rotation,
        roomWidthFt: dims.effectiveWidth,
        roomLengthFt: dims.effectiveLength,
      );

  FurnitureItem copyWith({
    FurnitureType? type,
    double? width,
    double? height,
    double? depth,
    double? rotation,
    double? blueprintX,
    double? blueprintY,
    String? color,
    WallId? wall,
    double? positionFromEdge,
    String? texturePath,
    bool clearTexture = false,
    bool clearWall = false,
    String? variant,
    String? materialPreset,
    bool clearVariant = false,
    bool clearMaterialPreset = false,
    double? heightFromFloor,
  }) {
    return FurnitureItem(
      id: id,
      type: type ?? this.type,
      width: width ?? this.width,
      height: height ?? this.height,
      depth: depth ?? this.depth,
      rotation: rotation ?? this.rotation,
      blueprintX: blueprintX ?? this.blueprintX,
      blueprintY: blueprintY ?? this.blueprintY,
      color: color ?? this.color,
      wall: clearWall ? null : (wall ?? this.wall),
      positionFromEdge: positionFromEdge ?? this.positionFromEdge,
      texturePath: clearTexture ? null : (texturePath ?? this.texturePath),
      variant: clearVariant ? null : (variant ?? this.variant),
      materialPreset: clearMaterialPreset ? null : (materialPreset ?? this.materialPreset),
      heightFromFloor: heightFromFloor ?? this.heightFromFloor,
    );
  }

  static FurnitureItem defaultForType(
    FurnitureType type,
    String id, {
    int index = 0,
    RoomDimensions? dimensions,
  }) {
    final base = switch (type) {
      FurnitureType.bed => FurnitureItem(
          id: id,
          type: type,
          width: 6.5,
          height: 2.5,
          depth: 6.5,
          color: '#5D4037',
        ),
      FurnitureType.sofa => FurnitureItem(
          id: id,
          type: type,
          width: 7.0,
          height: 3.0,
          depth: 3.0,
          color: '#455A64',
        ),
      FurnitureType.table => FurnitureItem(
          id: id,
          type: type,
          width: 4.0,
          height: 2.5,
          depth: 2.5,
          color: '#6D4C41',
        ),
      FurnitureType.diningTable => FurnitureItem(
          id: id,
          type: type,
          width: 5.0,
          height: 2.5,
          depth: 3.0,
          color: '#6D4C41',
          variant: DiningTableShape.rectangular.name,
          materialPreset: FurnitureMaterialPreset.wood.name,
        ),
      FurnitureType.tvUnit => FurnitureItem(
          id: id,
          type: type,
          width: 5.0,
          height: 2.0,
          depth: 1.5,
          color: '#37474F',
        ),
      FurnitureType.chair => FurnitureItem(
          id: id,
          type: type,
          width: 2.0,
          height: 3.0,
          depth: 2.0,
          color: '#78909C',
        ),
      FurnitureType.wardrobe => FurnitureItem(
          id: id,
          type: type,
          width: 6.0,
          height: 7.0,
          depth: 2.0,
          color: '#6D4C41',
        ),
      FurnitureType.storageUnit => FurnitureItem(
          id: id,
          type: type,
          width: 2.0,
          height: 3.0,
          depth: 1.5,
          color: '#558B2F',
          variant: StorageUnitStyle.singleDoor.name,
          materialPreset: FurnitureMaterialPreset.wood.name,
          heightFromFloor: 0,
        ),
      FurnitureType.kitchenChimney => FurnitureItem(
          id: id,
          type: type,
          width: 3.0,
          height: 2.5,
          depth: 1.2,
          color: '#37474F',
          variant: KitchenChimneyStyle.wallMounted.name,
          materialPreset: FurnitureMaterialPreset.stainlessSteel.name,
          heightFromFloor: 5.5,
        ),
      FurnitureType.sink => FurnitureItem(
          id: id,
          type: type,
          width: 2.5,
          height: 3.2,
          depth: 1.8,
          color: '#78909C',
        ),
      FurnitureType.toilet => FurnitureItem(
          id: id,
          type: type,
          width: 1.6,
          height: 2.8,
          depth: 2.6,
          color: '#FAFAFA',
        ),
      FurnitureType.washingMachine => FurnitureItem(
          id: id,
          type: type,
          width: 2.2,
          height: 3.0,
          depth: 2.5,
          color: '#ECEFF1',
        ),
      FurnitureType.bathtub => FurnitureItem(
          id: id,
          type: type,
          width: 2.5,
          height: 2.0,
          depth: 5.0,
          color: '#FAFAFA',
        ),
      FurnitureType.flowerPot => FurnitureItem(
          id: id,
          type: type,
          width: 1.2,
          height: 2.5,
          depth: 1.2,
          color: '#BF360C',
        ),
      FurnitureType.fridge => FurnitureItem(
          id: id,
          type: type,
          width: 2.5,
          height: 5.5,
          depth: 2.5,
          color: '#ECEFF1',
        ),
    };

    if (base.isWallMounted) {
      return base.copyWith(
        positionFromEdge: base.positionFromEdge + index * 1.5,
      );
    }

    final cols = 3;
    final row = index ~/ cols;
    final col = index % cols;
    final bx = 0.22 + col * 0.28;
    final by = 0.28 + row * 0.22;

    return base.copyWith(
      blueprintX: bx.clamp(0.12, 0.88),
      blueprintY: by.clamp(0.12, 0.88),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'width': width,
        'height': height,
        'depth': depth,
        'rotation': rotation,
        'blueprintX': blueprintX,
        'blueprintY': blueprintY,
        'color': color,
        'wall': wall?.name,
        'positionFromEdge': positionFromEdge,
        'texturePath': texturePath,
        'variant': variant,
        'materialPreset': materialPreset,
        'heightFromFloor': heightFromFloor,
      };

  factory FurnitureItem.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String;
    final type = switch (typeName) {
      'cupboard' => FurnitureType.wardrobe,
      _ => FurnitureType.values.byName(typeName),
    };
    return FurnitureItem(
      id: json['id'] as String,
      type: type,
      width: (json['width'] as num?)?.toDouble() ?? 6.0,
      height: (json['height'] as num?)?.toDouble() ?? 2.0,
      depth: (json['depth'] as num?)?.toDouble() ?? 6.5,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      blueprintX: (json['blueprintX'] as num?)?.toDouble() ?? 0.5,
      blueprintY: (json['blueprintY'] as num?)?.toDouble() ?? 0.5,
      color: json['color'] as String? ?? '#795548',
      wall: json['wall'] != null
          ? WallId.values.byName(json['wall'] as String)
          : null,
      positionFromEdge: (json['positionFromEdge'] as num?)?.toDouble() ?? 1.0,
      texturePath: json['texturePath'] as String?,
      variant: json['variant'] as String?,
      materialPreset: json['materialPreset'] as String?,
      heightFromFloor: (json['heightFromFloor'] as num?)?.toDouble() ??
          (type == FurnitureType.kitchenChimney ? 5.5 : 0),
    );
  }
}
