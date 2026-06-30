import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/blueprint_viewport_fit.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/blueprint_placement.dart';
import '../../models/apartment_layout.dart';
import '../../models/project_design.dart';
import '../../models/room_design.dart';
import '../../providers/apartment_blueprint_selection_provider.dart';
import '../../providers/apartment_placement_history_provider.dart';
import '../../providers/project_provider.dart';
import '../blueprint/room_blueprint_layout_painter.dart';

class ApartmentCanvas extends ConsumerStatefulWidget {
  const ApartmentCanvas({super.key, this.immersive = false});

  /// When true, fills the viewport (e.g. full screen) and auto-fits the layout.
  final bool immersive;

  @override
  ConsumerState<ApartmentCanvas> createState() => _ApartmentCanvasState();
}

class _ApartmentCanvasState extends ConsumerState<ApartmentCanvas> {
  static const _holdDuration = Duration(milliseconds: 420);

  TransformationController? _transformController;
  Size? _lastFitViewport;

  String? _dragAnchorId;
  bool _isDragging = false;
  Offset _dragDelta = Offset.zero;
  Offset? _dragStartCenter;
  Timer? _holdTimer;
  String? _holdItemId;

  final Map<String, ({double x, double y})> _groupStartPositions = {};
  final Map<String, ({double x, double y})> _tempGroupPositions = {};

