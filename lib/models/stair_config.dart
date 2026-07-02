import '../core/utils/blueprint_placement.dart';
import 'enums.dart';
import 'room_dimensions.dart';

class StairConfig {
  const StairConfig({
    required this.id,
    this.width = 3.5,
    this.height = 9.0,
    this.depth = 10.0,
    this.rotation = 0,
    this.blueprintX = 0.5,
    this.blueprintY = 0.5,
    this.stepCount = 10,
    this.color = '#8D6E63',
    this.shape = StairShape.straight,
    this.materialPreset = StairMaterialPreset.wood,
    this.texturePath,
    this.showLeftRailing = true,
    this.showRightRailing = true,
  });

  final String id;
  final double width;
  final double height;
  final double depth;
  final double rotation;
  final double blueprintX;
  final double blueprintY;
  final int stepCount;
  final String color;
  final StairShape shape;
  final StairMaterialPreset materialPreset;
  final String? texturePath;
  final bool showLeftRailing;
  final bool showRightRailing;

  int get safeStepCount => stepCount.clamp(2, 30);

  double get risePerStep => height / safeStepCount;

  double get treadDepth => depth / safeStepCount;

  static String displayLabel(List<StairConfig> stairs, StairConfig stair) {
    if (stairs.length <= 1) return 'Stairs';
    final index = stairs.indexWhere((s) => s.id == stair.id);
    if (index < 0) return 'Stairs';
    return 'Stairs ${index + 1}';
  }

  double effectiveWidthFt() =>
      BlueprintPlacement.effectiveWidthFt(width, depth, rotation);

  double effectiveDepthFt() =>
      BlueprintPlacement.effectiveDepthFt(width, depth, rotation);

  double positionFromLeftFt(RoomDimensions dims) =>
      blueprintX * dims.effectiveWidth - effectiveWidthFt() / 2;

  double positionFromFrontFt(RoomDimensions dims) =>
      blueprintY * dims.effectiveLength - effectiveDepthFt() / 2;

  double maxPositionFromLeftFt(RoomDimensions dims) =>
      (dims.effectiveWidth - effectiveWidthFt()).clamp(0, dims.effectiveWidth).toDouble();

  double maxPositionFromFrontFt(RoomDimensions dims) =>
      (dims.effectiveLength - effectiveDepthFt()).clamp(0, dims.effectiveLength).toDouble();

  double blueprintXFromLeftFt(double leftFt, RoomDimensions dims) {
    final half = normalizedHalfExtents(dims).halfX;
    return ((leftFt + effectiveWidthFt() / 2) / dims.effectiveWidth).clamp(half, 1 - half);
  }

  double blueprintYFromFrontFt(double frontFt, RoomDimensions dims) {
    final half = normalizedHalfExtents(dims).halfY;
    return ((frontFt + effectiveDepthFt() / 2) / dims.effectiveLength).clamp(half, 1 - half);
  }

  ({double halfX, double halfY}) normalizedHalfExtents(RoomDimensions dims) =>
      BlueprintPlacement.normalizedHalfExtents(
        widthFt: width,
        depthFt: depth,
        rotationDeg: rotation,
        roomWidthFt: dims.effectiveWidth,
        roomLengthFt: dims.effectiveLength,
      );

  StairConfig copyWith({
    double? width,
    double? height,
    double? depth,
    double? rotation,
    double? blueprintX,
    double? blueprintY,
    int? stepCount,
    String? color,
    StairShape? shape,
    StairMaterialPreset? materialPreset,
    String? texturePath,
    bool clearTexture = false,
    bool? showLeftRailing,
    bool? showRightRailing,
  }) {
    return StairConfig(
      id: id,
      width: width ?? this.width,
      height: height ?? this.height,
      depth: depth ?? this.depth,
      rotation: rotation ?? this.rotation,
      blueprintX: blueprintX ?? this.blueprintX,
      blueprintY: blueprintY ?? this.blueprintY,
      stepCount: stepCount ?? this.stepCount,
      color: color ?? this.color,
      shape: shape ?? this.shape,
      materialPreset: materialPreset ?? this.materialPreset,
      texturePath: clearTexture ? null : (texturePath ?? this.texturePath),
      showLeftRailing: showLeftRailing ?? this.showLeftRailing,
      showRightRailing: showRightRailing ?? this.showRightRailing,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'width': width,
        'height': height,
        'depth': depth,
        'rotation': rotation,
        'blueprintX': blueprintX,
        'blueprintY': blueprintY,
        'stepCount': stepCount,
        'color': color,
        'shape': shape.name,
        'materialPreset': materialPreset.name,
        'texturePath': texturePath,
        'showLeftRailing': showLeftRailing,
        'showRightRailing': showRightRailing,
      };

  factory StairConfig.fromJson(Map<String, dynamic> json) {
    return StairConfig(
      id: json['id'] as String,
      width: (json['width'] as num?)?.toDouble() ?? 3.5,
      height: (json['height'] as num?)?.toDouble() ?? 9.0,
      depth: (json['depth'] as num?)?.toDouble() ?? 10.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      blueprintX: (json['blueprintX'] as num?)?.toDouble() ?? 0.5,
      blueprintY: (json['blueprintY'] as num?)?.toDouble() ?? 0.5,
      stepCount: (json['stepCount'] as num?)?.toInt() ?? 10,
      color: json['color'] as String? ?? '#8D6E63',
      shape: StairShape.values.firstWhere(
        (s) => s.name == json['shape'],
        orElse: () => StairShape.straight,
      ),
      materialPreset: StairMaterialPreset.values.firstWhere(
        (m) => m.name == json['materialPreset'],
        orElse: () => StairMaterialPreset.wood,
      ),
      texturePath: json['texturePath'] as String?,
      showLeftRailing: json['showLeftRailing'] as bool? ?? true,
      showRightRailing: json['showRightRailing'] as bool? ?? true,
    );
  }

  static StairConfig initial(String id, RoomDimensions dims) {
    return StairConfig(
      id: id,
      height: dims.height.clamp(5, 20).toDouble(),
      stepCount: dims.height.round().clamp(4, 16),
    );
  }
}
