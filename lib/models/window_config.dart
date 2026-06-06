import 'enums.dart';
import 'room_dimensions.dart';

class WindowConfig {
  const WindowConfig({
    required this.id,
    required this.wall,
    this.width = 4.0,
    this.height = 4.0,
    this.positionFromEdge = 3.0,
    this.positionFromFloor = 3.0,
    this.rotation = 0,
    this.glassColor = '#B3E5FC',
    this.frameColor = '#FFFFFF',
  });

  final String id;
  final WallId wall;
  final double width;
  final double height;
  final double positionFromEdge;
  final double positionFromFloor;
  final double rotation;
  final String glassColor;
  final String frameColor;

  double wallLengthFt(RoomDimensions dims) => switch (wall) {
        WallId.front || WallId.back => dims.width,
        WallId.left || WallId.right => dims.length,
      };

  double maxPositionFromEdge(RoomDimensions dims) =>
      (wallLengthFt(dims) - width).clamp(0, wallLengthFt(dims)).toDouble();

  WindowConfig copyWith({
    WallId? wall,
    double? width,
    double? height,
    double? positionFromEdge,
    double? positionFromFloor,
    double? rotation,
    String? glassColor,
    String? frameColor,
  }) {
    return WindowConfig(
      id: id,
      wall: wall ?? this.wall,
      width: width ?? this.width,
      height: height ?? this.height,
      positionFromEdge: positionFromEdge ?? this.positionFromEdge,
      positionFromFloor: positionFromFloor ?? this.positionFromFloor,
      rotation: rotation ?? this.rotation,
      glassColor: glassColor ?? this.glassColor,
      frameColor: frameColor ?? this.frameColor,
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
        'glassColor': glassColor,
        'frameColor': frameColor,
      };

  factory WindowConfig.fromJson(Map<String, dynamic> json) {
    return WindowConfig(
      id: json['id'] as String,
      wall: WallId.values.byName(json['wall'] as String),
      width: (json['width'] as num?)?.toDouble() ?? 4.0,
      height: (json['height'] as num?)?.toDouble() ?? 4.0,
      positionFromEdge: (json['positionFromEdge'] as num?)?.toDouble() ?? 3.0,
      positionFromFloor: (json['positionFromFloor'] as num?)?.toDouble() ?? 3.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      glassColor: json['glassColor'] as String? ?? '#B3E5FC',
      frameColor: json['frameColor'] as String? ?? '#FFFFFF',
    );
  }
}
