import 'enums.dart';
import 'room_dimensions.dart';

class WallTvUnitConfig {
  const WallTvUnitConfig({
    required this.id,
    required this.wall,
    this.width = 5.0,
    this.height = 2.0,
    this.positionFromEdge = 2.0,
    this.rotation = 0,
    this.color = '#37474F',
  });

  final String id;
  final WallId wall;
  final double width;
  final double height;
  final double positionFromEdge;
  final double rotation;
  final String color;

  double wallLengthFt(RoomDimensions dims) => switch (wall) {
        WallId.front || WallId.back => dims.width,
        WallId.left || WallId.right => dims.length,
      };

  double maxPositionFromEdge(RoomDimensions dims) =>
      (wallLengthFt(dims) - width).clamp(0, wallLengthFt(dims)).toDouble();

  WallTvUnitConfig copyWith({
    WallId? wall,
    double? width,
    double? height,
    double? positionFromEdge,
    double? rotation,
    String? color,
  }) {
    return WallTvUnitConfig(
      id: id,
      wall: wall ?? this.wall,
      width: width ?? this.width,
      height: height ?? this.height,
      positionFromEdge: positionFromEdge ?? this.positionFromEdge,
      rotation: rotation ?? this.rotation,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'wall': wall.name,
        'width': width,
        'height': height,
        'positionFromEdge': positionFromEdge,
        'rotation': rotation,
        'color': color,
      };

  factory WallTvUnitConfig.fromJson(Map<String, dynamic> json) {
    return WallTvUnitConfig(
      id: json['id'] as String,
      wall: WallId.values.byName(json['wall'] as String),
      width: (json['width'] as num?)?.toDouble() ?? 5.0,
      height: (json['height'] as num?)?.toDouble() ?? 2.0,
      positionFromEdge: (json['positionFromEdge'] as num?)?.toDouble() ?? 2.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      color: json['color'] as String? ?? '#37474F',
    );
  }
}
