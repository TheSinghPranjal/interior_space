import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/color_utils.dart';
import '../../models/cupboard_config.dart';
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
        final roomRect = Rect.fromLTWH(offsetX, offsetY, roomW, roomH);

        return GestureDetector(
          onPanUpdate: (details) => _handleDrag(
            details.localPosition,
            roomRect,
            scale,
            design,
          ),
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
              roomRect: roomRect,
              scale: scale,
              selectedId: _draggingId,
            ),
            child: Stack(
              children: [
                ...design.furniture.where((f) => !f.isWallMounted).map((item) {
                  return _buildFloorItem(
                    item: item,
                    roomRect: roomRect,
                    scale: scale,
                  );
                }),
                ...design.furniture.where((f) => f.isWallMounted).map((item) {
                  return _buildWallItem(
                    item: item,
                    roomRect: roomRect,
                    scale: scale,
                  );
                }),
                ...design.cupboards.map((cupboard) {
                  return _buildCupboardItem(
                    cupboard: cupboard,
                    roomRect: roomRect,
                    scale: scale,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleDrag(
    Offset localPos,
    Rect roomRect,
    double scale,
    dynamic design,
  ) {
    if (_draggingId == null) return;

    if (_draggingType == 'furniture_floor') {
      final item = design.furniture.firstWhere((f) => f.id == _draggingId) as FurnitureItem;
      final localX = localPos.dx - roomRect.left;
      final localY = localPos.dy - roomRect.top;
      final halfWNorm = (item.width / design.dimensions.width) / 2;
      final halfDNorm = (item.depth / design.dimensions.length) / 2;
      final bx = (localX / roomRect.width).clamp(halfWNorm, 1 - halfWNorm);
      final by = (localY / roomRect.height).clamp(halfDNorm, 1 - halfDNorm);
      ref.read(roomDesignProvider.notifier).updateFurniture(
            item.copyWith(blueprintX: bx, blueprintY: by),
          );
    } else if (_draggingType == 'furniture_wall') {
      final item = design.furniture.firstWhere((f) => f.id == _draggingId) as FurnitureItem;
      final wall = item.wall ?? WallId.left;
      final edge = switch (wall) {
        WallId.front || WallId.back =>
          (localPos.dx - roomRect.left) / scale - item.width / 2,
        WallId.left || WallId.right =>
          (localPos.dy - roomRect.top) / scale - item.width / 2,
      };
      final maxEdge = switch (wall) {
        WallId.front || WallId.back => roomRect.width / scale - item.width,
        WallId.left || WallId.right => roomRect.height / scale - item.width,
      };
      ref.read(roomDesignProvider.notifier).updateFurniture(
            item.copyWith(positionFromEdge: edge.clamp(0, maxEdge.clamp(0, double.infinity))),
          );
    } else if (_draggingType == 'cupboard_floor') {
      final cupboard = design.cupboards.firstWhere((c) => c.id == _draggingId) as CupboardConfig;
      final localX = localPos.dx - roomRect.left;
      final localY = localPos.dy - roomRect.top;
      final halfWNorm = (cupboard.width / design.dimensions.width) / 2;
      final halfDNorm = (cupboard.depth / design.dimensions.length) / 2;
      final bx = (localX / roomRect.width).clamp(halfWNorm, 1 - halfWNorm);
      final by = (localY / roomRect.height).clamp(halfDNorm, 1 - halfDNorm);
      ref.read(roomDesignProvider.notifier).updateCupboard(
            cupboard.copyWith(blueprintX: bx, blueprintY: by),
          );
    }
  }

  Widget _buildFloorItem({
    required FurnitureItem item,
    required Rect roomRect,
    required double scale,
  }) {
    final w = item.width * scale;
    final d = item.depth * scale;
    final left = roomRect.left + item.blueprintX * roomRect.width - w / 2;
    final top = roomRect.top + item.blueprintY * roomRect.height - d / 2;

    return _itemBox(
      id: item.id,
      dragType: 'furniture_floor',
      left: left,
      top: top,
      width: w,
      height: d,
      label: item.type.label,
      color: ColorUtils.fromHex(item.color),
    );
  }

  Widget _buildWallItem({
    required FurnitureItem item,
    required Rect roomRect,
    required double scale,
  }) {
    final rect = _wallItemRect(item, roomRect, scale);
    return _itemBox(
      id: item.id,
      dragType: 'furniture_wall',
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      label: item.type.label,
      color: ColorUtils.fromHex(item.color),
    );
  }

  Widget _buildCupboardItem({
    required CupboardConfig cupboard,
    required Rect roomRect,
    required double scale,
  }) {
    final w = cupboard.width * scale;
    final d = cupboard.depth * scale;
    final left = roomRect.left + cupboard.blueprintX * roomRect.width - w / 2;
    final top = roomRect.top + cupboard.blueprintY * roomRect.height - d / 2;

    return _itemBox(
      id: cupboard.id,
      dragType: 'cupboard_floor',
      left: left,
      top: top,
      width: w,
      height: d,
      label: 'Cupboard',
      color: ColorUtils.fromHex(cupboard.color),
    );
  }

  Rect _wallItemRect(FurnitureItem item, Rect roomRect, double scale) {
    final wall = item.wall ?? WallId.left;
    final along = item.positionFromEdge * scale;
    final into = item.depth * scale;
    final alongSize = item.width * scale;

    switch (wall) {
      case WallId.front:
        return Rect.fromLTWH(
          roomRect.left + along,
          roomRect.top,
          alongSize,
          into,
        );
      case WallId.back:
        return Rect.fromLTWH(
          roomRect.left + along,
          roomRect.bottom - into,
          alongSize,
          into,
        );
      case WallId.left:
        return Rect.fromLTWH(
          roomRect.left,
          roomRect.top + along,
          into,
          alongSize,
        );
      case WallId.right:
        return Rect.fromLTWH(
          roomRect.right - into,
          roomRect.top + along,
          into,
          alongSize,
        );
    }
  }

  Widget _itemBox({
    required String id,
    required String dragType,
    required double left,
    required double top,
    required double width,
    required double height,
    required String label,
    required Color color,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _draggingId = id;
            _draggingType = dragType;
          });
        },
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.75),
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
