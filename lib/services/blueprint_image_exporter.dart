import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/utils/color_utils.dart';
import '../models/enums.dart';
import '../models/furniture_item.dart';
import '../models/room_design.dart';

class BlueprintImageExporter {
  static Future<Uint8List> render(RoomDesign design, {Size size = const Size(820, 640)}) async {
    WidgetsFlutterBinding.ensureInitialized();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = _BlueprintExportPainter(design: design, canvasSize: size);
    painter.paint(canvas, size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}

class _BlueprintExportPainter {
  _BlueprintExportPainter({
    required this.design,
    required this.canvasSize,
  });

  final RoomDesign design;
  final Size canvasSize;

  late Rect _roomRect;
  late double _scale;

  void paint(Canvas canvas, Size size) {
    const padding = 48.0;
    final availW = size.width - padding * 2;
    final availH = size.height - padding * 2 - 40;
    _scale = math.min(
      availW / design.dimensions.width,
      availH / design.dimensions.length,
    );
    final roomW = design.dimensions.width * _scale;
    final roomH = design.dimensions.length * _scale;
    final offsetX = (size.width - roomW) / 2;
    final offsetY = (size.height - roomH) / 2 + 10;
    _roomRect = Rect.fromLTWH(offsetX, offsetY, roomW, roomH);

    final bgPaint = Paint()
      ..color = Colors.blue.shade50
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    _drawTitle(canvas);
    _drawRoom(canvas);
    _drawGrid(canvas);
    _drawDoors(canvas);
    _drawWindows(canvas);
    _drawAcUnits(canvas);
    _drawWallTvUnits(canvas);
    _drawFurniture(canvas);
    _drawCupboards(canvas);
    _drawFans(canvas);
    _drawDimensions(canvas);
    _drawWallLabels(canvas);
  }

  void _drawTitle(Canvas canvas) {
    final tp = TextPainter(
      text: TextSpan(
        text: '${design.name} — Floor Plan',
        style: TextStyle(
          color: Colors.blueGrey.shade900,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: canvasSize.width - 32);
    tp.paint(canvas, const Offset(16, 12));
  }

  void _drawRoom(Canvas canvas) {
    final roomPaint = Paint()
      ..color = ColorUtils.fromHex(design.floor.color).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawRect(_roomRect, roomPaint);

    final borderPaint = Paint()
      ..color = Colors.blueGrey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(_roomRect, borderPaint);
  }

  void _drawGrid(Canvas canvas) {
    final gridLinePaint = Paint()
      ..color = Colors.blueGrey.shade200
      ..strokeWidth = 0.5;
    for (var i = 1; i < design.dimensions.width; i++) {
      final x = _roomRect.left + i * _scale;
      canvas.drawLine(Offset(x, _roomRect.top), Offset(x, _roomRect.bottom), gridLinePaint);
    }
    for (var i = 1; i < design.dimensions.length; i++) {
      final y = _roomRect.top + i * _scale;
      canvas.drawLine(Offset(_roomRect.left, y), Offset(_roomRect.right, y), gridLinePaint);
    }
  }

  void _drawDoors(Canvas canvas) {
    for (final door in design.doors) {
      final paint = Paint()..color = ColorUtils.fromHex(door.color);
      final dw = door.width * _scale;
      final offset = door.positionFromEdge * _scale;
      final rect = switch (door.wall) {
        WallId.front => Rect.fromLTWH(_roomRect.left + offset, _roomRect.top - 4, dw, 8),
        WallId.back => Rect.fromLTWH(_roomRect.left + offset, _roomRect.bottom - 4, dw, 8),
        WallId.left => Rect.fromLTWH(_roomRect.left - 4, _roomRect.top + offset, 8, dw),
        WallId.right => Rect.fromLTWH(_roomRect.right - 4, _roomRect.top + offset, 8, dw),
      };
      canvas.drawRect(rect, paint);
    }
  }

  void _drawWindows(Canvas canvas) {
    for (final window in design.windows) {
      final paint = Paint()..color = ColorUtils.fromHex(window.glassColor);
      final ww = window.width * _scale;
      final offset = window.positionFromEdge * _scale;
      final rect = switch (window.wall) {
        WallId.front => Rect.fromLTWH(_roomRect.left + offset, _roomRect.top - 3, ww, 6),
        WallId.back => Rect.fromLTWH(_roomRect.left + offset, _roomRect.bottom - 3, ww, 6),
        WallId.left => Rect.fromLTWH(_roomRect.left - 3, _roomRect.top + offset, 6, ww),
        WallId.right => Rect.fromLTWH(_roomRect.right - 3, _roomRect.top + offset, 6, ww),
      };
      canvas.drawRect(rect, paint);
    }
  }

  void _drawAcUnits(Canvas canvas) {
    for (final unit in design.acUnits) {
      final paint = Paint()..color = ColorUtils.fromHex(unit.color);
      final aw = unit.width * _scale;
      final offset = unit.positionFromEdge * _scale;
      final rect = switch (unit.wall) {
        WallId.front => Rect.fromLTWH(_roomRect.left + offset, _roomRect.top - 4, aw, 8),
        WallId.back => Rect.fromLTWH(_roomRect.left + offset, _roomRect.bottom - 4, aw, 8),
        WallId.left => Rect.fromLTWH(_roomRect.left - 4, _roomRect.top + offset, 8, aw),
        WallId.right => Rect.fromLTWH(_roomRect.right - 4, _roomRect.top + offset, 8, aw),
      };
      canvas.drawRect(rect, paint);
    }
  }

  void _drawWallTvUnits(Canvas canvas) {
    for (final unit in design.wallTvUnits) {
      final paint = Paint()..color = ColorUtils.fromHex(unit.color);
      final uw = unit.width * _scale;
      final offset = unit.positionFromEdge * _scale;
      final rect = switch (unit.wall) {
        WallId.front => Rect.fromLTWH(_roomRect.left + offset, _roomRect.top - 4, uw, 8),
        WallId.back => Rect.fromLTWH(_roomRect.left + offset, _roomRect.bottom - 4, uw, 8),
        WallId.left => Rect.fromLTWH(_roomRect.left - 4, _roomRect.top + offset, 8, uw),
        WallId.right => Rect.fromLTWH(_roomRect.right - 4, _roomRect.top + offset, 8, uw),
      };
      canvas.drawRect(rect, paint);
    }
  }

  void _drawFurniture(Canvas canvas) {
    for (final item in design.furniture) {
      if (item.isWallMounted) {
        _drawItemBox(canvas, _wallItemRect(item), FurnitureItem.displayLabel(design.furniture, item), ColorUtils.fromHex(item.color));
      } else {
        final w = item.width * _scale;
        final d = item.depth * _scale;
        final left = _roomRect.left + item.blueprintX * _roomRect.width - w / 2;
        final top = _roomRect.top + item.blueprintY * _roomRect.height - d / 2;
        _drawItemBox(canvas, Rect.fromLTWH(left, top, w, d), FurnitureItem.displayLabel(design.furniture, item), ColorUtils.fromHex(item.color));
      }
    }
  }

  void _drawCupboards(Canvas canvas) {
    for (final cupboard in design.cupboards) {
      final w = cupboard.width * _scale;
      final d = cupboard.depth * _scale;
      final left = _roomRect.left + cupboard.blueprintX * _roomRect.width - w / 2;
      final top = _roomRect.top + cupboard.blueprintY * _roomRect.height - d / 2;
      _drawItemBox(canvas, Rect.fromLTWH(left, top, w, d), 'Cupboard', ColorUtils.fromHex(cupboard.color));
    }
  }

  void _drawFans(Canvas canvas) {
    for (final fan in design.fans) {
      final cx = _roomRect.left + fan.positionX * _roomRect.width;
      final cy = _roomRect.top + fan.positionY * _roomRect.height;
      const radius = 12.0;

      final fill = Paint()
        ..color = ColorUtils.fromHex(fan.color).withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), radius, fill);

      final border = Paint()
        ..color = Colors.blueGrey.shade800
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(cx, cy), radius, border);
    }
  }

  void _drawItemBox(Canvas canvas, Rect rect, String label, Color color) {
    final fill = Paint()
      ..color = color.withValues(alpha: 0.8)
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

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 2);
    tp.paint(
      canvas,
      Offset(
        rect.left + (rect.width - tp.width) / 2,
        rect.top + (rect.height - tp.height) / 2,
      ),
    );
  }

