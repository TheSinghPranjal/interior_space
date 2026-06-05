import 'enums.dart';
import '../core/constants/room_constants.dart';

class DoorConfig {
  const DoorConfig({
    required this.id,
    required this.wall,
    this.width = RoomConstants.defaultDoorWidth,
    this.height = RoomConstants.defaultDoorHeight,
    this.positionFromEdge = 2.0,
    this.color = '#8B5E3C',
    this.material = DoorMaterial.wood,
    this.texturePath,
  });

  final String id;
  final WallId wall;
  final double width;
  final double height;
  final double positionFromEdge;
  final String color;
  final DoorMaterial material;
  final String? texturePath;

  DoorConfig copyWith({
    WallId? wall,
    double? width,
    double? height,
    double? positionFromEdge,
    String? color,
    DoorMaterial? material,
    String? texturePath,
    bool clearTexture = false,
  }) {
    return DoorConfig(
      id: id,
      wall: wall ?? this.wall,
      width: width ?? this.width,
      height: height ?? this.height,
      positionFromEdge: positionFromEdge ?? this.positionFromEdge,
      color: color ?? this.color,
      material: material ?? this.material,
      texturePath: clearTexture ? null : (texturePath ?? this.texturePath),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'wall': wall.name,
        'width': width,
        'height': height,
        'positionFromEdge': positionFromEdge,
        'color': color,
        'material': material.name,
        'texturePath': texturePath,
      };

  factory DoorConfig.fromJson(Map<String, dynamic> json) {
    return DoorConfig(
      id: json['id'] as String,
      wall: WallId.values.byName(json['wall'] as String),
      width: (json['width'] as num?)?.toDouble() ??
          RoomConstants.defaultDoorWidth,
      height: (json['height'] as num?)?.toDouble() ??
          RoomConstants.defaultDoorHeight,
      positionFromEdge: (json['positionFromEdge'] as num?)?.toDouble() ?? 2.0,
      color: json['color'] as String? ?? '#8B5E3C',
      material: DoorMaterial.values.byName(
        json['material'] as String? ?? 'wood',
      ),
      texturePath: json['texturePath'] as String?,
    );
  }
}
