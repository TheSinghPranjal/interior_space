import '../core/constants/room_constants.dart';
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
  });

  final double width;
  final double length;
  final double height;
  final bool useCustomWallLengths;
  final double? customWallFront;
  final double? customWallBack;
  final double? customWallLeft;
  final double? customWallRight;

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
  double get effectiveWidth =>
      useCustomWallLengths
          ? mathMax(lengthForWall(WallId.front), lengthForWall(WallId.back))
          : width;

  /// Bounding length/depth for blueprint / placement.
  double get effectiveLength =>
      useCustomWallLengths
          ? mathMax(lengthForWall(WallId.left), lengthForWall(WallId.right))
          : length;

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
      };

  factory RoomDimensions.fromJson(Map<String, dynamic> json) {
    return RoomDimensions(
      width: (json['width'] as num?)?.toDouble() ?? RoomConstants.defaultWidth,
      length: (json['length'] as num?)?.toDouble() ?? RoomConstants.defaultLength,
      height: (json['height'] as num?)?.toDouble() ?? RoomConstants.defaultHeight,
      useCustomWallLengths: json['useCustomWallLengths'] as bool? ?? false,
      customWallFront: (json['customWallFront'] as num?)?.toDouble(),
      customWallBack: (json['customWallBack'] as num?)?.toDouble(),
      customWallLeft: (json['customWallLeft'] as num?)?.toDouble(),
      customWallRight: (json['customWallRight'] as num?)?.toDouble(),
    );
  }
}
