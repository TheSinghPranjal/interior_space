import 'enums.dart';
import '../core/constants/room_constants.dart';

class FloorConfig {
  const FloorConfig({
    this.surfaceType = SurfaceType.solidColor,
    this.color = '#C4A77D',
    this.pattern = FloorPattern.grid,
    this.tileLength = RoomConstants.defaultTileLength,
    this.tileWidth = RoomConstants.defaultTileWidth,
    this.material = FloorMaterial.ceramic,
    this.texturePath,
    this.reflection = 0.3,
    this.roughness = 0.6,
  });

  final SurfaceType surfaceType;
  final String color;
  final FloorPattern pattern;
  final double tileLength;
  final double tileWidth;
  final FloorMaterial material;
  final String? texturePath;
  final double reflection;
  final double roughness;

  FloorConfig copyWith({
    SurfaceType? surfaceType,
    String? color,
    FloorPattern? pattern,
    double? tileLength,
    double? tileWidth,
    FloorMaterial? material,
    String? texturePath,
    double? reflection,
    double? roughness,
    bool clearTexture = false,
  }) {
    return FloorConfig(
      surfaceType: surfaceType ?? this.surfaceType,
      color: color ?? this.color,
      pattern: pattern ?? this.pattern,
      tileLength: tileLength ?? this.tileLength,
      tileWidth: tileWidth ?? this.tileWidth,
      material: material ?? this.material,
      texturePath: clearTexture ? null : (texturePath ?? this.texturePath),
      reflection: reflection ?? this.reflection,
      roughness: roughness ?? this.roughness,
    );
  }

  Map<String, dynamic> toJson() => {
        'surfaceType': surfaceType.name,
        'color': color,
        'pattern': pattern.name,
        'tileLength': tileLength,
        'tileWidth': tileWidth,
        'material': material.name,
        'texturePath': texturePath,
        'reflection': reflection,
        'roughness': roughness,
      };

  factory FloorConfig.fromJson(Map<String, dynamic> json) {
    return FloorConfig(
      surfaceType: SurfaceType.values.byName(
        json['surfaceType'] as String? ?? 'solidColor',
      ),
      color: json['color'] as String? ?? '#C4A77D',
      pattern: FloorPattern.values.byName(
        json['pattern'] as String? ?? 'grid',
      ),
      tileLength: (json['tileLength'] as num?)?.toDouble() ??
          RoomConstants.defaultTileLength,
      tileWidth: (json['tileWidth'] as num?)?.toDouble() ??
          RoomConstants.defaultTileWidth,
      material: FloorMaterial.values.byName(
        json['material'] as String? ?? 'ceramic',
      ),
      texturePath: json['texturePath'] as String?,
      reflection: (json['reflection'] as num?)?.toDouble() ?? 0.3,
      roughness: (json['roughness'] as num?)?.toDouble() ?? 0.6,
    );
  }
}
