import 'enums.dart';
import 'room_dimensions.dart';

class AcUnitConfig {
  const AcUnitConfig({
    required this.id,
    required this.wall,
    this.width = 3.0,
    this.height = 1.0,
    this.positionFromEdge = 3.0,
    this.positionFromFloor = 7.0,
    this.rotation = 0,
    this.color = '#F5F5F5',
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

  double wallLengthFt(RoomDimensions dims) => switch (wall) {
        WallId.front || WallId.back => dims.width,
        WallId.left || WallId.right => dims.length,
      };

  double maxPositionFromEdge(RoomDimensions dims) =>
      (wallLengthFt(dims) - width).clamp(0, wallLengthFt(dims)).toDouble();

  AcUnitConfig copyWith({
    WallId? wall,
    double? width,
    double? height,
    double? positionFromEdge,
    double? positionFromFloor,
    double? rotation,
    String? color,
    String? texturePath,
  }) {
    return AcUnitConfig(
      id: id,
      wall: wall ?? this.wall,
      width: width ?? this.width,
      height: height ?? this.height,
      positionFromEdge: positionFromEdge ?? this.positionFromEdge,
      positionFromFloor: positionFromFloor ?? this.positionFromFloor,
      rotation: rotation ?? this.rotation,
      color: color ?? this.color,
      texturePath: texturePath ?? this.texturePath,
    );
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

  factory AcUnitConfig.fromJson(Map<String, dynamic> json) {
    return AcUnitConfig(
      id: json['id'] as String,
      wall: WallId.values.byName(json['wall'] as String),
      width: (json['width'] as num?)?.toDouble() ?? 3.0,
      height: (json['height'] as num?)?.toDouble() ?? 1.0,
      positionFromEdge: (json['positionFromEdge'] as num?)?.toDouble() ?? 3.0,
      positionFromFloor: (json['positionFromFloor'] as num?)?.toDouble() ?? 7.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      color: json['color'] as String? ?? '#F5F5F5',
      texturePath: json['texturePath'] as String?,
    );
  }
}
