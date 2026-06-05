import 'enums.dart';

class CeilingConfig {
  const CeilingConfig({
    this.color = '#FAFAFA',
    this.material = CeilingMaterial.matte,
    this.texturePath,
    this.falseCeilingEnabled = false,
    this.falseCeilingType = FalseCeilingType.none,
    this.falseCeilingDepth = 1.0,
    this.falseCeilingThickness = 0.5,
    this.falseCeilingColor = '#FFFFFF',
  });

  final String color;
  final CeilingMaterial material;
  final String? texturePath;
  final bool falseCeilingEnabled;
  final FalseCeilingType falseCeilingType;
  final double falseCeilingDepth;
  final double falseCeilingThickness;
  final String falseCeilingColor;

  CeilingConfig copyWith({
    String? color,
    CeilingMaterial? material,
    String? texturePath,
    bool? falseCeilingEnabled,
    FalseCeilingType? falseCeilingType,
    double? falseCeilingDepth,
    double? falseCeilingThickness,
    String? falseCeilingColor,
    bool clearTexture = false,
  }) {
    return CeilingConfig(
      color: color ?? this.color,
      material: material ?? this.material,
      texturePath: clearTexture ? null : (texturePath ?? this.texturePath),
      falseCeilingEnabled: falseCeilingEnabled ?? this.falseCeilingEnabled,
      falseCeilingType: falseCeilingType ?? this.falseCeilingType,
      falseCeilingDepth: falseCeilingDepth ?? this.falseCeilingDepth,
      falseCeilingThickness:
          falseCeilingThickness ?? this.falseCeilingThickness,
      falseCeilingColor: falseCeilingColor ?? this.falseCeilingColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'color': color,
        'material': material.name,
        'texturePath': texturePath,
        'falseCeilingEnabled': falseCeilingEnabled,
        'falseCeilingType': falseCeilingType.name,
        'falseCeilingDepth': falseCeilingDepth,
        'falseCeilingThickness': falseCeilingThickness,
        'falseCeilingColor': falseCeilingColor,
      };

  factory CeilingConfig.fromJson(Map<String, dynamic> json) {
    return CeilingConfig(
      color: json['color'] as String? ?? '#FAFAFA',
      material: CeilingMaterial.values.byName(
        json['material'] as String? ?? 'matte',
      ),
      texturePath: json['texturePath'] as String?,
      falseCeilingEnabled: json['falseCeilingEnabled'] as bool? ?? false,
      falseCeilingType: FalseCeilingType.values.byName(
        json['falseCeilingType'] as String? ?? 'none',
      ),
      falseCeilingDepth: (json['falseCeilingDepth'] as num?)?.toDouble() ?? 1.0,
      falseCeilingThickness:
          (json['falseCeilingThickness'] as num?)?.toDouble() ?? 0.5,
      falseCeilingColor: json['falseCeilingColor'] as String? ?? '#FFFFFF',
    );
  }
}
