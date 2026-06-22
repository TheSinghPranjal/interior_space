import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/utils/color_utils.dart';
import '../../models/enums.dart';
import '../../models/furniture_item.dart';
import '../../models/room_design.dart';

/// Draws a complete room floor-plan layout (floor, grid, furniture, doors, etc.)
/// at the given [roomRect] using feet-to-pixel [scale].
class RoomBlueprintLayoutPainter extends CustomPainter {
  RoomBlueprintLayoutPainter({
    required this.design,
    required this.roomRect,
    required this.scale,
    this.isSelected = false,
    this.showWallLabels = true,
    this.showDimensions = false,
  });

  final RoomDesign design;
  final Rect roomRect;
  final double scale;
  final bool isSelected;
  final bool showWallLabels;
  final bool showDimensions;

  @override
  void paint(Canvas canvas, Size size) {
    if (roomRect.width <= 0 || roomRect.height <= 0) return;

    _drawFloor(canvas);
    _drawGrid(canvas);
    _drawDoors(canvas);
    _drawWindows(canvas);
    _drawCurtains(canvas);
    _drawAcUnits(canvas);
    _drawWallTvUnits(canvas);
    _drawCupboards(canvas);
    _drawFurniture(canvas);
    _drawFans(canvas);
    _drawRoomBorder(canvas);
    if (showWallLabels) _drawWallLabels(canvas);
    if (showDimensions) _drawDimensions(canvas);
    _drawRoomName(canvas);
    if (isSelected) _drawSelectionHighlight(canvas);
  }

  void _drawFloor(Canvas canvas) {
    final roomPaint = Paint()
      ..color = ColorUtils.fromHex(design.floor.color).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawRect(roomRect, roomPaint);
  }

  void _drawRoomBorder(Canvas canvas) {
    final borderPaint = Paint()
      ..color = Colors.blueGrey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(roomRect, borderPaint);
  }

  void _drawGrid(Canvas canvas) {
    final gridLinePaint = Paint()
      ..color = Colors.blueGrey.shade200
      ..strokeWidth = 0.5;
    for (var i = 1; i < design.dimensions.width; i++) {
      final x = roomRect.left + i * scale;
      canvas.drawLine(Offset(x, roomRect.top), Offset(x, roomRect.bottom), gridLinePaint);
    }
    for (var i = 1; i < design.dimensions.length; i++) {
      final y = roomRect.top + i * scale;
      canvas.drawLine(Offset(roomRect.left, y), Offset(roomRect.right, y), gridLinePaint);
    }
  }

  void _drawDoors(Canvas canvas) {
    for (final door in design.doors) {
      final paint = Paint()..color = ColorUtils.fromHex(door.color);
      final dw = door.width * scale;
      final offset = door.positionFromEdge * scale;
      final rect = switch (door.wall) {
        WallId.front => Rect.fromLTWH(roomRect.left + offset, roomRect.top - 3, dw, 6),
        WallId.back => Rect.fromLTWH(roomRect.left + offset, roomRect.bottom - 3, dw, 6),
        WallId.left => Rect.fromLTWH(roomRect.left - 3, roomRect.top + offset, 6, dw),
        WallId.right => Rect.fromLTWH(roomRect.right - 3, roomRect.top + offset, 6, dw),
      };
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
    }
  }

  void _drawWindows(Canvas canvas) {
    for (final window in design.windows) {
      final paint = Paint()..color = ColorUtils.fromHex(window.glassColor);
      final ww = window.width * scale;
      final offset = window.positionFromEdge * scale;
      final rect = switch (window.wall) {
        WallId.front => Rect.fromLTWH(roomRect.left + offset, roomRect.top - 3, ww, 6),
        WallId.back => Rect.fromLTWH(roomRect.left + offset, roomRect.bottom - 3, ww, 6),
        WallId.left => Rect.fromLTWH(roomRect.left - 3, roomRect.top + offset, 6, ww),
        WallId.right => Rect.fromLTWH(roomRect.right - 3, roomRect.top + offset, 6, ww),
      };
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
    }
  }

