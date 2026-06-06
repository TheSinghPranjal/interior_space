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

  bool get isWallMounted => type.isWallMounted;

  double effectiveWidthFt() =>
      BlueprintPlacement.effectiveWidthFt(width, depth, rotation);

  double effectiveDepthFt() =>
      BlueprintPlacement.effectiveDepthFt(width, depth, rotation);

  double positionFromLeftFt(RoomDimensions dims) =>
      blueprintX * dims.width - effectiveWidthFt() / 2;

  double positionFromFrontFt(RoomDimensions dims) =>
      blueprintY * dims.length - effectiveDepthFt() / 2;

  double maxPositionFromLeftFt(RoomDimensions dims) =>
      (dims.width - effectiveWidthFt()).clamp(0, dims.width).toDouble();

  double maxPositionFromFrontFt(RoomDimensions dims) =>
      (dims.length - effectiveDepthFt()).clamp(0, dims.length).toDouble();

  double blueprintXFromLeftFt(double leftFt, RoomDimensions dims) {
    final half = normalizedHalfExtents(dims).halfX;
    return ((leftFt + effectiveWidthFt() / 2) / dims.width).clamp(half, 1 - half);
  }

  double blueprintYFromFrontFt(double frontFt, RoomDimensions dims) {
    final half = normalizedHalfExtents(dims).halfY;
    return ((frontFt + effectiveDepthFt() / 2) / dims.length).clamp(half, 1 - half);
  }

  ({double halfX, double halfY}) normalizedHalfExtents(RoomDimensions dims) =>
      BlueprintPlacement.normalizedHalfExtents(
        widthFt: width,
        depthFt: depth,
        rotationDeg: rotation,
        roomWidthFt: dims.width,
        roomLengthFt: dims.length,
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
      FurnitureType.cupboard => FurnitureItem(
          id: id,
          type: type,
          width: 4.0,
          height: 3.0,
          depth: 1.5,
          color: '#8D6E63',
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
      };

  factory FurnitureItem.fromJson(Map<String, dynamic> json) {
    return FurnitureItem(
      id: json['id'] as String,
      type: FurnitureType.values.byName(json['type'] as String),
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
    );
  }
}
