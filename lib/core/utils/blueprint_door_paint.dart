import 'dart:math' as math;
import 'dart:ui';

import '../../models/door_config.dart';
import '../../models/enums.dart';

/// Architectural door symbol: colored wall opening, plus dotted swing arc.
class BlueprintDoorPaint {
  static const _stripDepth = 6.0;

  static void draw({
    required Canvas canvas,
    required Rect roomRect,
    required double scale,
    required DoorConfig door,
    Color? fillColor,
    Color? strokeColor,
    bool selected = false,
  }) {
    final r = door.width * scale;
    if (r <= 0) return;

    final fill = fillColor ?? strokeColor ?? const Color(0xFF8B5E3C);
    final arcStroke = strokeColor ?? fill;

    final stripRect = wallStripRect(
      roomRect: roomRect,
      scale: scale,
      door: door,
    );

    final fillPaint = Paint()
      ..color = fill.withValues(alpha: selected ? 1.0 : 0.92)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(stripRect, const Radius.circular(2)),
      fillPaint,
    );

    if (selected) {
      final outlinePaint = Paint()
        ..color = arcStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(stripRect, const Radius.circular(2)),
        outlinePaint,
      );
    }

    if (!door.showSwingArc) return;

    final geom = _geometry(
      roomRect: roomRect,
      scale: scale,
      door: door,
    );
    if (geom == null) return;

    final arcPaint = Paint()
      ..color = arcStroke.withValues(alpha: selected ? 0.95 : 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 1.4 : 1.1
      ..strokeCap = StrokeCap.round;

    _drawDottedArc(
      canvas: canvas,
      center: geom.hinge,
      radius: geom.radius,
      startAngle: geom.arcStart,
      sweepAngle: geom.arcSweep,
      paint: arcPaint,
    );
  }

  static Rect wallStripRect({
    required Rect roomRect,
    required double scale,
    required DoorConfig door,
  }) {
    final dw = door.width * scale;
    final offset = door.positionFromEdge * scale;
    const d = _stripDepth;

    return switch (door.wall) {
      WallId.front => Rect.fromLTWH(roomRect.left + offset, roomRect.top - d / 2, dw, d),
      WallId.back => Rect.fromLTWH(roomRect.left + offset, roomRect.bottom - d / 2, dw, d),
      WallId.left => Rect.fromLTWH(roomRect.left - d / 2, roomRect.top + offset, d, dw),
      WallId.right => Rect.fromLTWH(roomRect.right - d / 2, roomRect.top + offset, d, dw),
    };
  }

  static _DoorGeom? _geometry({
    required Rect roomRect,
    required double scale,
    required DoorConfig door,
  }) {
    final radius = door.width * scale;
    if (radius <= 0) return null;

    final offset = door.positionFromEdge * scale;
    final hingeAtStart = door.hingeSide == DoorHingeSide.start;
    final inward = door.swingDirection == DoorSwingDirection.inward;

    final opening = _openingJambs(
      roomRect: roomRect,
      offset: offset,
      span: radius,
      wall: door.wall,
    );
    final hinge = hingeAtStart ? opening.start : opening.end;
    final freeJamb = hingeAtStart ? opening.end : opening.start;

    final intoRoom = _intoRoomUnit(door.wall);
    final swingInto = inward ? intoRoom : -intoRoom;

    final closedAngle = math.atan2(
      freeJamb.dy - hinge.dy,
      freeJamb.dx - hinge.dx,
    );

    // Rotate the closed leaf direction 90° toward the swing side.
    final closedDx = math.cos(closedAngle);
    final closedDy = math.sin(closedAngle);
    final cross = closedDx * swingInto.dy - closedDy * swingInto.dx;
    final arcSweep = cross >= 0 ? math.pi / 2 : -math.pi / 2;

    return _DoorGeom(
      hinge: hinge,
      radius: radius,
      arcStart: closedAngle,
      arcSweep: arcSweep,
    );
  }

  static ({Offset start, Offset end}) _openingJambs({
    required Rect roomRect,
    required double offset,
    required double span,
    required WallId wall,
  }) {
    return switch (wall) {
      WallId.front => (
          start: Offset(roomRect.left + offset, roomRect.top),
          end: Offset(roomRect.left + offset + span, roomRect.top),
        ),
      WallId.back => (
          start: Offset(roomRect.left + offset, roomRect.bottom),
          end: Offset(roomRect.left + offset + span, roomRect.bottom),
        ),
      WallId.left => (
          start: Offset(roomRect.left, roomRect.top + offset),
          end: Offset(roomRect.left, roomRect.top + offset + span),
        ),
      WallId.right => (
          start: Offset(roomRect.right, roomRect.top + offset),
          end: Offset(roomRect.right, roomRect.top + offset + span),
        ),
    };
  }

  static Offset _intoRoomUnit(WallId wall) {
    return switch (wall) {
      WallId.front => const Offset(0, 1),
      WallId.back => const Offset(0, -1),
      WallId.left => const Offset(1, 0),
      WallId.right => const Offset(-1, 0),
    };
  }

  static void _drawDottedArc({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double startAngle,
    required double sweepAngle,
    required Paint paint,
  }) {
    if (radius <= 0 || sweepAngle.abs() < 0.01) return;

    const dashCount = 8;
    final dashSweep = sweepAngle / (dashCount * 2);
    for (var i = 0; i < dashCount; i++) {
      final a0 = startAngle + i * 2 * dashSweep;
      final a1 = a0 + dashSweep;
      final p0 = center + Offset(math.cos(a0) * radius, math.sin(a0) * radius);
      final p1 = center + Offset(math.cos(a1) * radius, math.sin(a1) * radius);
      canvas.drawLine(p0, p1, paint);
    }
  }
}

class _DoorGeom {
  const _DoorGeom({
    required this.hinge,
    required this.radius,
    required this.arcStart,
    required this.arcSweep,
  });

  final Offset hinge;
  final double radius;
  final double arcStart;
  final double arcSweep;
}