  void _drawCurtains(Canvas canvas) {
    for (final curtain in design.curtains) {
      final paint = Paint()..color = ColorUtils.fromHex(curtain.color);
      final cw = curtain.width * scale;
      final offset = curtain.positionFromEdge * scale;
      final rect = switch (curtain.wall) {
        WallId.front => Rect.fromLTWH(roomRect.left + offset, roomRect.top - 4, cw, 8),
        WallId.back => Rect.fromLTWH(roomRect.left + offset, roomRect.bottom - 4, cw, 8),
        WallId.left => Rect.fromLTWH(roomRect.left - 4, roomRect.top + offset, 8, cw),
        WallId.right => Rect.fromLTWH(roomRect.right - 4, roomRect.top + offset, 8, cw),
      };
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
    }
  }

  void _drawAcUnits(Canvas canvas) {
    for (final unit in design.acUnits) {
      final paint = Paint()..color = ColorUtils.fromHex(unit.color);
      final aw = unit.width * scale;
      final offset = unit.positionFromEdge * scale;
      final rect = switch (unit.wall) {
        WallId.front => Rect.fromLTWH(roomRect.left + offset, roomRect.top - 4, aw, 8),
        WallId.back => Rect.fromLTWH(roomRect.left + offset, roomRect.bottom - 4, aw, 8),
        WallId.left => Rect.fromLTWH(roomRect.left - 4, roomRect.top + offset, 8, aw),
        WallId.right => Rect.fromLTWH(roomRect.right - 4, roomRect.top + offset, 8, aw),
      };
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);

      final fontSize = math.max(5.0, math.min(8.0, aw * 0.18));
      final tp = TextPainter(
        text: TextSpan(
          text: 'AC',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: aw);
      tp.paint(
        canvas,
        Offset(
          rect.left + (rect.width - tp.width) / 2,
          rect.top + (rect.height - tp.height) / 2,
        ),
      );
    }
  }

  void _drawWallTvUnits(Canvas canvas) {
    for (final unit in design.wallTvUnits) {
      final paint = Paint()..color = ColorUtils.fromHex(unit.color);
      final uw = unit.width * scale;
      final offset = unit.positionFromEdge * scale;
      final rect = switch (unit.wall) {
        WallId.front => Rect.fromLTWH(roomRect.left + offset, roomRect.top - 3, uw, 6),
        WallId.back => Rect.fromLTWH(roomRect.left + offset, roomRect.bottom - 3, uw, 6),
        WallId.left => Rect.fromLTWH(roomRect.left - 3, roomRect.top + offset, 6, uw),
        WallId.right => Rect.fromLTWH(roomRect.right - 3, roomRect.top + offset, 6, uw),
      };
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
    }
  }

  void _drawFurniture(Canvas canvas) {
    for (final item in design.furniture) {
      if (item.isWallMounted) {
        _drawItemBox(canvas, _wallItemRect(item), FurnitureItem.displayLabel(design.furniture, item), ColorUtils.fromHex(item.color));
      } else {
        final w = item.width * scale;
        final d = item.depth * scale;
        final left = roomRect.left + item.blueprintX * roomRect.width - w / 2;
        final top = roomRect.top + item.blueprintY * roomRect.height - d / 2;
        _drawItemBox(
          canvas,
          Rect.fromLTWH(left, top, w, d),
          FurnitureItem.displayLabel(design.furniture, item),
          ColorUtils.fromHex(item.color),
        );
      }
    }
  }

  void _drawCupboards(Canvas canvas) {
    for (final cupboard in design.cupboards) {
      final w = cupboard.width * scale;
      final d = cupboard.depth * scale;
      final left = roomRect.left + cupboard.blueprintX * roomRect.width - w / 2;
      final top = roomRect.top + cupboard.blueprintY * roomRect.height - d / 2;
      _drawItemBox(
        canvas,
        Rect.fromLTWH(left, top, w, d),
        'Cupboard',
        ColorUtils.fromHex(cupboard.color),
      );
    }
  }

  void _drawFans(Canvas canvas) {
    for (final fan in design.fans) {
      final cx = roomRect.left + fan.positionX * roomRect.width;
      final cy = roomRect.top + fan.positionY * roomRect.height;
      const radius = 10.0;

      final fill = Paint()
        ..color = ColorUtils.fromHex(fan.color).withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), radius, fill);

      final border = Paint()
        ..color = Colors.blueGrey.shade800
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(Offset(cx, cy), radius, border);

