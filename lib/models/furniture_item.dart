import 'enums.dart';

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

  FurnitureItem copyWith({
    FurnitureType? type,
    double? width,
    double? height,
    double? depth,
    double? rotation,
    double? blueprintX,
    double? blueprintY,
    String? color,
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
    );
  }

  static FurnitureItem defaultForType(FurnitureType type, String id) {
    return switch (type) {
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
    );
  }
}
