import '../core/utils/blueprint_placement.dart';
import 'enums.dart';
import 'furniture_item.dart';
import 'room_dimensions.dart';
import 'wall_tv_unit_config.dart';

/// Pasteable configuration for a floor or wall-mounted furniture item (excludes [id]).
class FurnitureConfigSnapshot {
  const FurnitureConfigSnapshot({
    required this.type,
    required this.width,
    required this.height,
    required this.depth,
    required this.rotation,
    required this.blueprintX,
    required this.blueprintY,
    required this.color,
    this.wall,
    required this.positionFromEdge,
    this.texturePath,
    this.variant,
    this.materialPreset,
    required this.heightFromFloor,
  });

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
  final String? variant;
  final String? materialPreset;
  final double heightFromFloor;

  factory FurnitureConfigSnapshot.from(FurnitureItem item) {
    return FurnitureConfigSnapshot(
      type: item.type,
      width: item.width,
      height: item.height,
      depth: item.depth,
      rotation: item.rotation,
      blueprintX: item.blueprintX,
      blueprintY: item.blueprintY,
      color: item.color,
      wall: item.wall,
      positionFromEdge: item.positionFromEdge,
      texturePath: item.texturePath,
      variant: item.variant,
      materialPreset: item.materialPreset,
      heightFromFloor: item.heightFromFloor,
    );
  }

  FurnitureItem applyTo(FurnitureItem target, RoomDimensions dims) {
    assert(target.type == type, 'Cannot paste ${type.label} config onto ${target.type.label}');

    if (target.isWallMounted) {
      final updated = target.copyWith(
        width: width,
        height: height,
        depth: depth,
        rotation: rotation,
        color: color,
        wall: wall ?? target.wall,
        positionFromEdge: positionFromEdge,
        texturePath: texturePath,
        clearTexture: texturePath == null,
        variant: variant,
        clearVariant: variant == null,
        materialPreset: materialPreset,
        clearMaterialPreset: materialPreset == null,
        heightFromFloor: heightFromFloor,
      );
      final maxEdge = _maxWallEdge(updated, dims);
      return updated.copyWith(
        positionFromEdge: updated.positionFromEdge.clamp(0, maxEdge).toDouble(),
      );
    }

    final clamped = BlueprintPlacement.clampBlueprintCenter(
      centerXNorm: blueprintX,
      centerYNorm: blueprintY,
      widthFt: width,
      depthFt: depth,
      rotationDeg: rotation,
      roomWidthFt: dims.effectiveWidth,
      roomLengthFt: dims.effectiveLength,
    );

    return target.copyWith(
      width: width,
      height: height,
      depth: depth,
      rotation: rotation,
      blueprintX: clamped.bx,
      blueprintY: clamped.by,
      color: color,
      clearWall: true,
      texturePath: texturePath,
      clearTexture: texturePath == null,
      variant: variant,
      clearVariant: variant == null,
      materialPreset: materialPreset,
      clearMaterialPreset: materialPreset == null,
      heightFromFloor: heightFromFloor,
    );
  }

  static double _maxWallEdge(FurnitureItem item, RoomDimensions dims) {
    final wallLen = dims.lengthForWall(item.wall ?? WallId.left);
    return (wallLen - item.width).clamp(0, wallLen).toDouble();
  }
}

/// Pasteable configuration for a wall TV unit (excludes [id]).
class WallTvUnitConfigSnapshot {
  const WallTvUnitConfigSnapshot({
    required this.wall,
    required this.width,
    required this.height,
    required this.positionFromEdge,
    required this.positionFromFloor,
    required this.rotation,
    required this.color,
    this.texturePath,
  });

  final WallId wall;
  final double width;
  final double height;
  final double positionFromEdge;
  final double positionFromFloor;
  final double rotation;
  final String color;
  final String? texturePath;

  factory WallTvUnitConfigSnapshot.from(WallTvUnitConfig unit) {
    return WallTvUnitConfigSnapshot(
      wall: unit.wall,
      width: unit.width,
      height: unit.height,
      positionFromEdge: unit.positionFromEdge,
      positionFromFloor: unit.positionFromFloor,
      rotation: unit.rotation,
      color: unit.color,
      texturePath: unit.texturePath,
    );
  }

  WallTvUnitConfig applyTo(WallTvUnitConfig target, RoomDimensions dims) {
    final updated = target.copyWith(
      wall: wall,
      width: width,
      height: height,
      positionFromEdge: positionFromEdge,
      positionFromFloor: positionFromFloor,
      rotation: rotation,
      color: color,
      texturePath: texturePath,
      clearTexture: texturePath == null,
    );
    final maxEdge = updated.maxPositionFromEdge(dims);
    return updated.copyWith(
      positionFromEdge: updated.positionFromEdge.clamp(0, maxEdge).toDouble(),
    );
  }
}
