import 'dart:math' as math;
import 'dart:ui';

import '../../models/door_config.dart';
import '../../models/enums.dart';

/// Architectural door symbol: colored wall opening, plus dotted swing arc.
class BlueprintDoorPaint {
  static const _stripDepth = 6.0;

  /// One third of a quarter circle (30°).
  static const _arcSweep = math.pi / 6;

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
      radius: r,
      startAngle: geom.arcStart,
      sweepAngle: _arcSweep,
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
    final r = door.width * scale;
    final offset = door.positionFromEdge * scale;
    final hingeAtStart = door.hingeSide == DoorHingeSide.start;
    final inward = door.swingDirection == DoorSwingDirection.inward;

    switch (door.wall) {
      case WallId.front:
        final y = roomRect.top;
        final x0 = roomRect.left + offset;
        final x1 = x0 + r;
        final hinge = hingeAtStart ? Offset(x0, y) : Offset(x1, y);
        return _DoorGeom(
          hinge: hinge,
          arcStart: hingeAtStart
              ? (inward ? 0.0 : -math.pi / 2)
              : (inward ? math.pi : math.pi / 2),
        );
      case WallId.back:
        final y = roomRect.bottom;
        final x0 = roomRect.left + offset;
        final x1 = x0 + r;
        final hinge = hingeAtStart ? Offset(x0, y) : Offset(x1, y);
        return _DoorGeom(
          hinge: hinge,
          arcStart: hingeAtStart
              ? (inward ? math.pi : math.pi / 2)
              : (inward ? 0.0 : -math.pi / 2),
        );
      case WallId.left:
        final x = roomRect.left;
        final y0 = roomRect.top + offset;
        final y1 = y0 + r;
        final hinge = hingeAtStart ? Offset(x, y0) : Offset(x, y1);
        return _DoorGeom(
          hinge: hinge,
          arcStart: hingeAtStart
              ? (inward ? -math.pi / 2 : math.pi)
              : (inward ? math.pi / 2 : 0.0),
        );
      case WallId.right:
        final x = roomRect.right;
        final y0 = roomRect.top + offset;
        final y1 = y0 + r;
        final hinge = hingeAtStart ? Offset(x, y0) : Offset(x, y1);
        return _DoorGeom(
          hinge: hinge,
          arcStart: hingeAtStart
              ? (inward ? math.pi / 2 : 0.0)
              : (inward ? -math.pi / 2 : math.pi),
        );
    }
  }

  static void _drawDottedArc({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double startAngle,
    required double sweepAngle,
    required Paint paint,
  }) {
    const dashCount = 5;
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
    required this.arcStart,
  });

  final Offset hinge;
  final double arcStart;
}
