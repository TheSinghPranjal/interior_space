import 'enums.dart';
import '../core/constants/room_constants.dart';
import 'room_dimensions.dart';

class DoorConfig {
  const DoorConfig({
    required this.id,
    required this.wall,
    this.width = RoomConstants.defaultDoorWidth,
    this.height = RoomConstants.defaultDoorHeight,
    this.positionFromEdge = 2.0,
    this.rotation = 0,
    this.color = '#8B5E3C',
    this.material = DoorMaterial.wood,
    this.texturePath,
  });

  final String id;
  final WallId wall;
  final double width;
  final double height;
  final double positionFromEdge;
  final double rotation;
  final String color;
  final DoorMaterial material;
  final String? texturePath;

  double wallLengthFt(RoomDimensions dims) => dims.lengthForWall(wall);

  double maxPositionFromEdge(RoomDimensions dims) =>
      (wallLengthFt(dims) - width).clamp(0, wallLengthFt(dims)).toDouble();

  /// "Door" alone, or "Door 1", "Door 2" when multiples exist.
  static String displayLabel(List<DoorConfig> doors, DoorConfig door) {
    if (doors.length <= 1) return 'Door';
    final index = doors.indexWhere((d) => d.id == door.id);
    if (index < 0) return 'Door';
    return 'Door ${index + 1}';
  }

  DoorConfig copyWith({
    WallId? wall,
    double? width,
    double? height,
    double? positionFromEdge,
    double? rotation,
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
      rotation: rotation ?? this.rotation,
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
        'rotation': rotation,
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
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      color: json['color'] as String? ?? '#8B5E3C',
      material: DoorMaterial.values.byName(
        json['material'] as String? ?? 'wood',
      ),
      texturePath: json['texturePath'] as String?,
    );
  }
}
