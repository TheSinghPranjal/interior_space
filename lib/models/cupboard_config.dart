import 'enums.dart';
import 'room_dimensions.dart';

class CupboardConfig {
  const CupboardConfig({
    required this.id,
    required this.wall,
    this.width = 6.0,
    this.height = 7.0,
    this.depth = 2.0,
    this.positionFromEdge = 1.0,
    this.rotation = 0,
    this.color = '#6D4C41',
    this.texture = CupboardTexture.laminate,
    this.texturePath,
    this.blueprintX = 0.5,
    this.blueprintY = 0.5,
  });

  final String id;
  final WallId wall;
  final double width;
  final double height;
  final double depth;
  final double positionFromEdge;
  final double rotation;
  final String color;
  final CupboardTexture texture;
  final String? texturePath;
  final double blueprintX;
  final double blueprintY;

  double positionFromLeftFt(RoomDimensions dims) =>
      blueprintX * dims.width - width / 2;

  double positionFromFrontFt(RoomDimensions dims) =>
      blueprintY * dims.length - depth / 2;

  CupboardConfig copyWith({
    WallId? wall,
    double? width,
    double? height,
    double? depth,
    double? positionFromEdge,
    double? rotation,
    String? color,
    CupboardTexture? texture,
    String? texturePath,
    double? blueprintX,
    double? blueprintY,
    bool clearTexture = false,
  }) {
    return CupboardConfig(
      id: id,
      wall: wall ?? this.wall,
      width: width ?? this.width,
      height: height ?? this.height,
      depth: depth ?? this.depth,
      positionFromEdge: positionFromEdge ?? this.positionFromEdge,
      rotation: rotation ?? this.rotation,
      color: color ?? this.color,
      texture: texture ?? this.texture,
      texturePath: clearTexture ? null : (texturePath ?? this.texturePath),
      blueprintX: blueprintX ?? this.blueprintX,
      blueprintY: blueprintY ?? this.blueprintY,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'wall': wall.name,
        'width': width,
        'height': height,
        'depth': depth,
        'positionFromEdge': positionFromEdge,
        'rotation': rotation,
        'color': color,
        'texture': texture.name,
        'texturePath': texturePath,
        'blueprintX': blueprintX,
        'blueprintY': blueprintY,
      };

  factory CupboardConfig.fromJson(Map<String, dynamic> json) {
    return CupboardConfig(
      id: json['id'] as String,
      wall: WallId.values.byName(json['wall'] as String),
      width: (json['width'] as num?)?.toDouble() ?? 6.0,
      height: (json['height'] as num?)?.toDouble() ?? 7.0,
      depth: (json['depth'] as num?)?.toDouble() ?? 2.0,
      positionFromEdge: (json['positionFromEdge'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      color: json['color'] as String? ?? '#6D4C41',
      texture: CupboardTexture.values.byName(
        json['texture'] as String? ?? 'laminate',
      ),
      texturePath: json['texturePath'] as String?,
      blueprintX: (json['blueprintX'] as num?)?.toDouble() ?? 0.5,
      blueprintY: (json['blueprintY'] as num?)?.toDouble() ?? 0.5,
    );
  }
}
