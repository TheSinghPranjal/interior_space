import '../core/constants/room_constants.dart';

class RoomDimensions {
  const RoomDimensions({
    this.width = RoomConstants.defaultWidth,
    this.length = RoomConstants.defaultLength,
    this.height = RoomConstants.defaultHeight,
  });

  final double width;
  final double length;
  final double height;

  RoomDimensions copyWith({double? width, double? length, double? height}) {
    return RoomDimensions(
      width: width ?? this.width,
      length: length ?? this.length,
      height: height ?? this.height,
    );
  }

  RoomDimensions clamped() {
    return RoomDimensions(
      width: width.clamp(RoomConstants.minWidth, RoomConstants.maxWidth),
      length: length.clamp(RoomConstants.minLength, RoomConstants.maxLength),
      height: height.clamp(RoomConstants.minHeight, RoomConstants.maxHeight),
    );
  }

  Map<String, dynamic> toJson() => {
        'width': width,
        'length': length,
        'height': height,
      };

  factory RoomDimensions.fromJson(Map<String, dynamic> json) {
    return RoomDimensions(
      width: (json['width'] as num?)?.toDouble() ?? RoomConstants.defaultWidth,
      length: (json['length'] as num?)?.toDouble() ?? RoomConstants.defaultLength,
      height: (json['height'] as num?)?.toDouble() ?? RoomConstants.defaultHeight,
    );
  }
}
