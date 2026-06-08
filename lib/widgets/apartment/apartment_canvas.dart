import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/blueprint_placement.dart';
import '../../models/apartment_layout.dart';
import '../../models/project_design.dart';
import '../../models/room_design.dart';
import '../../providers/project_provider.dart';
import '../blueprint/room_blueprint_layout_painter.dart';

class ApartmentCanvas extends ConsumerStatefulWidget {
  const ApartmentCanvas({super.key});

  @override
  ConsumerState<ApartmentCanvas> createState() => _ApartmentCanvasState();
}

class _ApartmentCanvasState extends ConsumerState<ApartmentCanvas> {
  static const _holdDuration = Duration(milliseconds: 420);

  String? _selectedId;
  bool _isDragging = false;
  Offset _dragDelta = Offset.zero;
  Offset? _dragStartCenter;
  Timer? _holdTimer;
  String? _holdItemId;

  double? _tempBlueprintX;
  double? _tempBlueprintY;

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdItemId = null;
  }

  void _clearStaleSelection(ProjectDesign project) {
    if (_selectedId == null) return;
    final exists = project.apartmentLayout.placements.any((p) => p.id == _selectedId);
    if (!exists) {
      _selectedId = null;
      _isDragging = false;
      _dragDelta = Offset.zero;
      _dragStartCenter = null;
      _tempBlueprintX = null;
      _tempBlueprintY = null;
      _cancelHold();
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider);
    _clearStaleSelection(project);
    final layout = project.apartmentLayout;

    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = 32.0;
        final availW = constraints.maxWidth - padding * 2;
        final availH = constraints.maxHeight - padding * 2;
        final scale = math.min(
          availW / layout.widthFt,
          availH / layout.lengthFt,
        );
        final aptW = layout.widthFt * scale;
        final aptH = layout.lengthFt * scale;
        final offsetX = (constraints.maxWidth - aptW) / 2;
        final offsetY = (constraints.maxHeight - aptH) / 2;
        final aptRect = Rect.fromLTWH(offsetX, offsetY, aptW, aptH);

        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          boundaryMargin: const EdgeInsets.all(120),
          panEnabled: !_isDragging,
          scaleEnabled: !_isDragging,
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _deselect,
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _ApartmentPainter(
                      aptRect: aptRect,
                      scale: scale,
                    ),
                  ),
                ),
                ...layout.placements.map((placement) {
                  final room = project.roomById(placement.roomId);
                  if (room == null) return const SizedBox.shrink();
                  return _buildRoomLayout(
                    placement: placement,
                    room: room,
                    layout: layout,
                    aptRect: aptRect,
                    scale: scale,
                  );
                }),
                if (_selectedId != null &&
                    project.apartmentLayout.placements.any((p) => p.id == _selectedId))
                  _buildSelectionToolbar(
                    project: project,
                    layout: layout,
                    aptRect: aptRect,
                    scale: scale,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomLayout({
    required ApartmentRoomPlacement placement,
    required RoomDesign room,
    required ApartmentLayout layout,
    required Rect aptRect,
    required double scale,
  }) {
    final bx = (_isDragging && _selectedId == placement.id && _tempBlueprintX != null)
        ? _tempBlueprintX!
        : placement.blueprintX;
    final by = (_isDragging && _selectedId == placement.id && _tempBlueprintY != null)
        ? _tempBlueprintY!
        : placement.blueprintY;

    final pixelLayout = BlueprintPlacement.layoutPixels(
      blueprintX: bx,
      blueprintY: by,
      widthFt: room.dimensions.width,
      depthFt: room.dimensions.length,
      rotationDeg: placement.rotation,
      roomRect: aptRect,
      scale: scale,
    );

    final isSelected = _selectedId == placement.id;
    final isDragging = isSelected && _isDragging;
    final itemCenter = Offset(
      pixelLayout.left + pixelLayout.bboxW / 2 + _dragDelta.dx,
      pixelLayout.top + pixelLayout.bboxH / 2 + _dragDelta.dy,
    );

    return Positioned(
      left: pixelLayout.left + _dragDelta.dx,
      top: pixelLayout.top + _dragDelta.dy,
      width: pixelLayout.bboxW,
      height: pixelLayout.bboxH,
      child: GestureDetector(
        onLongPress: () => _selectPlacement(placement.id),
        onPanDown: (_) {
          _holdItemId = placement.id;
          _holdTimer?.cancel();
          _holdTimer = Timer(_holdDuration, () {
            if (_holdItemId != placement.id) return;
            _selectPlacement(placement.id);
            _beginDrag(itemCenter);
          });
        },
        onPanUpdate: (details) {
          if (_selectedId != placement.id || !_isDragging) return;
          setState(() => _dragDelta += details.delta);
          final center = (_dragStartCenter ?? itemCenter) + _dragDelta;
          _updateTempPosition(
            center: center,
            room: room,
            layout: layout,
            aptRect: aptRect,
            placement: placement,
          );
        },
        onPanEnd: (_) {
          _cancelHold();
          if (_selectedId == placement.id && _isDragging) {
            _commitDrag(placement, layout, room);
          }
        },
        onPanCancel: () {
          _cancelHold();
          if (_selectedId == placement.id && _isDragging) {
            _commitDrag(placement, layout, room);
          }
        },
        child: SizedBox(
          width: pixelLayout.bboxW,
          height: pixelLayout.bboxH,
          child: Center(
            child: Transform.rotate(
              angle: placement.rotation * math.pi / 180,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                width: pixelLayout.innerW,
                height: pixelLayout.innerH,
                decoration: isDragging
                    ? BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      )
                    : null,
                child: CustomPaint(
                  size: Size(pixelLayout.innerW, pixelLayout.innerH),
                  painter: RoomBlueprintLayoutPainter(
                    design: room,
                    roomRect: Rect.fromLTWH(0, 0, pixelLayout.innerW, pixelLayout.innerH),
                    scale: scale,
                    isSelected: isSelected,
                    showWallLabels: pixelLayout.innerW >= 70,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionToolbar({
    required ProjectDesign project,
    required ApartmentLayout layout,
    required Rect aptRect,
    required double scale,
  }) {
    final placement =
        layout.placements.firstWhereOrNull((p) => p.id == _selectedId);
    if (placement == null) return const SizedBox.shrink();

    final room = project.roomById(placement.roomId);
    if (room == null) return const SizedBox.shrink();

    final bx = _tempBlueprintX ?? placement.blueprintX;
    final by = _tempBlueprintY ?? placement.blueprintY;
    final pixelLayout = BlueprintPlacement.layoutPixels(
      blueprintX: bx,
      blueprintY: by,
      widthFt: room.dimensions.width,
      depthFt: room.dimensions.length,
      rotationDeg: placement.rotation,
      roomRect: aptRect,
      scale: scale,
    );

    final itemRect = Rect.fromLTWH(
      pixelLayout.left + _dragDelta.dx,
      pixelLayout.top + _dragDelta.dy,
      pixelLayout.bboxW,
      pixelLayout.bboxH,
    );

    return Positioned(
      left: itemRect.center.dx - 88,
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
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.rotate_left, color: Colors.white, size: 20),
                tooltip: 'Rotate left',
                onPressed: () => _rotateSelected(placement, -15),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.rotate_right, color: Colors.white, size: 20),
                tooltip: 'Rotate right',
                onPressed: () => _rotateSelected(placement, 15),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                tooltip: 'Remove from blueprint',
                onPressed: () {
                  ref.read(projectProvider.notifier).removeApartmentPlacement(placement.id);
                  _deselect();
                },
              ),
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

  void _selectPlacement(String id) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedId = id;
      _isDragging = false;
      _dragDelta = Offset.zero;
      _dragStartCenter = null;
      _tempBlueprintX = null;
      _tempBlueprintY = null;
    });
  }

  void _deselect() {
    if (_selectedId == null) return;
    setState(() {
      _selectedId = null;
      _isDragging = false;
      _dragDelta = Offset.zero;
      _dragStartCenter = null;
      _tempBlueprintX = null;
      _tempBlueprintY = null;
    });
  }

  void _beginDrag(Offset center) {
    setState(() {
      _isDragging = true;
      _dragStartCenter = center;
    });
  }

  void _updateTempPosition({
    required Offset center,
    required RoomDesign room,
    required ApartmentLayout layout,
    required Rect aptRect,
    required ApartmentRoomPlacement placement,
  }) {
    final normX = ((center.dx - aptRect.left) / aptRect.width).clamp(0.0, 1.0);
    final normY = ((center.dy - aptRect.top) / aptRect.height).clamp(0.0, 1.0);
    final clamped = BlueprintPlacement.clampBlueprintCenter(
      centerXNorm: normX,
      centerYNorm: normY,
      widthFt: room.dimensions.width,
      depthFt: room.dimensions.length,
      rotationDeg: placement.rotation,
      roomWidthFt: layout.widthFt,
      roomLengthFt: layout.lengthFt,
    );
    setState(() {
      _tempBlueprintX = clamped.bx;
      _tempBlueprintY = clamped.by;
    });
  }

  void _commitDrag(
    ApartmentRoomPlacement placement,
    ApartmentLayout layout,
    RoomDesign room,
  ) {
    final notifier = ref.read(projectProvider.notifier);
    if (_tempBlueprintX != null && _tempBlueprintY != null) {
      notifier.updateApartmentPlacement(
        placement.copyWith(
          blueprintX: _tempBlueprintX!,
          blueprintY: _tempBlueprintY!,
        ),
      );
    }
    setState(() {
      _isDragging = false;
      _dragDelta = Offset.zero;
      _dragStartCenter = null;
      _tempBlueprintX = null;
      _tempBlueprintY = null;
    });
  }

  void _rotateSelected(ApartmentRoomPlacement placement, double delta) {
    final next = (placement.rotation + delta) % 360;
    ref.read(projectProvider.notifier).updateApartmentPlacement(
          placement.copyWith(rotation: next < 0 ? next + 360 : next),
        );
  }
}

class _ApartmentPainter extends CustomPainter {
  _ApartmentPainter({
    required this.aptRect,
    required this.scale,
  });

  final Rect aptRect;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.blue.shade50;
    canvas.drawRect(Offset.zero & size, bg);

    final floor = Paint()..color = const Color(0xFFF5F5F5);
    canvas.drawRect(aptRect, floor);

    final border = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(aptRect, border);

    final gridPaint = Paint()
      ..color = Colors.blueGrey.shade200
      ..strokeWidth = 0.5;

    for (var ft = 1.0; ft < aptRect.width / scale; ft += 1) {
      final x = aptRect.left + ft * scale;
      canvas.drawLine(Offset(x, aptRect.top), Offset(x, aptRect.bottom), gridPaint);
    }
    for (var ft = 1.0; ft < aptRect.height / scale; ft += 1) {
      final y = aptRect.top + ft * scale;
      canvas.drawLine(Offset(aptRect.left, y), Offset(aptRect.right, y), gridPaint);
    }

    final label = TextPainter(
      text: TextSpan(
        text: 'Apartment Floor Plan',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(aptRect.left + 8, aptRect.top - 20));
  }

  @override
  bool shouldRepaint(covariant _ApartmentPainter oldDelegate) =>
      oldDelegate.aptRect != aptRect || oldDelegate.scale != scale;
}
