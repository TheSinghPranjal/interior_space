import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../models/room_design.dart';
import '../../models/room_dimensions.dart';
import '../../models/wall_config.dart';

/// Shared blueprint wall-outline drawing (respects custom wall mode + visibility).
abstract final class BlueprintWallBorderPaint {
  static void drawRoomBorder(
    Canvas canvas, {
    required Rect roomRect,
    required RoomDesign design,
    required double scale,
    required Paint paint,
  }) {
    if (!design.dimensions.useCustomWallLengths) {
      canvas.drawRect(roomRect, paint);
      return;
    }

    for (final wall in design.walls) {
      if (wall.isFullyHidden) continue;
      drawWallEdge(
        canvas,
        paint: paint,
        wall: wall,
        roomRect: roomRect,
        scale: scale,
        dimensions: design.dimensions,
      );
    }
  }

  static void drawWallEdge(
    Canvas canvas, {
    required Paint paint,
    required WallConfig wall,
    required Rect roomRect,
    required double scale,
    required RoomDimensions dimensions,
  }) {
    final fraction = wall.visibleFraction.clamp(0.0, 1.0);
    if (fraction <= 0) return;


    final wallLenFt = dimensions.lengthForWall(wall.id);
    final fullLen = wallLenFt * scale;
    final visLen = fullLen * fraction;

    double alignOffset = 0;
    if (wall.visibleAlign == WallVisibleAlign.center) {
      alignOffset = (fullLen - visLen) / 2;
    } else if (wall.visibleAlign == WallVisibleAlign.end) {
      alignOffset = fullLen - visLen;
    }

    final edgeOffset = _wallEdgeOffset(
      wall.id,
      roomRect: roomRect,
      wallLenPx: fullLen,
    );

    switch (wall.id) {
      case WallId.front:
        canvas.drawLine(
          Offset(roomRect.left + edgeOffset.dx + alignOffset, roomRect.top),
          Offset(roomRect.left + edgeOffset.dx + alignOffset + visLen, roomRect.top),
          paint,
        );
      case WallId.back:
        canvas.drawLine(
          Offset(roomRect.left + edgeOffset.dx + alignOffset, roomRect.bottom),
          Offset(roomRect.left + edgeOffset.dx + alignOffset + visLen, roomRect.bottom),
          paint,
        );
      case WallId.left:
        canvas.drawLine(
          Offset(roomRect.left, roomRect.top + edgeOffset.dy + alignOffset),
          Offset(roomRect.left, roomRect.top + edgeOffset.dy + alignOffset + visLen),
          paint,
        );
      case WallId.right:
        canvas.drawLine(
          Offset(roomRect.right, roomRect.top + edgeOffset.dy + alignOffset),
          Offset(roomRect.right, roomRect.top + edgeOffset.dy + alignOffset + visLen),
          paint,
        );
    }
  }

  /// Centers a shorter custom wall along its bounding-box edge.
  static Offset _wallEdgeOffset(
    WallId wall, {
    required Rect roomRect,
    required double wallLenPx,
  }) {
    return switch (wall) {
      WallId.front || WallId.back => Offset((roomRect.width - wallLenPx) / 2, 0),
      WallId.left || WallId.right => Offset(0, (roomRect.height - wallLenPx) / 2),
    };
  }
}
