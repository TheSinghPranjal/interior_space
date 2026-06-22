import 'enums.dart';
import 'room_dimensions.dart';

class WallTvUnitConfig {
  const WallTvUnitConfig({
    required this.id,
    required this.wall,
    this.width = 5.0,
    this.height = 2.0,
    this.positionFromEdge = 2.0,
    this.positionFromFloor = 4.0,
    this.rotation = 0,
    this.color = '#37474F',
    this.texturePath,
  });

  final String id;
  final WallId wall;
  final double width;
  final double height;
  final double positionFromEdge;
  final double positionFromFloor;
  final double rotation;
  final String color;
  final String? texturePath;

  double wallLengthFt(RoomDimensions dims) => dims.lengthForWall(wall);

  double maxPositionFromEdge(RoomDimensions dims) =>
      (wallLengthFt(dims) - width).clamp(0, wallLengthFt(dims)).toDouble();

  WallTvUnitConfig copyWith({
    WallId? wall,
    double? width,
    double? height,
    double? positionFromEdge,
    double? positionFromFloor,
    double? rotation,
    String? color,
    String? texturePath,
    bool clearTexture = false,
  }) {
    return WallTvUnitConfig(
      id: id,
      wall: wall ?? this.wall,
      width: width ?? this.width,
      height: height ?? this.height,
      positionFromEdge: positionFromEdge ?? this.positionFromEdge,
      positionFromFloor: positionFromFloor ?? this.positionFromFloor,
      rotation: rotation ?? this.rotation,
      color: color ?? this.color,
      texturePath: clearTexture ? null : (texturePath ?? this.texturePath),
    );
  }

  static String displayLabel(List<WallTvUnitConfig> units, WallTvUnitConfig unit) {
    if (units.length <= 1) return 'Wall TV Unit';
    final index = units.indexWhere((u) => u.id == unit.id);
    if (index < 0) return 'Wall TV Unit';
    return 'Wall TV Unit ${index + 1}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'wall': wall.name,
        'width': width,
        'height': height,
        'positionFromEdge': positionFromEdge,
        'positionFromFloor': positionFromFloor,
        'rotation': rotation,
        'color': color,
        'texturePath': texturePath,
      };

  factory WallTvUnitConfig.fromJson(Map<String, dynamic> json) {
    return WallTvUnitConfig(
      id: json['id'] as String,
      wall: WallId.values.byName(json['wall'] as String),
      width: (json['width'] as num?)?.toDouble() ?? 5.0,
      height: (json['height'] as num?)?.toDouble() ?? 2.0,
      positionFromEdge: (json['positionFromEdge'] as num?)?.toDouble() ?? 2.0,
      positionFromFloor: (json['positionFromFloor'] as num?)?.toDouble() ?? 4.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      color: json['color'] as String? ?? '#37474F',
      texturePath: json['texturePath'] as String?,
    );
  }
}
