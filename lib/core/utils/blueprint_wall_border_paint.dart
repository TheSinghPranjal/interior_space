import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../models/room_design.dart';
import '../../models/room_dimensions.dart';
import '../../models/wall_config.dart';
import 'polygon_room_geometry.dart';

/// Shared blueprint wall-outline drawing (rectangular + polygon custom rooms).
abstract final class BlueprintWallBorderPaint {
  static void drawRoomBorder(
    Canvas canvas, {
    required Rect roomRect,
    required RoomDesign design,
    required double scale,
    required Paint paint,
  }) {
    if (design.dimensions.isPolygon) {
      _drawPolygonBorder(canvas, design: design, roomRect: roomRect, scale: scale, paint: paint);
      return;
    }

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

  static void _drawPolygonBorder(
    Canvas canvas, {
    required RoomDesign design,
    required Rect roomRect,
    required double scale,
    required Paint paint,
  }) {
    final vertices = design.dimensions.normalizedPolygonVertices;
    if (vertices.length < 3) return;

    for (var i = 0; i < vertices.length; i++) {
      final wall = design.walls.cast<WallConfig?>().elementAtOrNull(i);
      if (wall != null && wall.isFullyHidden) continue;

      final a = vertices[i];
      final b = vertices[(i + 1) % vertices.length];
      final start = PolygonRoomGeometry.cornerToCanvas(
        corner: a,
        roomRect: roomRect,
        scale: scale,
      );
      final end = PolygonRoomGeometry.cornerToCanvas(
        corner: b,
        roomRect: roomRect,
        scale: scale,
      );

      final fraction = (wall?.visibleFraction ?? 1.0).clamp(0.0, 1.0);
      if (fraction <= 0) continue;

      final align = wall?.visibleAlign ?? WallVisibleAlign.start;
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final visDx = dx * fraction;
      final visDy = dy * fraction;

      double offsetDx = 0;
      double offsetDy = 0;
      if (align == WallVisibleAlign.center) {
        offsetDx = (dx - visDx) / 2;
        offsetDy = (dy - visDy) / 2;
      } else if (align == WallVisibleAlign.end) {
        offsetDx = dx - visDx;
        offsetDy = dy - visDy;
      }

      canvas.drawLine(
        Offset(start.dx + offsetDx, start.dy + offsetDy),
        Offset(start.dx + offsetDx + visDx, start.dy + offsetDy + visDy),
        paint,
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

extension _ListElementAtOrNull<E> on List<E> {
  E? elementAtOrNull(int index) =>
      index >= 0 && index < length ? this[index] : null;
}
