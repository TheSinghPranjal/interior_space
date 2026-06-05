import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/color_utils.dart';
import '../../models/enums.dart';
import '../../models/furniture_item.dart';
import '../../providers/room_design_provider.dart';

class BlueprintCanvas extends ConsumerStatefulWidget {
  const BlueprintCanvas({super.key});

  @override
  ConsumerState<BlueprintCanvas> createState() => _BlueprintCanvasState();
}

class _BlueprintCanvasState extends ConsumerState<BlueprintCanvas> {
  String? _draggingId;
  String? _draggingType;

  @override
  Widget build(BuildContext context) {
    final design = ref.watch(roomDesignProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = 32.0;
        final availW = constraints.maxWidth - padding * 2;
        final availH = constraints.maxHeight - padding * 2;
        final scale = math.min(
          availW / design.dimensions.width,
          availH / design.dimensions.length,
        );
        final roomW = design.dimensions.width * scale;
        final roomH = design.dimensions.length * scale;
        final offsetX = (constraints.maxWidth - roomW) / 2;
        final offsetY = (constraints.maxHeight - roomH) / 2;

        return GestureDetector(
          onPanUpdate: (details) {
            if (_draggingId == null) return;
            final localX = details.localPosition.dx - offsetX;
            final localY = details.localPosition.dy - offsetY;
            final bx = (localX / roomW).clamp(0.05, 0.95);
            final by = (localY / roomH).clamp(0.05, 0.95);

            if (_draggingType == 'furniture') {
              final item = design.furniture.firstWhere((f) => f.id == _draggingId);
              ref.read(roomDesignProvider.notifier).updateFurniture(
                    item.copyWith(blueprintX: bx, blueprintY: by),
                  );
            } else if (_draggingType == 'cupboard') {
              final cupboard = design.cupboards.firstWhere((c) => c.id == _draggingId);
              ref.read(roomDesignProvider.notifier).updateCupboard(
                    cupboard.copyWith(blueprintX: bx, blueprintY: by),
                  );
            }
          },
          onPanEnd: (_) {
            setState(() {
              _draggingId = null;
              _draggingType = null;
            });
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _BlueprintPainter(
              design: design,
              roomRect: Rect.fromLTWH(offsetX, offsetY, roomW, roomH),
              scale: scale,
              selectedId: _draggingId,
            ),
            child: Stack(
              children: [
                ...design.furniture.map((item) {
                  return _buildDraggableItem(
                    item: item,
                    offsetX: offsetX,
                    offsetY: offsetY,
                    roomW: roomW,
                    roomH: roomH,
                    scale: scale,
                    type: 'furniture',
                    label: item.type.label,
                    color: ColorUtils.fromHex(item.color),
                  );
                }),
                ...design.cupboards.map((cupboard) {
                  return _buildDraggableItem(
                    item: cupboard,
                    offsetX: offsetX,
                    offsetY: offsetY,
                    roomW: roomW,
                    roomH: roomH,
                    scale: scale,
                    type: 'cupboard',
                    label: 'Cupboard',
                    color: ColorUtils.fromHex(cupboard.color),
                    width: cupboard.width,
                    depth: cupboard.depth,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableItem({
    required dynamic item,
    required double offsetX,
    required double offsetY,
    required double roomW,
    required double roomH,
    required double scale,
    required String type,
    required String label,
    required Color color,
    double? width,
    double? depth,
  }) {
    final w = (width ?? (item as FurnitureItem).width) * scale;
    final d = (depth ?? (item as FurnitureItem).depth) * scale;
    final bx = item.blueprintX as double;
    final by = item.blueprintY as double;
    final id = item.id as String;

    return Positioned(
      left: offsetX + bx * roomW - w / 2,
      top: offsetY + by * roomH - d / 2,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _draggingId = id;
            _draggingType = type;
          });
        },
        child: Container(
          width: w,
          height: d,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.7),
            border: Border.all(
              color: _draggingId == id ? Colors.orange : Colors.black54,
              width: _draggingId == id ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _BlueprintPainter extends CustomPainter {
  _BlueprintPainter({
    required this.design,
    required this.roomRect,
    required this.scale,
    this.selectedId,
  });

  final dynamic design;
  final Rect roomRect;
  final double scale;
  final String? selectedId;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.blue.shade50
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, gridPaint);

    final roomPaint = Paint()
      ..color = ColorUtils.fromHex(design.floor.color).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRect(roomRect, roomPaint);

    final borderPaint = Paint()
      ..color = Colors.blueGrey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(roomRect, borderPaint);

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

    _drawDoors(canvas);
    _drawWindows(canvas);
    _drawDimensions(canvas);
    _drawWallLabels(canvas);
  }

  void _drawDoors(Canvas canvas) {
    for (final door in design.doors) {
      final paint = Paint()..color = ColorUtils.fromHex(door.color);
      final dw = door.width * scale;
      final offset = door.positionFromEdge * scale;

      Rect rect;
      switch (door.wall as WallId) {
        case WallId.front:
          rect = Rect.fromLTWH(roomRect.left + offset, roomRect.top - 4, dw, 8);
        case WallId.back:
          rect = Rect.fromLTWH(roomRect.left + offset, roomRect.bottom - 4, dw, 8);
        case WallId.left:
          rect = Rect.fromLTWH(roomRect.left - 4, roomRect.top + offset, 8, dw);
        case WallId.right:
          rect = Rect.fromLTWH(roomRect.right - 4, roomRect.top + offset, 8, dw);
      }
      canvas.drawRect(rect, paint);
    }
  }

  void _drawWindows(Canvas canvas) {
    for (final window in design.windows) {
      final paint = Paint()..color = ColorUtils.fromHex(window.glassColor);
      final ww = window.width * scale;
      final offset = window.positionFromEdge * scale;

      Rect rect;
      switch (window.wall as WallId) {
        case WallId.front:
          rect = Rect.fromLTWH(roomRect.left + offset, roomRect.top - 3, ww, 6);
        case WallId.back:
          rect = Rect.fromLTWH(roomRect.left + offset, roomRect.bottom - 3, ww, 6);
        case WallId.left:
          rect = Rect.fromLTWH(roomRect.left - 3, roomRect.top + offset, 6, ww);
        case WallId.right:
          rect = Rect.fromLTWH(roomRect.right - 3, roomRect.top + offset, 6, ww);
      }
      canvas.drawRect(rect, paint);
    }
  }

  void _drawDimensions(Canvas canvas) {
    final style = TextStyle(
      color: Colors.blueGrey.shade700,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );
    final tp = TextPainter(textDirection: TextDirection.ltr);

    tp.text = TextSpan(
      text: '${design.dimensions.width} ft',
      style: style,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(roomRect.center.dx - tp.width / 2, roomRect.top - 24),
    );

    tp.text = TextSpan(
      text: '${design.dimensions.length} ft',
      style: style,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(roomRect.right + 8, roomRect.center.dy - tp.height / 2),
    );
  }

  void _drawWallLabels(Canvas canvas) {
    final style = TextStyle(color: Colors.grey.shade600, fontSize: 10);
    final labels = {
      Offset(roomRect.center.dx, roomRect.top + 12): 'Front',
      Offset(roomRect.center.dx, roomRect.bottom - 20): 'Back',
      Offset(roomRect.left + 16, roomRect.center.dy): 'Left',
      Offset(roomRect.right - 32, roomRect.center.dy): 'Right',
    };

    for (final entry in labels.entries) {
      final tp = TextPainter(
        text: TextSpan(text: entry.value, style: style),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, entry.key);
    }
  }

  @override
  bool shouldRepaint(covariant _BlueprintPainter oldDelegate) => true;
}