      final bladePaint = Paint()
        ..color = ColorUtils.fromHex(fan.color).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (var i = 0; i < 4; i++) {
        final angle = i * math.pi / 2;
        canvas.drawLine(
          Offset(cx, cy),
          Offset(cx + math.cos(angle) * (radius - 2), cy + math.sin(angle) * (radius - 2)),
          bladePaint,
        );
      }
    }
  }

  Rect _wallItemRect(FurnitureItem item) {
    final wall = item.wall ?? WallId.left;
    final along = item.positionFromEdge * scale;
    final into = item.depth * scale;
    final alongSize = item.width * scale;

    return switch (wall) {
      WallId.front => Rect.fromLTWH(roomRect.left + along, roomRect.top, alongSize, into),
      WallId.back => Rect.fromLTWH(roomRect.left + along, roomRect.bottom - into, alongSize, into),
      WallId.left => Rect.fromLTWH(roomRect.left, roomRect.top + along, into, alongSize),
      WallId.right => Rect.fromLTWH(roomRect.right - into, roomRect.top + along, into, alongSize),
    };
  }

  void _drawItemBox(Canvas canvas, Rect rect, String label, Color color) {
    if (rect.width < 2 || rect.height < 2) return;

    final fill = Paint()
      ..color = color.withValues(alpha: 0.82)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      fill,
    );

    final border = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      border,
    );

    final fontSize = math.max(6.0, math.min(10.0, rect.shortestSide * 0.22));
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: rect.width - 4);
    tp.paint(
      canvas,
      Offset(
        rect.left + (rect.width - tp.width) / 2,
        rect.top + (rect.height - tp.height) / 2,
      ),
    );
  }

  void _drawWallLabels(Canvas canvas) {
    if (roomRect.width < 80) return;
    final style = TextStyle(color: Colors.grey.shade600, fontSize: 8);
    final labels = {
      Offset(roomRect.center.dx, roomRect.top + 8): 'Front',
      Offset(roomRect.center.dx, roomRect.bottom - 14): 'Back',
      Offset(roomRect.left + 10, roomRect.center.dy): 'Left',
      Offset(roomRect.right - 24, roomRect.center.dy): 'Right',
    };

    for (final entry in labels.entries) {
      final tp = TextPainter(
        text: TextSpan(text: entry.value, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, entry.key);
    }
  }

  void _drawDimensions(Canvas canvas) {
    final style = TextStyle(
      color: Colors.blueGrey.shade700,
      fontSize: 9,
      fontWeight: FontWeight.w500,
    );
    final tp = TextPainter(textDirection: TextDirection.ltr);

    tp.text = TextSpan(text: '${design.dimensions.width.toStringAsFixed(0)} ft', style: style);
    tp.layout();
    tp.paint(canvas, Offset(roomRect.center.dx - tp.width / 2, roomRect.top - 14));

    tp.text = TextSpan(text: '${design.dimensions.length.toStringAsFixed(0)} ft', style: style);
    tp.layout();
    tp.paint(canvas, Offset(roomRect.right + 4, roomRect.center.dy - tp.height / 2));
  }

  void _drawRoomName(Canvas canvas) {
    final fontSize = math.max(7.0, math.min(11.0, roomRect.width * 0.07));
    final tp = TextPainter(
      text: TextSpan(
        text: design.name,
        style: TextStyle(
          color: Colors.blueGrey.shade900,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          backgroundColor: Colors.white.withValues(alpha: 0.75),
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: roomRect.width - 8);

    tp.paint(
      canvas,
      Offset(
        roomRect.left + (roomRect.width - tp.width) / 2,
        roomRect.top + 2,
      ),
    );
  }

  void _drawSelectionHighlight(Canvas canvas) {
    final highlight = Paint()
      ..color = Colors.orange.shade400.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRect(roomRect, highlight);

    final border = Paint()
      ..color = Colors.orange.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRect(roomRect, border);
  }

  @override
  bool shouldRepaint(covariant RoomBlueprintLayoutPainter oldDelegate) =>
      oldDelegate.design != design ||
      oldDelegate.roomRect != roomRect ||
      oldDelegate.scale != scale ||
      oldDelegate.isSelected != isSelected;
}
