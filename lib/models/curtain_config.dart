import 'package:flutter/material.dart';

import 'enums.dart';
import 'room_dimensions.dart';

enum CurtainState { open, closed }

class CurtainConfig {
  const CurtainConfig({
    required this.id,
    required this.wall,
    this.width = 4.0,
    this.height = 6.0,
    this.positionFromEdge = 3.0,
    this.positionFromFloor = 0.5,
    this.rotation = 0,
    this.color = '#8D6E63',
    this.state = CurtainState.open,
  });

  final String id;
  final WallId wall;
  final double width;
  final double height;
  final double positionFromEdge;
  final double positionFromFloor;
  final double rotation;
  final String color;
  final CurtainState state;

  double wallLengthFt(RoomDimensions dims) => dims.lengthForWall(wall);

  double maxPositionFromEdge(RoomDimensions dims) =>
      (wallLengthFt(dims) - width).clamp(0, wallLengthFt(dims)).toDouble();

  CurtainConfig copyWith({
    WallId? wall,
    double? width,
    double? height,
    double? positionFromEdge,
    double? positionFromFloor,
    double? rotation,
    String? color,
    CurtainState? state,
  }) {
    return CurtainConfig(
      id: id,
      wall: wall ?? this.wall,
      width: width ?? this.width,
      height: height ?? this.height,
      positionFromEdge: positionFromEdge ?? this.positionFromEdge,
      positionFromFloor: positionFromFloor ?? this.positionFromFloor,
      rotation: rotation ?? this.rotation,
      color: color ?? this.color,
      state: state ?? this.state,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'wall': wall.name,
        'width': width,
        'height': height,
        'positionFromEdge': positionFromEdge,
        'positionFromFloor': positionFromFloor,
        'rotation': rotation,
        'color': color,
        'state': state.name,
      };

  factory CurtainConfig.fromJson(Map<String, dynamic> json) {
    return CurtainConfig(
      id: json['id'] as String,
      wall: WallId.values.byName(json['wall'] as String),
      width: (json['width'] as num?)?.toDouble() ?? 4.0,
      height: (json['height'] as num?)?.toDouble() ?? 6.0,
      positionFromEdge: (json['positionFromEdge'] as num?)?.toDouble() ?? 3.0,
      positionFromFloor: (json['positionFromFloor'] as num?)?.toDouble() ?? 0.5,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      color: json['color'] as String? ?? '#8D6E63',
      state: CurtainState.values.byName(json['state'] as String? ?? 'open'),
    );
  }
}

extension CurtainStateLabel on CurtainState {
  String get label => switch (this) {
        CurtainState.open => 'Open',
        CurtainState.closed => 'Closed',
      };

  IconData get icon => switch (this) {
        CurtainState.open => Icons.curtains,
        CurtainState.closed => Icons.curtains_closed,
      };
}