  Rect _wallItemRect(FurnitureItem item) {
    final wall = item.wall ?? WallId.left;
    final along = item.positionFromEdge * _scale;
    final into = item.depth * _scale;
    final alongSize = item.width * _scale;

    return switch (wall) {
      WallId.front => Rect.fromLTWH(_roomRect.left + along, _roomRect.top, alongSize, into),
      WallId.back => Rect.fromLTWH(_roomRect.left + along, _roomRect.bottom - into, alongSize, into),
      WallId.left => Rect.fromLTWH(_roomRect.left, _roomRect.top + along, into, alongSize),
      WallId.right => Rect.fromLTWH(_roomRect.right - into, _roomRect.top + along, into, alongSize),
    };
  }

  void _drawDimensions(Canvas canvas) {
    final style = TextStyle(
      color: Colors.blueGrey.shade800,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
    final tp = TextPainter(textDirection: TextDirection.ltr);

    tp.text = TextSpan(text: '${design.dimensions.width} ft', style: style);
    tp.layout();
    tp.paint(canvas, Offset(_roomRect.center.dx - tp.width / 2, _roomRect.top - 28));

    tp.text = TextSpan(text: '${design.dimensions.length} ft', style: style);
    tp.layout();
    tp.paint(canvas, Offset(_roomRect.right + 10, _roomRect.center.dy - tp.height / 2));

    tp.text = TextSpan(
      text: 'Height: ${design.dimensions.height} ft',
      style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 11),
    );
    tp.layout();
    tp.paint(canvas, Offset(16, canvasSize.height - 24));
  }

  void _drawWallLabels(Canvas canvas) {
    final style = TextStyle(color: Colors.grey.shade700, fontSize: 10, fontWeight: FontWeight.w500);
    final labels = {
      Offset(_roomRect.center.dx, _roomRect.top + 10): 'Front',
      Offset(_roomRect.center.dx, _roomRect.bottom - 18): 'Back',
      Offset(_roomRect.left + 12, _roomRect.center.dy): 'Left',
      Offset(_roomRect.right - 28, _roomRect.center.dy): 'Right',
    };

    for (final entry in labels.entries) {
      final tp = TextPainter(
        text: TextSpan(text: entry.value, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, entry.key);
    }
  }
}