  @override
  void initState() {
    super.initState();
    if (widget.immersive) {
      _transformController = TransformationController();
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _transformController?.dispose();
    super.dispose();
  }

  void _scheduleViewportFit(Size viewport, Rect contentRect) {
    if (!widget.immersive || _transformController == null) return;
    if (_lastFitViewport == viewport) return;
    _lastFitViewport = viewport;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      BlueprintViewportFit.apply(
        _transformController!,
        viewport,
        contentRect,
        margin: 12,
      );
    });
  }

  @override
  void didUpdateWidget(covariant ApartmentCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.immersive != widget.immersive) {
      _lastFitViewport = null;
      if (widget.immersive && _transformController == null) {
        _transformController = TransformationController();
      } else if (!widget.immersive) {
        _transformController?.dispose();
        _transformController = null;
      }
    }
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdItemId = null;
  }

  void _clearStaleSelection(ProjectDesign project) {
    ref
        .read(apartmentBlueprintSelectionProvider.notifier)
        .pruneMissing(project.apartmentLayout.placements.map((p) => p.id));
    if (_dragAnchorId != null &&
        !project.apartmentLayout.placements.any((p) => p.id == _dragAnchorId)) {
      _dragAnchorId = null;
      _isDragging = false;
      _dragDelta = Offset.zero;
      _dragStartCenter = null;
      _groupStartPositions.clear();
      _tempGroupPositions.clear();
      _cancelHold();
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider);
    final selectedIds = ref.watch(apartmentBlueprintSelectionProvider);
    _clearStaleSelection(project);
    final layout = project.apartmentLayout;

    return LayoutBuilder(
      builder: (context, constraints) {
        const edgePadding = 32.0;
        final padding = widget.immersive ? 12.0 : edgePadding;
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
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        if (widget.immersive) {
          _scheduleViewportFit(viewport, aptRect);
        }

        return InteractiveViewer(
          transformationController: _transformController,
          minScale: 0.35,
          maxScale: 6.0,
          boundaryMargin: widget.immersive
              ? EdgeInsets.zero
              : const EdgeInsets.all(120),
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
                      widthFt: layout.widthFt,
                      lengthFt: layout.lengthFt,
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
                    selectedIds: selectedIds,
                    project: project,
                  );
                }),
                if (selectedIds.isNotEmpty)
                  _buildSelectionToolbar(
                    project: project,
                    layout: layout,
                    aptRect: aptRect,
                    scale: scale,
                    selectedIds: selectedIds,
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
    required Set<String> selectedIds,
    required ProjectDesign project,
  }) {
    final (bx, by) = _displayPosition(placement);
    final isSelected = selectedIds.contains(placement.id);
    final isDragging = _isDragging && isSelected && _dragAnchorId != null;

    final pixelLayout = BlueprintPlacement.layoutPixels(
      blueprintX: bx,
      blueprintY: by,
      widthFt: room.dimensions.width,
      depthFt: room.dimensions.length,
      rotationDeg: placement.rotation,
      roomRect: aptRect,
      scale: scale,
    );

    final itemCenter = Offset(
      pixelLayout.left + pixelLayout.bboxW / 2,
      pixelLayout.top + pixelLayout.bboxH / 2,
    );

    return Positioned(
      left: pixelLayout.left,
      top: pixelLayout.top,
      width: pixelLayout.bboxW,
      height: pixelLayout.bboxH,
      child: GestureDetector(
        onLongPress: () => _activatePlacement(
          placement: placement,
          itemCenter: itemCenter,
          selectedIds: selectedIds,
        ),
        onPanDown: (_) {
          _holdItemId = placement.id;
          _holdTimer?.cancel();
          _holdTimer = Timer(_holdDuration, () {
            if (_holdItemId != placement.id) return;
            _activatePlacement(
              placement: placement,
              itemCenter: itemCenter,
              selectedIds: selectedIds,
            );
          });
        },
        onPanUpdate: (details) {
          if (_dragAnchorId != placement.id || !_isDragging) return;
          setState(() {
            _dragDelta += details.delta;
            final center = (_dragStartCenter ?? itemCenter) + _dragDelta;
            _updateGroupDrag(
              anchorCenter: center,
              anchorPlacement: placement,
              anchorRoom: room,
              layout: layout,
              aptRect: aptRect,
              project: project,
              selectedIds: selectedIds,
            );
          });
        },
        onPanEnd: (_) {
          _cancelHold();
          if (_dragAnchorId == placement.id && _isDragging) {
            _commitGroupDrag(project, layout);
          }
        },
        onPanCancel: () {
          _cancelHold();
          if (_dragAnchorId == placement.id && _isDragging) {
            _commitGroupDrag(project, layout);
          }
        },
        child: SizedBox(
          width: pixelLayout.bboxW,
          height: pixelLayout.bboxH,
          child: Center(
            child: OverflowBox(
              maxWidth: pixelLayout.innerW,
              maxHeight: pixelLayout.innerH,
              minWidth: pixelLayout.innerW,
              minHeight: pixelLayout.innerH,
              alignment: Alignment.center,
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
      ),
    );
  }

  Widget _buildSelectionToolbar({
    required ProjectDesign project,
    required ApartmentLayout layout,
    required Rect aptRect,
    required double scale,
    required Set<String> selectedIds,
  }) {
    if (selectedIds.length > 1) {
      return _buildGroupSelectionToolbar(
        project: project,
        layout: layout,
        aptRect: aptRect,
        scale: scale,
        selectedIds: selectedIds,
      );
    }

    final placement =
        layout.placements.firstWhereOrNull((p) => selectedIds.contains(p.id));
    if (placement == null) return const SizedBox.shrink();

    final room = project.roomById(placement.roomId);
    if (room == null) return const SizedBox.shrink();

    final (bx, by) = _displayPosition(placement);
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
      pixelLayout.left,
      pixelLayout.top,
      pixelLayout.bboxW,
      pixelLayout.bboxH,
    );

    return Positioned(
      left: itemRect.center.dx - 88,
      top: itemRect.top - 44,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.primary.withValues(alpha: 0.85),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.rotate_left, color: Colors.white, size: 18),
                tooltip: 'Rotate left',
                onPressed: () => _rotateSelected(placement, -15),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.rotate_right, color: Colors.white, size: 18),
                tooltip: 'Rotate right',
                onPressed: () => _rotateSelected(placement, 15),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                tooltip: 'Remove from blueprint',
                onPressed: () {
                  ref.read(projectProvider.notifier).removeApartmentPlacement(placement.id);
                  _deselect();
                },
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, color: Colors.white, size: 16),
                tooltip: 'Deselect',
                onPressed: _deselect,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupSelectionToolbar({
    required ProjectDesign project,
    required ApartmentLayout layout,
    required Rect aptRect,
    required double scale,
    required Set<String> selectedIds,
  }) {
    Rect? bounds;
    for (final placement in layout.placements.where((p) => selectedIds.contains(p.id))) {
      final room = project.roomById(placement.roomId);
      if (room == null) continue;
      final (bx, by) = _displayPosition(placement);
      final pixelLayout = BlueprintPlacement.layoutPixels(
        blueprintX: bx,
        blueprintY: by,
        widthFt: room.dimensions.width,
        depthFt: room.dimensions.length,
        rotationDeg: placement.rotation,
        roomRect: aptRect,
        scale: scale,
      );
      final rect = Rect.fromLTWH(
        pixelLayout.left,
        pixelLayout.top,
        pixelLayout.bboxW,
        pixelLayout.bboxH,
      );
      bounds = bounds == null ? rect : bounds.expandToInclude(rect);
    }
    if (bounds == null) return const SizedBox.shrink();

    return Positioned(
      left: bounds.center.dx - 72,
      top: bounds.top - 44,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.primary.withValues(alpha: 0.85),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${selectedIds.length} rooms',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, color: Colors.white, size: 16),
                tooltip: 'Deselect all',
                onPressed: _deselect,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _activatePlacement({
    required ApartmentRoomPlacement placement,
    required Offset itemCenter,
    required Set<String> selectedIds,
  }) {
    final selection = ref.read(apartmentBlueprintSelectionProvider.notifier);
    if (selectedIds.contains(placement.id) && selectedIds.length > 1) {
      // Keep the current multi-selection.
    } else {
      selection.selectOne(placement.id);
    }
    final activeSelection = ref.read(apartmentBlueprintSelectionProvider);
    _selectPlacementForDrag(placement.id, itemCenter, activeSelection);
  }

  (double, double) _displayPosition(ApartmentRoomPlacement placement) {
    final temp = _tempGroupPositions[placement.id];
    if (_isDragging && temp != null) {
      return (temp.x, temp.y);
    }
    return (placement.blueprintX, placement.blueprintY);
  }

  void _selectPlacementForDrag(String anchorId, Offset center, Set<String> selectedIds) {
    HapticFeedback.mediumImpact();
    setState(() {
      _dragAnchorId = anchorId;
      _isDragging = true;
      _dragStartCenter = center;
      _dragDelta = Offset.zero;
      _groupStartPositions.clear();
      _tempGroupPositions.clear();

      final project = ref.read(projectProvider);
      for (final id in selectedIds) {
        final placement = project.apartmentLayout.placements.firstWhereOrNull((p) => p.id == id);
        if (placement == null) continue;
        final pos = (x: placement.blueprintX, y: placement.blueprintY);
        _groupStartPositions[id] = pos;
        _tempGroupPositions[id] = pos;
      }
    });
  }

  void _deselect() {
    if (ref.read(apartmentBlueprintSelectionProvider).isEmpty && !_isDragging) return;
    ref.read(apartmentBlueprintSelectionProvider.notifier).clear();
    setState(() {
      _dragAnchorId = null;
      _isDragging = false;
      _dragDelta = Offset.zero;
      _dragStartCenter = null;
      _groupStartPositions.clear();
      _tempGroupPositions.clear();
    });
  }

  void _updateGroupDrag({
    required Offset anchorCenter,
    required ApartmentRoomPlacement anchorPlacement,
    required RoomDesign anchorRoom,
    required ApartmentLayout layout,
    required Rect aptRect,
    required ProjectDesign project,
    required Set<String> selectedIds,
  }) {
    final anchorStart = _groupStartPositions[anchorPlacement.id];
    if (anchorStart == null) return;

    final anchorNormX = ((anchorCenter.dx - aptRect.left) / aptRect.width).clamp(0.0, 1.0);
    final anchorNormY = ((anchorCenter.dy - aptRect.top) / aptRect.height).clamp(0.0, 1.0);
    final anchorClamped = BlueprintPlacement.clampBlueprintCenter(
      centerXNorm: anchorNormX,
      centerYNorm: anchorNormY,
      widthFt: anchorRoom.dimensions.width,
      depthFt: anchorRoom.dimensions.length,
      rotationDeg: anchorPlacement.rotation,
      roomWidthFt: layout.widthFt,
      roomLengthFt: layout.lengthFt,
    );
    final deltaX = anchorClamped.bx - anchorStart.x;
    final deltaY = anchorClamped.by - anchorStart.y;

    for (final id in selectedIds) {
      final start = _groupStartPositions[id];
      final placement = layout.placements.firstWhereOrNull((p) => p.id == id);
      final room = placement == null ? null : project.roomById(placement.roomId);
      if (start == null || placement == null || room == null) continue;

      final clamped = BlueprintPlacement.clampBlueprintCenter(
        centerXNorm: start.x + deltaX,
        centerYNorm: start.y + deltaY,
        widthFt: room.dimensions.width,
        depthFt: room.dimensions.length,
        rotationDeg: placement.rotation,
        roomWidthFt: layout.widthFt,
        roomLengthFt: layout.lengthFt,
      );
      _tempGroupPositions[id] = (x: clamped.bx, y: clamped.by);
    }
  }

  void _commitGroupDrag(ProjectDesign project, ApartmentLayout layout) {
    final notifier = ref.read(projectProvider.notifier);
    final updates = <String, ApartmentRoomPlacement>{};
    var moved = false;

    for (final entry in _tempGroupPositions.entries) {
      final placement = layout.placements.firstWhereOrNull((p) => p.id == entry.key);
      if (placement == null) continue;
      if ((entry.value.x - placement.blueprintX).abs() > 1e-6 ||
          (entry.value.y - placement.blueprintY).abs() > 1e-6) {
        moved = true;
      }
      updates[entry.key] = placement.copyWith(
        blueprintX: entry.value.x,
        blueprintY: entry.value.y,
      );
    }

    if (moved) {
      ref.read(apartmentPlacementHistoryProvider.notifier).recordBeforeChange();
      notifier.updateApartmentPlacements(updates);
    }

    setState(() {
      _dragAnchorId = null;
      _isDragging = false;
      _dragDelta = Offset.zero;
      _dragStartCenter = null;
      _groupStartPositions.clear();
      _tempGroupPositions.clear();
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
    required this.widthFt,
    required this.lengthFt,
  });

  final Rect aptRect;
  final double scale;
  final double widthFt;
  final double lengthFt;

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
        text: 'Apartment Floor Plan • ${widthFt.toStringAsFixed(0)} × ${lengthFt.toStringAsFixed(0)} ft',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(aptRect.left + 8, aptRect.top - 20));
  }

  @override
  bool shouldRepaint(covariant _ApartmentPainter oldDelegate) =>
      oldDelegate.aptRect != aptRect ||
      oldDelegate.scale != scale ||
      oldDelegate.widthFt != widthFt ||
      oldDelegate.lengthFt != lengthFt;
}
