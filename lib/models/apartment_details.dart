enum ApartmentFacing {
  north,
  south,
  east,
  west,
  northEast,
  northWest,
  southEast,
  southWest,
}

extension ApartmentFacingLabel on ApartmentFacing {
  String get label => switch (this) {
        ApartmentFacing.north => 'North',
        ApartmentFacing.south => 'South',
        ApartmentFacing.east => 'East',
        ApartmentFacing.west => 'West',
        ApartmentFacing.northEast => 'North East',
        ApartmentFacing.northWest => 'North West',
        ApartmentFacing.southEast => 'South East',
        ApartmentFacing.southWest => 'South West',
      };
}

class ApartmentDetails {
  const ApartmentDetails({
    this.unitType = '',
    this.tower = '',
    this.superBuiltUpArea = '',
    this.carpetArea = '',
    this.blockName = '',
    this.block = '',
    this.facing,
    this.description = '',
  });

  final String unitType;
  final String tower;
  final String superBuiltUpArea;
  final String carpetArea;
  final String blockName;
  final String block;
  final ApartmentFacing? facing;
  final String description;

  bool get hasAny =>
      unitType.trim().isNotEmpty ||
      tower.trim().isNotEmpty ||
      superBuiltUpArea.trim().isNotEmpty ||
      carpetArea.trim().isNotEmpty ||
      blockName.trim().isNotEmpty ||
      block.trim().isNotEmpty ||
      facing != null ||
      description.trim().isNotEmpty;

  ApartmentDetails copyWith({
    String? unitType,
    String? tower,
    String? superBuiltUpArea,
    String? carpetArea,
    String? blockName,
    String? block,
    ApartmentFacing? facing,
    bool clearFacing = false,
    String? description,
  }) {
    return ApartmentDetails(
      unitType: unitType ?? this.unitType,
      tower: tower ?? this.tower,
      superBuiltUpArea: superBuiltUpArea ?? this.superBuiltUpArea,
      carpetArea: carpetArea ?? this.carpetArea,
      blockName: blockName ?? this.blockName,
      block: block ?? this.block,
      facing: clearFacing ? null : (facing ?? this.facing),
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'unitType': unitType,
        'tower': tower,
        'superBuiltUpArea': superBuiltUpArea,
        'carpetArea': carpetArea,
        'blockName': blockName,
        'block': block,
        if (facing != null) 'facing': facing!.name,
        'description': description,
      };

  factory ApartmentDetails.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ApartmentDetails();
    ApartmentFacing? facing;
    final facingName = json['facing'] as String?;
    if (facingName != null) {
      for (final value in ApartmentFacing.values) {
        if (value.name == facingName) {
          facing = value;
          break;
        }
      }
    }
    return ApartmentDetails(
      unitType: json['unitType'] as String? ?? '',
      tower: json['tower'] as String? ?? '',
      superBuiltUpArea: json['superBuiltUpArea'] as String? ?? '',
      carpetArea: json['carpetArea'] as String? ?? '',
      blockName: json['blockName'] as String? ?? '',
      block: json['block'] as String? ?? '',
      facing: facing,
      description: json['description'] as String? ?? '',
    );
  }
}
