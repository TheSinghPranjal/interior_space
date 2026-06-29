import '../core/constants/room_constants.dart';
import '../core/utils/room_geometry.dart';
import 'enums.dart';

class RoomDimensions {
  const RoomDimensions({
    this.width = RoomConstants.defaultWidth,
    this.length = RoomConstants.defaultLength,
    this.height = RoomConstants.defaultHeight,
    this.useCustomWallLengths = false,
    this.customWallFront,
    this.customWallBack,
    this.customWallLeft,
    this.customWallRight,
    this.shapeMode = RoomShapeMode.rectangular,
    this.polygonVertices = const [],
  });

  final double width;
  final double length;
  final double height;
  final bool useCustomWallLengths;
  final double? customWallFront;
  final double? customWallBack;
  final double? customWallLeft;
  final double? customWallRight;
  final RoomShapeMode shapeMode;
  /// Corner points in feet on the custom room grid (absolute coordinates before normalize).
  final List<RoomCorner> polygonVertices;

  bool get isPolygon =>
      shapeMode == RoomShapeMode.polygon && polygonVertices.length >= RoomConstants.minPolygonWalls;

  List<RoomCorner> get normalizedPolygonVertices {
    if (!isPolygon) return const [];
    final xs = polygonVertices.map((v) => v.x);
    final ys = polygonVertices.map((v) => v.y);
    final minX = xs.reduce((a, b) => a < b ? a : b);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    return polygonVertices.map((v) => RoomCorner(v.x - minX, v.y - minY)).toList();
  }

  /// Effective length of a wall in feet.
  double lengthForWall(WallId wall) {
    if (!useCustomWallLengths) {
      return switch (wall) {
        WallId.front || WallId.back => width,
        WallId.left || WallId.right => length,
      };
    }
    return switch (wall) {
      WallId.front => customWallFront ?? width,
      WallId.back => customWallBack ?? width,
      WallId.left => customWallLeft ?? length,
      WallId.right => customWallRight ?? length,
    };
  }

  /// Bounding width for blueprint / placement (max of front/back in custom mode).
  double get effectiveWidth {
    if (isPolygon) {
      final verts = normalizedPolygonVertices;
      if (verts.isEmpty) return width;
      final xs = verts.map((v) => v.x);
      return xs.reduce((a, b) => a > b ? a : b);
    }
    return useCustomWallLengths
        ? mathMax(lengthForWall(WallId.front), lengthForWall(WallId.back))
        : width;
  }

  /// Bounding length/depth for blueprint / placement.
  double get effectiveLength {
    if (isPolygon) {
      final verts = normalizedPolygonVertices;
      if (verts.isEmpty) return length;
      final ys = verts.map((v) => v.y);
      return ys.reduce((a, b) => a > b ? a : b);
    }
    return useCustomWallLengths
        ? mathMax(lengthForWall(WallId.left), lengthForWall(WallId.right))
        : length;
  }

  static double mathMax(double a, double b) => a > b ? a : b;

  RoomDimensions copyWith({
    double? width,
    double? length,
    double? height,
    bool? useCustomWallLengths,
    double? customWallFront,
    double? customWallBack,
    double? customWallLeft,
    double? customWallRight,
    bool clearCustomWalls = false,
    RoomShapeMode? shapeMode,
    List<RoomCorner>? polygonVertices,
    bool clearPolygon = false,
  }) {
    return RoomDimensions(
      width: width ?? this.width,
      length: length ?? this.length,
      height: height ?? this.height,
      useCustomWallLengths: useCustomWallLengths ?? this.useCustomWallLengths,
      customWallFront: clearCustomWalls
          ? null
          : (customWallFront ?? this.customWallFront),
      customWallBack:
          clearCustomWalls ? null : (customWallBack ?? this.customWallBack),
      customWallLeft:
          clearCustomWalls ? null : (customWallLeft ?? this.customWallLeft),
      customWallRight:
          clearCustomWalls ? null : (customWallRight ?? this.customWallRight),
      shapeMode: shapeMode ?? this.shapeMode,
      polygonVertices: clearPolygon
          ? const []
          : (polygonVertices ?? this.polygonVertices),
    );
  }

  /// Sync custom wall values from standard width/length.
  RoomDimensions withSyncedCustomWalls() {
    return copyWith(
      customWallFront: width,
      customWallBack: width,
      customWallLeft: length,
      customWallRight: length,
    );
  }

  RoomDimensions clamped() {
    return RoomDimensions(
      width: width.clamp(RoomConstants.minWidth, RoomConstants.maxWidth),
      length: length.clamp(RoomConstants.minLength, RoomConstants.maxLength),
      height: height.clamp(RoomConstants.minHeight, RoomConstants.maxHeight),
      useCustomWallLengths: useCustomWallLengths,
      customWallFront: customWallFront?.clamp(RoomConstants.minWidth, RoomConstants.maxWidth),
      customWallBack: customWallBack?.clamp(RoomConstants.minWidth, RoomConstants.maxWidth),
      customWallLeft: customWallLeft?.clamp(RoomConstants.minLength, RoomConstants.maxLength),
      customWallRight: customWallRight?.clamp(RoomConstants.minLength, RoomConstants.maxLength),
      shapeMode: shapeMode,
      polygonVertices: polygonVertices,
    );
  }

  Map<String, dynamic> toJson() => {
        'width': width,
        'length': length,
        'height': height,
        'useCustomWallLengths': useCustomWallLengths,
        if (customWallFront != null) 'customWallFront': customWallFront,
        if (customWallBack != null) 'customWallBack': customWallBack,
        if (customWallLeft != null) 'customWallLeft': customWallLeft,
        if (customWallRight != null) 'customWallRight': customWallRight,
        'shapeMode': shapeMode.name,
        if (polygonVertices.isNotEmpty)
          'polygonVertices': polygonVertices
              .map((v) => {'x': v.x, 'y': v.y})
              .toList(),
      };

  factory RoomDimensions.fromJson(Map<String, dynamic> json) {
    final polygonRaw = json['polygonVertices'] as List<dynamic>?;
    final vertices = polygonRaw
            ?.map(
              (e) => RoomCorner(
                (e['x'] as num).toDouble(),
                (e['y'] as num).toDouble(),
              ),
            )
            .toList() ??
        const <RoomCorner>[];

    final shapeModeName = json['shapeMode'] as String?;
    final shapeMode = shapeModeName != null
        ? RoomShapeMode.values.byName(shapeModeName)
        : (vertices.length >= RoomConstants.minPolygonWalls
            ? RoomShapeMode.polygon
            : RoomShapeMode.rectangular);

    return RoomDimensions(
      width: (json['width'] as num?)?.toDouble() ?? RoomConstants.defaultWidth,
      length: (json['length'] as num?)?.toDouble() ?? RoomConstants.defaultLength,
      height: (json['height'] as num?)?.toDouble() ?? RoomConstants.defaultHeight,
      useCustomWallLengths: json['useCustomWallLengths'] as bool? ?? false,
      customWallFront: (json['customWallFront'] as num?)?.toDouble(),
      customWallBack: (json['customWallBack'] as num?)?.toDouble(),
      customWallLeft: (json['customWallLeft'] as num?)?.toDouble(),
      customWallRight: (json['customWallRight'] as num?)?.toDouble(),
      shapeMode: shapeMode,
      polygonVertices: vertices,
    );
  }
}
