import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/color_utils.dart';
import '../../models/cupboard_config.dart';
import '../../models/enums.dart';
import '../../models/furniture_item.dart';
import '../../models/room_design.dart';
import '../../providers/room_design_provider.dart';

class BlueprintCanvas extends ConsumerStatefulWidget {
  const BlueprintCanvas({super.key});

  @override
  ConsumerState<BlueprintCanvas> createState() => _BlueprintCanvasState();
}

class _BlueprintCanvasState extends ConsumerState<BlueprintCanvas> {
  static const _holdDuration = Duration(milliseconds: 420);

  String? _selectedId;
  String? _selectedType;
  bool _isDragging = false;
  Offset _dragDelta = Offset.zero;
  Offset? _dragStartCenter;
  Timer? _holdTimer;
  String? _holdItemId;

  double? _tempBlueprintX;
  double? _tempBlueprintY;
  double? _tempPositionFromEdge;

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

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

        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _deselect,
              child: CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _BlueprintPainter(
                  design: design,
                  roomRect: roomRect,
                  scale: scale,
                  selectedId: _selectedId,
                ),
              ),
            ),
            ...design.furniture.where((f) => !f.isWallMounted).map((item) {
              return _buildFloorItem(
                item: item,
                design: design,
                roomRect: roomRect,
                scale: scale,
              );
            }),
            ...design.furniture.where((f) => f.isWallMounted).map((item) {
              return _buildWallItem(
                item: item,
                design: design,
                roomRect: roomRect,
                scale: scale,
              );
            }),
            ...design.cupboards.map((cupboard) {
              return _buildCupboardItem(
                cupboard: cupboard,
                design: design,
                roomRect: roomRect,
                scale: scale,
              );
            }),
            if (_selectedId != null)
              _buildSelectionToolbar(design: design, roomRect: roomRect, scale: scale),
          ],
        );
      },
    );
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdItemId = null;
  }

  void _deselect() {
    _cancelHold();
    if (_selectedId == null) return;
    setState(() {
      _selectedId = null;
      _selectedType = null;
      _isDragging = false;
      _dragDelta = Offset.zero;
      _dragStartCenter = null;
      _tempBlueprintX = null;
      _tempBlueprintY = null;
      _tempPositionFromEdge = null;
    });
  }

  void _selectItem(String id, String type) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedId = id;
      _selectedType = type;
      _isDragging = false;
      _dragDelta = Offset.zero;
      _dragStartCenter = null;
      _tempBlueprintX = null;
      _tempBlueprintY = null;
      _tempPositionFromEdge = null;
    });
  }

  void _beginDrag(Offset itemCenter) {
    setState(() {
      _isDragging = true;
      _dragDelta = Offset.zero;
      _dragStartCenter = itemCenter;
    });
  }

  void _commitDrag(RoomDesign design, Rect roomRect, double scale) {
    if (_selectedId == null || _selectedType == null) return;

    final notifier = ref.read(roomDesignProvider.notifier);

    if (_selectedType == 'furniture_floor' && _tempBlueprintX != null && _tempBlueprintY != null) {
      final item = design.furniture.firstWhere((f) => f.id == _selectedId);
      notifier.updateFurniture(
        item.copyWith(blueprintX: _tempBlueprintX!, blueprintY: _tempBlueprintY!),
      );
    } else if (_selectedType == 'furniture_wall' && _tempPositionFromEdge != null) {
      final item = design.furniture.firstWhere((f) => f.id == _selectedId);
      notifier.updateFurniture(item.copyWith(positionFromEdge: _tempPositionFromEdge!));
    } else if (_selectedType == 'cupboard_floor' && _tempBlueprintX != null && _tempBlueprintY != null) {
      final cupboard = design.cupboards.firstWhere((c) => c.id == _selectedId);
      notifier.updateCupboard(
        cupboard.copyWith(blueprintX: _tempBlueprintX!, blueprintY: _tempBlueprintY!),
      );
    }

    setState(() {
      _isDragging = false;
      _dragDelta = Offset.zero;
      _dragStartCenter = null;
      _tempBlueprintX = null;
      _tempBlueprintY = null;
      _tempPositionFromEdge = null;
    });
  }

  void _rotateSelected(RoomDesign design, double degrees) {
    if (_selectedId == null || _selectedType == null) return;
    HapticFeedback.selectionClick();
    final notifier = ref.read(roomDesignProvider.notifier);

    if (_selectedType == 'furniture_floor') {
      final item = design.furniture.firstWhere((f) => f.id == _selectedId);
      final next = (item.rotation + degrees) % 360;
      notifier.updateFurniture(item.copyWith(rotation: next < 0 ? next + 360 : next));
    } else if (_selectedType == 'cupboard_floor') {
      final cupboard = design.cupboards.firstWhere((c) => c.id == _selectedId);
      final next = (cupboard.rotation + degrees) % 360;
      notifier.updateCupboard(cupboard.copyWith(rotation: next < 0 ? next + 360 : next));
    }
  }

  void _computeFloorPosition({
    required FurnitureItem? item,
    required CupboardConfig? cupboard,
    required RoomDesign design,
    required Rect roomRect,
    required double defaultBx,
    required double defaultBy,
  }) {
    final width = item?.width ?? cupboard!.width;
    final depth = item?.depth ?? cupboard!.depth;
    final center = (_dragStartCenter ?? Offset.zero) + _dragDelta;
    final halfWNorm = (width / design.dimensions.width) / 2;
    final halfDNorm = (depth / design.dimensions.length) / 2;
    final bx = ((center.dx - roomRect.left) / roomRect.width).clamp(halfWNorm, 1 - halfWNorm);
    final by = ((center.dy - roomRect.top) / roomRect.height).clamp(halfDNorm, 1 - halfDNorm);
    _tempBlueprintX = _isDragging ? bx : defaultBx;
    _tempBlueprintY = _isDragging ? by : defaultBy;
  }

  Widget _buildFloorItem({
    required FurnitureItem item,
    required RoomDesign design,
    required Rect roomRect,
    required double scale,
  }) {
    final w = item.width * scale;
    final d = item.depth * scale;
    final bx = (_isDragging && _selectedId == item.id && _tempBlueprintX != null)
        ? _tempBlueprintX!
        : item.blueprintX;
    final by = (_isDragging && _selectedId == item.id && _tempBlueprintY != null)
        ? _tempBlueprintY!
        : item.blueprintY;
    final left = roomRect.left + bx * roomRect.width - w / 2;
    final top = roomRect.top + by * roomRect.height - d / 2;

    return _itemBox(
      id: item.id,
      dragType: 'furniture_floor',
      left: left,
      top: top,
      width: w,
      height: d,
      label: item.type.label,
      color: ColorUtils.fromHex(item.color),
      rotation: item.rotation,
      design: design,
      roomRect: roomRect,
      scale: scale,
      onFloorDrag: () {
        _computeFloorPosition(
          item: item,
          cupboard: null,
          design: design,
          roomRect: roomRect,
          defaultBx: item.blueprintX,
          defaultBy: item.blueprintY,
        );
      },
    );
  }

  Widget _buildWallItem({
    required FurnitureItem item,
    required RoomDesign design,
    required Rect roomRect,
    required double scale,
  }) {
    final edge = (_isDragging && _selectedId == item.id && _tempPositionFromEdge != null)
        ? _tempPositionFromEdge!
        : item.positionFromEdge;
    final tempItem = item.copyWith(positionFromEdge: edge);
    final rect = _wallItemRect(tempItem, roomRect, scale);

    return _itemBox(
      id: item.id,
      dragType: 'furniture_wall',
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      label: item.type.label,
      color: ColorUtils.fromHex(item.color),
      rotation: 0,
      design: design,
      roomRect: roomRect,
      scale: scale,
      onWallDrag: (Offset center) {
        final wall = item.wall ?? WallId.left;
        double edgePos;
        switch (wall) {
          case WallId.front:
          case WallId.back:
            edgePos = (center.dx - roomRect.left) / scale - item.width / 2;
          case WallId.left:
          case WallId.right:
            edgePos = (center.dy - roomRect.top) / scale - item.width / 2;
        }
        final maxEdge = switch (wall) {
          WallId.front || WallId.back => roomRect.width / scale - item.width,
          WallId.left || WallId.right => roomRect.height / scale - item.width,
        };
        _tempPositionFromEdge = edgePos.clamp(0, maxEdge.clamp(0, double.infinity));
      },
    );
  }

  Widget _buildCupboardItem({
    required CupboardConfig cupboard,
    required RoomDesign design,
    required Rect roomRect,
    required double scale,
  }) {
    final w = cupboard.width * scale;
    final d = cupboard.depth * scale;
    final bx = (_isDragging && _selectedId == cupboard.id && _tempBlueprintX != null)
        ? _tempBlueprintX!
        : cupboard.blueprintX;
    final by = (_isDragging && _selectedId == cupboard.id && _tempBlueprintY != null)
        ? _tempBlueprintY!
        : cupboard.blueprintY;
    final left = roomRect.left + bx * roomRect.width - w / 2;
    final top = roomRect.top + by * roomRect.height - d / 2;

    return _itemBox(
      id: cupboard.id,
      dragType: 'cupboard_floor',
      left: left,
      top: top,
      width: w,
      height: d,
      label: 'Cupboard',
      color: ColorUtils.fromHex(cupboard.color),
      rotation: cupboard.rotation,
      design: design,
      roomRect: roomRect,
      scale: scale,
      onFloorDrag: () {
        _computeFloorPosition(
          item: null,
          cupboard: cupboard,
          design: design,
          roomRect: roomRect,
          defaultBx: cupboard.blueprintX,
          defaultBy: cupboard.blueprintY,
        );
      },
    );
  }

  Widget _buildSelectionToolbar({
    required RoomDesign design,
    required Rect roomRect,
    required double scale,
  }) {
    final canRotate = _selectedType == 'furniture_floor' || _selectedType == 'cupboard_floor';

    Rect? itemRect;
    if (_selectedType == 'furniture_floor') {
      final item = design.furniture.firstWhere((f) => f.id == _selectedId);
      final w = item.width * scale;
      final d = item.depth * scale;
      final bx = _tempBlueprintX ?? item.blueprintX;
      final by = _tempBlueprintY ?? item.blueprintY;
      itemRect = Rect.fromLTWH(
        roomRect.left + bx * roomRect.width - w / 2,
        roomRect.top + by * roomRect.height - d / 2,
        w,
        d,
      );
    } else if (_selectedType == 'cupboard_floor') {
      final cupboard = design.cupboards.firstWhere((c) => c.id == _selectedId);
      final w = cupboard.width * scale;
      final d = cupboard.depth * scale;
      final bx = _tempBlueprintX ?? cupboard.blueprintX;
      final by = _tempBlueprintY ?? cupboard.blueprintY;
      itemRect = Rect.fromLTWH(
        roomRect.left + bx * roomRect.width - w / 2,
        roomRect.top + by * roomRect.height - d / 2,
        w,
        d,
      );
    } else if (_selectedType == 'furniture_wall') {
      final item = design.furniture.firstWhere((f) => f.id == _selectedId);
      itemRect = _wallItemRect(item, roomRect, scale);
    }

    if (itemRect == null) return const SizedBox.shrink();

    return Positioned(
      left: itemRect.center.dx - 72,
      top: itemRect.top - 44,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(20),
        color: Colors.orange.shade700,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canRotate) ...[
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.rotate_left, color: Colors.white, size: 20),
                  tooltip: 'Rotate left',
                  onPressed: () => _rotateSelected(design, -15),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.rotate_right, color: Colors.white, size: 20),
                  tooltip: 'Rotate right',
                  onPressed: () => _rotateSelected(design, 15),
                ),
              ],
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                tooltip: 'Deselect',
                onPressed: _deselect,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Rect _wallItemRect(FurnitureItem item, Rect roomRect, double scale) {
    final wall = item.wall ?? WallId.left;
    final along = item.positionFromEdge * scale;
    final into = item.depth * scale;
    final alongSize = item.width * scale;

    switch (wall) {
      case WallId.front:
        return Rect.fromLTWH(roomRect.left + along, roomRect.top, alongSize, into);
      case WallId.back:
        return Rect.fromLTWH(roomRect.left + along, roomRect.bottom - into, alongSize, into);
      case WallId.left:
        return Rect.fromLTWH(roomRect.left, roomRect.top + along, into, alongSize);
      case WallId.right:
        return Rect.fromLTWH(roomRect.right - into, roomRect.top + along, into, alongSize);
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
    required double rotation,
    required RoomDesign design,
    required Rect roomRect,
    required double scale,
    VoidCallback? onFloorDrag,
    void Function(Offset center)? onWallDrag,
  }) {
    final isSelected = _selectedId == id;
    final isDragging = isSelected && _isDragging;

    final itemCenter = Offset(left + width / 2, top + height / 2);

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onLongPress: () => _selectItem(id, dragType),
        onPanDown: (_) {
          _holdItemId = id;
          _holdTimer?.cancel();
          _holdTimer = Timer(_holdDuration, () {
            if (_holdItemId != id) return;
            _selectItem(id, dragType);
            _beginDrag(itemCenter);
          });
        },
        onPanUpdate: (details) {
          if (_selectedId != id || !_isDragging) return;
          setState(() {
            _dragDelta += details.delta;
            if (onFloorDrag != null) {
              onFloorDrag();
            } else if (onWallDrag != null) {
              final center = (_dragStartCenter ?? itemCenter) + _dragDelta;
              onWallDrag(center);
            }
          });
        },
        onPanEnd: (_) {
          _cancelHold();
          if (_selectedId == id && _isDragging) {
            _commitDrag(design, roomRect, scale);
          }
        },
        onPanCancel: () {
          _cancelHold();
          if (_selectedId == id && _isDragging) {
            _commitDrag(design, roomRect, scale);
          }
        },
        child: Transform.rotate(
          angle: rotation * math.pi / 180,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDragging ? 0.9 : 0.75),
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.black54,
                width: isSelected ? 2.5 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: isDragging
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
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

  final RoomDesign design;
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

      final rect = switch (door.wall) {
        WallId.front => Rect.fromLTWH(roomRect.left + offset, roomRect.top - 4, dw, 8),
        WallId.back => Rect.fromLTWH(roomRect.left + offset, roomRect.bottom - 4, dw, 8),
        WallId.left => Rect.fromLTWH(roomRect.left - 4, roomRect.top + offset, 8, dw),
        WallId.right => Rect.fromLTWH(roomRect.right - 4, roomRect.top + offset, 8, dw),
      };
      canvas.drawRect(rect, paint);
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

    tp.text = TextSpan(text: '${design.dimensions.width} ft', style: style);
    tp.layout();
    tp.paint(canvas, Offset(roomRect.center.dx - tp.width / 2, roomRect.top - 24));

    tp.text = TextSpan(text: '${design.dimensions.length} ft', style: style);
    tp.layout();
    tp.paint(canvas, Offset(roomRect.right + 8, roomRect.center.dy - tp.height / 2));
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
