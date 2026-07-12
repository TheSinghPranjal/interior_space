import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/blueprint_viewport_fit.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/blueprint_door_paint.dart';
import '../../core/utils/blueprint_stair_paint.dart';
import '../../core/utils/blueprint_placement.dart';
import '../../core/utils/blueprint_wall_border_paint.dart';
import '../../core/utils/color_utils.dart';
import '../../models/ac_unit_config.dart';
import '../../models/curtain_config.dart';
import '../../models/door_config.dart';
import '../../models/enums.dart';
import '../../models/furniture_item.dart';
import '../../models/room_design.dart';
import '../../models/stair_config.dart';
import '../../models/wall_tv_unit_config.dart';
import '../../models/window_config.dart';
import '../../core/utils/blueprint_premium_assets.dart';
import '../../providers/blueprint_premium_assets_provider.dart';
import '../../providers/room_design_provider.dart';

class BlueprintCanvas extends ConsumerStatefulWidget {
  const BlueprintCanvas({super.key, this.immersive = false});

  /// When true, fills the viewport (e.g. full screen) and auto-fits the room.
  final bool immersive;

  @override
  ConsumerState<BlueprintCanvas> createState() => _BlueprintCanvasState();
}

class _BlueprintCanvasState extends ConsumerState<BlueprintCanvas> {
  static const _holdDuration = Duration(milliseconds: 420);

  TransformationController? _transformController;
  Size? _lastFitViewport;

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
  void didUpdateWidget(covariant BlueprintCanvas oldWidget) {
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

  bool _selectionValid(RoomDesign design) {
    if (_selectedId == null || _selectedType == null) return false;
    switch (_selectedType!) {
      case 'furniture_floor':
      case 'furniture_wall':
        return design.furniture.any((f) => f.id == _selectedId);
      case 'stair_floor':
        return design.stairs.any((s) => s.id == _selectedId);
      case 'door_wall':
        return design.doors.any((d) => d.id == _selectedId);
      case 'window_wall':
        return design.windows.any((w) => w.id == _selectedId);
      case 'curtain_wall':
        return design.curtains.any((c) => c.id == _selectedId);
      case 'ac_unit_wall':
        return design.acUnits.any((a) => a.id == _selectedId);
      case 'wall_tv_wall':
        return design.wallTvUnits.any((t) => t.id == _selectedId);
      default:
        return false;
    }
  }

  void _clearStaleSelection(RoomDesign design) {
    if (_selectedId != null && !_selectionValid(design)) {
      _selectedId = null;
      _selectedType = null;
      _isDragging = false;
      _dragDelta = Offset.zero;
      _dragStartCenter = null;
      _tempBlueprintX = null;
      _tempBlueprintY = null;
      _tempPositionFromEdge = null;
      _cancelHold();
    }
  }

  @override
  Widget build(BuildContext context) {
    final design = ref.watch(roomDesignProvider);
    final premiumFurniture = ref.watch(premiumFurnitureProvider);
    final premiumImagesAsync = ref.watch(blueprintPremiumImagesProvider);
    final premiumImages = premiumImagesAsync.valueOrNull;
    _clearStaleSelection(design);

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = widget.immersive ? 12.0 : 32.0;
        final availW = constraints.maxWidth - padding * 2;
        final availH = constraints.maxHeight - padding * 2;
        final scale = math.min(
          availW / design.dimensions.effectiveWidth,
          availH / design.dimensions.effectiveLength,
        );
        final roomW = design.dimensions.effectiveWidth * scale;
        final roomH = design.dimensions.effectiveLength * scale;
        final offsetX = (constraints.maxWidth - roomW) / 2;
        final offsetY = (constraints.maxHeight - roomH) / 2;
        final roomRect = Rect.fromLTWH(offsetX, offsetY, roomW, roomH);
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        if (widget.immersive) {
          _scheduleViewportFit(viewport, roomRect);
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
            ...design.stairs.map((stair) {
              return _buildStairItem(
                stair: stair,
                design: design,
                roomRect: roomRect,
                scale: scale,
              );
            }),
            ...design.furniture.where((f) => !f.isWallMounted).map((item) {
              return _buildFloorItem(
                item: item,
                design: design,
                roomRect: roomRect,
                scale: scale,
                premiumFurniture: premiumFurniture,
                premiumImages: premiumImages,
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
            ...design.doors.map((door) {
              return _buildDoorItem(
                door: door,
                design: design,
                roomRect: roomRect,
                scale: scale,
              );
            }),
            ...design.windows.map((window) {
              return _buildWindowItem(
                window: window,
                design: design,
                roomRect: roomRect,
                scale: scale,
              );
            }),
            ...design.curtains.map((curtain) {
              return _buildCurtainItem(
                curtain: curtain,
                design: design,
                roomRect: roomRect,
                scale: scale,
              );
            }),
            ...design.acUnits.map((unit) {
              return _buildAcUnitItem(
                unit: unit,
                design: design,
                roomRect: roomRect,
                scale: scale,
              );
            }),
            ...design.wallTvUnits.map((unit) {
              return _buildWallTvUnitItem(
                unit: unit,
                design: design,
                roomRect: roomRect,
                scale: scale,
              );
            }),
            if (_selectedId != null && _selectionValid(design))
              _buildSelectionToolbar(design: design, roomRect: roomRect, scale: scale),
              ],
            ),
          ),
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
    if (_selectedId == null || _selectedType == null || !_selectionValid(design)) return;

    final notifier = ref.read(roomDesignProvider.notifier);

    if (_selectedType == 'furniture_floor' && _tempBlueprintX != null && _tempBlueprintY != null) {
      final item = design.furniture.firstWhere((f) => f.id == _selectedId);
      notifier.updateFurniture(
        item.copyWith(blueprintX: _tempBlueprintX!, blueprintY: _tempBlueprintY!),
      );
    } else if (_selectedType == 'stair_floor' && _tempBlueprintX != null && _tempBlueprintY != null) {
      final stair = design.stairs.firstWhere((s) => s.id == _selectedId);
      notifier.updateStair(
        stair.copyWith(blueprintX: _tempBlueprintX!, blueprintY: _tempBlueprintY!),
      );
    } else if (_selectedType == 'furniture_wall' && _tempPositionFromEdge != null) {
      final item = design.furniture.firstWhere((f) => f.id == _selectedId);
      notifier.updateFurniture(item.copyWith(positionFromEdge: _tempPositionFromEdge!));
    } else if (_selectedType == 'door_wall' && _tempPositionFromEdge != null) {
      final door = design.doors.firstWhere((d) => d.id == _selectedId);
      notifier.updateDoor(door.copyWith(positionFromEdge: _tempPositionFromEdge!));
    } else if (_selectedType == 'window_wall' && _tempPositionFromEdge != null) {
      final window = design.windows.firstWhere((w) => w.id == _selectedId);
      notifier.updateWindow(window.copyWith(positionFromEdge: _tempPositionFromEdge!));
    } else if (_selectedType == 'curtain_wall' && _tempPositionFromEdge != null) {
      final curtain = design.curtains.firstWhere((c) => c.id == _selectedId);
      notifier.updateCurtain(curtain.copyWith(positionFromEdge: _tempPositionFromEdge!));
    } else if (_selectedType == 'ac_unit_wall' && _tempPositionFromEdge != null) {
      final unit = design.acUnits.firstWhere((a) => a.id == _selectedId);
      notifier.updateAcUnit(unit.copyWith(positionFromEdge: _tempPositionFromEdge!));
    } else if (_selectedType == 'wall_tv_wall' && _tempPositionFromEdge != null) {
      final unit = design.wallTvUnits.firstWhere((t) => t.id == _selectedId);
      notifier.updateWallTvUnit(unit.copyWith(positionFromEdge: _tempPositionFromEdge!));
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

  void _deleteSelected(RoomDesign design) {
    if (_selectedId == null || _selectedType == null || !_selectionValid(design)) return;
    HapticFeedback.mediumImpact();
    final notifier = ref.read(roomDesignProvider.notifier);
    final id = _selectedId!;

    switch (_selectedType!) {
      case 'furniture_floor':
      case 'furniture_wall':
        notifier.removeFurniture(id);
      case 'stair_floor':
        notifier.removeStair(id);
      case 'door_wall':
        notifier.removeDoor(id);
      case 'window_wall':
        notifier.removeWindow(id);
      case 'curtain_wall':
        notifier.removeCurtain(id);
      case 'ac_unit_wall':
        notifier.removeAcUnit(id);
      case 'wall_tv_wall':
        notifier.removeWallTvUnit(id);
    }

    _deselect();
  }

  void _flipDoorSwing(RoomDesign design) {
    if (_selectedId == null || _selectedType != 'door_wall' || !_selectionValid(design)) return;
    final door = design.doors.firstWhere((d) => d.id == _selectedId);
    final next = door.swingDirection == DoorSwingDirection.inward
        ? DoorSwingDirection.outward
        : DoorSwingDirection.inward;
    ref.read(roomDesignProvider.notifier).updateDoor(door.copyWith(swingDirection: next));
    HapticFeedback.selectionClick();
  }

  void _flipDoorHinge(RoomDesign design) {
    if (_selectedId == null || _selectedType != 'door_wall' || !_selectionValid(design)) return;
    final door = design.doors.firstWhere((d) => d.id == _selectedId);
    final next = door.hingeSide == DoorHingeSide.start ? DoorHingeSide.end : DoorHingeSide.start;
    ref.read(roomDesignProvider.notifier).updateDoor(door.copyWith(hingeSide: next));
    HapticFeedback.selectionClick();
  }

  void _rotateSelected(RoomDesign design, double degrees) {
    if (_selectedId == null || _selectedType == null || !_selectionValid(design)) return;
    HapticFeedback.selectionClick();
    final notifier = ref.read(roomDesignProvider.notifier);

    if (_selectedType == 'furniture_floor') {
      final item = design.furniture.firstWhere((f) => f.id == _selectedId);
      final next = (item.rotation + degrees) % 360;
      notifier.updateFurniture(item.copyWith(rotation: next < 0 ? next + 360 : next));
    } else if (_selectedType == 'stair_floor') {
      final stair = design.stairs.firstWhere((s) => s.id == _selectedId);
      final next = (stair.rotation + degrees) % 360;
      notifier.updateStair(stair.copyWith(rotation: next < 0 ? next + 360 : next));
    } else if (_selectedType == 'door_wall') {
      final door = design.doors.firstWhere((d) => d.id == _selectedId);
      final next = (door.rotation + degrees) % 360;
      notifier.updateDoor(door.copyWith(rotation: next < 0 ? next + 360 : next));
    } else if (_selectedType == 'window_wall') {
      final window = design.windows.firstWhere((w) => w.id == _selectedId);
      final next = (window.rotation + degrees) % 360;
      notifier.updateWindow(window.copyWith(rotation: next < 0 ? next + 360 : next));
    } else if (_selectedType == 'curtain_wall') {
      final curtain = design.curtains.firstWhere((c) => c.id == _selectedId);
      final next = (curtain.rotation + degrees) % 360;
      notifier.updateCurtain(curtain.copyWith(rotation: next < 0 ? next + 360 : next));
    } else if (_selectedType == 'ac_unit_wall') {
      final unit = design.acUnits.firstWhere((a) => a.id == _selectedId);
      final next = (unit.rotation + degrees) % 360;
      notifier.updateAcUnit(unit.copyWith(rotation: next < 0 ? next + 360 : next));
    } else if (_selectedType == 'wall_tv_wall') {
      final unit = design.wallTvUnits.firstWhere((t) => t.id == _selectedId);
      final next = (unit.rotation + degrees) % 360;
      notifier.updateWallTvUnit(unit.copyWith(rotation: next < 0 ? next + 360 : next));
    }
  }

  void _computeFloorPosition({
    required FurnitureItem item,
    required RoomDesign design,
    required Rect roomRect,
    required double defaultBx,
    required double defaultBy,
  }) {
    final center = (_dragStartCenter ?? Offset.zero) + _dragDelta;
    final clamped = BlueprintPlacement.clampBlueprintCenter(
      centerXNorm: (center.dx - roomRect.left) / roomRect.width,
      centerYNorm: (center.dy - roomRect.top) / roomRect.height,
      widthFt: item.width,
      depthFt: item.depth,
      rotationDeg: item.rotation,
      roomWidthFt: design.dimensions.effectiveWidth,
      roomLengthFt: design.dimensions.effectiveLength,
    );
    _tempBlueprintX = _isDragging ? clamped.bx : defaultBx;
    _tempBlueprintY = _isDragging ? clamped.by : defaultBy;
  }

  void _computeStairPosition({
    required StairConfig stair,
    required RoomDesign design,
    required Rect roomRect,
    required double defaultBx,
    required double defaultBy,
  }) {
    final center = (_dragStartCenter ?? Offset.zero) + _dragDelta;
    final clamped = BlueprintPlacement.clampBlueprintCenter(
      centerXNorm: (center.dx - roomRect.left) / roomRect.width,
      centerYNorm: (center.dy - roomRect.top) / roomRect.height,
      widthFt: stair.width,
      depthFt: stair.depth,
      rotationDeg: stair.rotation,
      roomWidthFt: design.dimensions.effectiveWidth,
      roomLengthFt: design.dimensions.effectiveLength,
    );
    _tempBlueprintX = _isDragging ? clamped.bx : defaultBx;
    _tempBlueprintY = _isDragging ? clamped.by : defaultBy;
  }

  Widget _buildStairItem({
    required StairConfig stair,
    required RoomDesign design,
    required Rect roomRect,
    required double scale,
  }) {
    final bx = (_isDragging && _selectedId == stair.id && _tempBlueprintX != null)
        ? _tempBlueprintX!
        : stair.blueprintX;
    final by = (_isDragging && _selectedId == stair.id && _tempBlueprintY != null)
        ? _tempBlueprintY!
        : stair.blueprintY;
    final footprint = BlueprintPlacement.footprintLayout(
      blueprintX: bx,
      blueprintY: by,
      widthFt: stair.width,
      depthFt: stair.depth,
      roomRect: roomRect,
      scale: scale,
    );
    final hit = BlueprintPlacement.layoutPixels(
      blueprintX: bx,
      blueprintY: by,
      widthFt: stair.width,
      depthFt: stair.depth,
      rotationDeg: stair.rotation,
      roomRect: roomRect,
      scale: scale,
    );
    final isSelected = _selectedId == stair.id;
    final isDragging = isSelected && _isDragging;
    final itemCenter = Offset(hit.left + hit.bboxW / 2, hit.top + hit.bboxH / 2);

    return Positioned(
      left: hit.left,
      top: hit.top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => _selectItem(stair.id, 'stair_floor'),
        onPanDown: (_) {
          _holdItemId = stair.id;
          _holdTimer?.cancel();
          _holdTimer = Timer(_holdDuration, () {
            if (_holdItemId != stair.id) return;
            _selectItem(stair.id, 'stair_floor');
            _beginDrag(itemCenter);
          });
        },
        onPanUpdate: (details) {
          if (_selectedId != stair.id || !_isDragging) return;
          setState(() {
            _dragDelta += details.delta;
            _computeStairPosition(
              stair: stair,
              design: design,
              roomRect: roomRect,
              defaultBx: stair.blueprintX,
              defaultBy: stair.blueprintY,
            );
          });
        },
        onPanEnd: (_) {
          _cancelHold();
          if (_selectedId == stair.id && _isDragging) {
            _commitDrag(design, roomRect, scale);
          }
        },
        onPanCancel: () {
          _cancelHold();
          if (_selectedId == stair.id && _isDragging) {
            _commitDrag(design, roomRect, scale);
          }
        },
        child: SizedBox(
          width: hit.bboxW,
          height: hit.bboxH,
          child: Center(
            child: OverflowBox(
              maxWidth: footprint.innerW,
              maxHeight: footprint.innerH,
              minWidth: footprint.innerW,
              minHeight: footprint.innerH,
              alignment: Alignment.center,
              child: Transform.rotate(
                angle: stair.rotation * math.pi / 180,
                child: CustomPaint(
                  size: Size(footprint.innerW, footprint.innerH),
                  painter: _StairSymbolPainter(
                    stair: stair,
                    fillColor: ColorUtils.fromHex(stair.color),
                    selected: isSelected,
                    dragging: isDragging,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloorItem({
    required FurnitureItem item,
    required RoomDesign design,
    required Rect roomRect,
    required double scale,
    required bool premiumFurniture,
    required BlueprintPremiumImages? premiumImages,
  }) {
    final bx = (_isDragging && _selectedId == item.id && _tempBlueprintX != null)
        ? _tempBlueprintX!
        : item.blueprintX;
    final by = (_isDragging && _selectedId == item.id && _tempBlueprintY != null)
        ? _tempBlueprintY!
        : item.blueprintY;
    final footprint = BlueprintPlacement.footprintLayout(
      blueprintX: bx,
      blueprintY: by,
      widthFt: item.width,
      depthFt: item.depth,
      roomRect: roomRect,
      scale: scale,
    );
    final hit = BlueprintPlacement.layoutPixels(
      blueprintX: bx,
      blueprintY: by,
      widthFt: item.width,
      depthFt: item.depth,
      rotationDeg: item.rotation,
      roomRect: roomRect,
      scale: scale,
    );

    return _itemBox(
      id: item.id,
      dragType: 'furniture_floor',
      left: hit.left,
      top: hit.top,
      width: hit.bboxW,
      height: hit.bboxH,
      innerWidth: footprint.innerW,
      innerHeight: footprint.innerH,
      label: FurnitureItem.displayLabel(design.furniture, item),
      color: ColorUtils.fromHex(item.color),
      rotation: item.rotation,
      item: item,
      premiumFurniture: premiumFurniture,
      premiumImages: premiumImages,
      design: design,
      roomRect: roomRect,
      scale: scale,
      onFloorDrag: () {
        _computeFloorPosition(
          item: item,
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
      label: FurnitureItem.displayLabel(design.furniture, item),
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

  Widget _buildDoorItem({
    required DoorConfig door,
    required RoomDesign design,
    required Rect roomRect,
    required double scale,
  }) {
    final edge = (_isDragging && _selectedId == door.id && _tempPositionFromEdge != null)
        ? _tempPositionFromEdge!
        : door.positionFromEdge;
    final hit = _doorHitRect(
      door: door.copyWith(positionFromEdge: edge),
      roomRect: roomRect,
      scale: scale,
    );
    final isSelected = _selectedId == door.id;
    final isDragging = isSelected && _isDragging;
    final itemCenter = hit.center;

    return Positioned(
      left: hit.left,
      top: hit.top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => _selectItem(door.id, 'door_wall'),
        onPanDown: (_) {
          _holdItemId = door.id;
          _holdTimer?.cancel();
          _holdTimer = Timer(_holdDuration, () {
            if (_holdItemId != door.id) return;
            _selectItem(door.id, 'door_wall');
            _beginDrag(itemCenter);
          });
        },
        onPanUpdate: (details) {
          if (_selectedId != door.id || !_isDragging) return;
          setState(() {
            _dragDelta += details.delta;
            _tempPositionFromEdge = _edgeFromCenter(
              wall: door.wall,
              center: (_dragStartCenter ?? itemCenter) + _dragDelta,
              itemWidthFt: door.width,
              roomRect: roomRect,
              scale: scale,
              maxEdge: door.maxPositionFromEdge(design.dimensions),
            );
          });
        },
        onPanEnd: (_) {
          _cancelHold();
          if (_selectedId == door.id && _isDragging) {
            _commitDrag(design, roomRect, scale);
          }
        },
        onPanCancel: () {
          _cancelHold();
          if (_selectedId == door.id && _isDragging) {
            _commitDrag(design, roomRect, scale);
          }
        },
        child: SizedBox(
          width: hit.width,
          height: hit.height,
          child: CustomPaint(
            painter: _DoorSymbolPainter(
              door: door.copyWith(positionFromEdge: edge),
              roomRect: roomRect,
              scale: scale,
              hitRect: hit,
              selected: isSelected,
              dragging: isDragging,
            ),
          ),
        ),
      ),
    );
  }

  Rect _doorHitRect({
    required DoorConfig door,
    required Rect roomRect,
    required double scale,
  }) {
    final dw = door.width * scale;
    final offset = door.positionFromEdge * scale;
    final inward = door.swingDirection == DoorSwingDirection.inward;
    final pad = dw + 8;

    switch (door.wall) {
      case WallId.front:
        final x0 = roomRect.left + offset;
        return Rect.fromLTWH(
          x0 - 4,
          inward ? roomRect.top - 4 : roomRect.top - pad,
          dw + 8,
          inward ? pad : pad,
        );
      case WallId.back:
        final x0 = roomRect.left + offset;
        return Rect.fromLTWH(
          x0 - 4,
          inward ? roomRect.bottom - pad + 4 : roomRect.bottom - 4,
          dw + 8,
          pad,
        );
      case WallId.left:
        final y0 = roomRect.top + offset;
        return Rect.fromLTWH(
          inward ? roomRect.left - 4 : roomRect.left - pad,
          y0 - 4,
          pad,
          dw + 8,
        );
      case WallId.right:
        final y0 = roomRect.top + offset;
        return Rect.fromLTWH(
          inward ? roomRect.right - pad + 4 : roomRect.right - 4,
          y0 - 4,
          pad,
          dw + 8,
        );
    }
  }

  Widget _buildWindowItem({
    required WindowConfig window,
    required RoomDesign design,
    required Rect roomRect,
    required double scale,
  }) {
    final edge = (_isDragging && _selectedId == window.id && _tempPositionFromEdge != null)
        ? _tempPositionFromEdge!
        : window.positionFromEdge;
    final tempWindow = window.copyWith(positionFromEdge: edge);
    final rect = _wallStripRect(
      wall: window.wall,
      positionFromEdge: tempWindow.positionFromEdge,
      widthFt: window.width,
      roomRect: roomRect,
      scale: scale,
    );

    return _itemBox(
      id: window.id,
      dragType: 'window_wall',
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      label: 'Window',
      color: ColorUtils.fromHex(window.glassColor),
      rotation: window.rotation,
      design: design,
      roomRect: roomRect,
      scale: scale,
      onWallDrag: (Offset center) {
        _tempPositionFromEdge = _edgeFromCenter(
          wall: window.wall,
          center: center,
          itemWidthFt: window.width,
          roomRect: roomRect,
          scale: scale,
          maxEdge: window.maxPositionFromEdge(design.dimensions),
        );
      },
    );
  }

  Widget _buildCurtainItem({
    required CurtainConfig curtain,
    required RoomDesign design,
    required Rect roomRect,
    required double scale,
  }) {
    final edge = (_isDragging && _selectedId == curtain.id && _tempPositionFromEdge != null)
        ? _tempPositionFromEdge!
        : curtain.positionFromEdge;
    final rect = _wallStripRect(
      wall: curtain.wall,
      positionFromEdge: edge,
      widthFt: curtain.width,
      roomRect: roomRect,
      scale: scale,
    );

    return _itemBox(
      id: curtain.id,
      dragType: 'curtain_wall',
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      label: 'Curtain',
      color: ColorUtils.fromHex(curtain.color),
      rotation: curtain.rotation,
      design: design,
      roomRect: roomRect,
      scale: scale,
      onWallDrag: (Offset center) {
        _tempPositionFromEdge = _edgeFromCenter(
          wall: curtain.wall,
          center: center,
          itemWidthFt: curtain.width,
          roomRect: roomRect,
          scale: scale,
          maxEdge: curtain.maxPositionFromEdge(design.dimensions),
        );
      },
    );
  }

  Widget _buildAcUnitItem({
    required AcUnitConfig unit,
    required RoomDesign design,
    required Rect roomRect,
    required double scale,
  }) {
    final edge = (_isDragging && _selectedId == unit.id && _tempPositionFromEdge != null)
        ? _tempPositionFromEdge!
        : unit.positionFromEdge;
    final rect = _wallStripRect(
      wall: unit.wall,
      positionFromEdge: edge,
      widthFt: unit.width,
      roomRect: roomRect,
      scale: scale,
    );

    return _itemBox(
      id: unit.id,
      dragType: 'ac_unit_wall',
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      label: 'AC',
      color: ColorUtils.fromHex(unit.color),
      rotation: unit.rotation,
      design: design,
      roomRect: roomRect,
      scale: scale,
      onWallDrag: (Offset center) {
        _tempPositionFromEdge = _edgeFromCenter(
          wall: unit.wall,
          center: center,
          itemWidthFt: unit.width,
          roomRect: roomRect,
          scale: scale,
          maxEdge: unit.maxPositionFromEdge(design.dimensions),
        );
      },
    );
  }


  Widget _buildWallTvUnitItem({
    required WallTvUnitConfig unit,
    required RoomDesign design,
    required Rect roomRect,
    required double scale,
  }) {
    final edge = (_isDragging && _selectedId == unit.id && _tempPositionFromEdge != null)
        ? _tempPositionFromEdge!
        : unit.positionFromEdge;
    final rect = _wallStripRect(
      wall: unit.wall,
      positionFromEdge: edge,
      widthFt: unit.width,
      roomRect: roomRect,
      scale: scale,
    );

    return _itemBox(
      id: unit.id,
      dragType: 'wall_tv_wall',
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      label: WallTvUnitConfig.displayLabel(design.wallTvUnits, unit),
      color: ColorUtils.fromHex(unit.color),
      rotation: unit.rotation,
      design: design,
      roomRect: roomRect,
      scale: scale,
      onWallDrag: (Offset center) {
        _tempPositionFromEdge = _edgeFromCenter(
          wall: unit.wall,
          center: center,
          itemWidthFt: unit.width,
          roomRect: roomRect,
          scale: scale,
          maxEdge: unit.maxPositionFromEdge(design.dimensions),
        );
      },
    );
  }

  Widget _buildSelectionToolbar({
    required RoomDesign design,
    required Rect roomRect,
    required double scale,
  }) {
    if (!_selectionValid(design)) return const SizedBox.shrink();

    final canRotate = _selectedType == 'furniture_floor' ||
        _selectedType == 'stair_floor' ||
        _selectedType == 'door_wall' ||
        _selectedType == 'window_wall' ||
        _selectedType == 'curtain_wall' ||
        _selectedType == 'ac_unit_wall' ||
        _selectedType == 'wall_tv_wall';

    Rect? itemRect;
    if (_selectedType == 'furniture_floor') {
      final item = design.furniture.firstWhere((f) => f.id == _selectedId);
      final bx = _tempBlueprintX ?? item.blueprintX;
      final by = _tempBlueprintY ?? item.blueprintY;
      final hit = BlueprintPlacement.layoutPixels(
        blueprintX: bx,
        blueprintY: by,
        widthFt: item.width,
        depthFt: item.depth,
        rotationDeg: item.rotation,
        roomRect: roomRect,
        scale: scale,
      );
      itemRect = Rect.fromLTWH(hit.left, hit.top, hit.bboxW, hit.bboxH);
    } else if (_selectedType == 'stair_floor') {
      final stair = design.stairs.firstWhere((s) => s.id == _selectedId);
      final bx = _tempBlueprintX ?? stair.blueprintX;
      final by = _tempBlueprintY ?? stair.blueprintY;
      final hit = BlueprintPlacement.layoutPixels(
        blueprintX: bx,
        blueprintY: by,
        widthFt: stair.width,
        depthFt: stair.depth,
        rotationDeg: stair.rotation,
        roomRect: roomRect,
        scale: scale,
      );
      itemRect = Rect.fromLTWH(hit.left, hit.top, hit.bboxW, hit.bboxH);
    } else if (_selectedType == 'furniture_wall') {
      final item = design.furniture.firstWhere((f) => f.id == _selectedId);
      itemRect = _wallItemRect(item, roomRect, scale);
    } else if (_selectedType == 'door_wall') {
      final door = design.doors.firstWhere((d) => d.id == _selectedId);
      final edge = _tempPositionFromEdge ?? door.positionFromEdge;
      itemRect = _doorHitRect(
        door: door.copyWith(positionFromEdge: edge),
        roomRect: roomRect,
        scale: scale,
      );
    } else if (_selectedType == 'window_wall') {
      final window = design.windows.firstWhere((w) => w.id == _selectedId);
      final edge = _tempPositionFromEdge ?? window.positionFromEdge;
      itemRect = _wallStripRect(
        wall: window.wall,
        positionFromEdge: edge,
        widthFt: window.width,
        roomRect: roomRect,
        scale: scale,
      );
    } else if (_selectedType == 'curtain_wall') {
      final curtain = design.curtains.firstWhere((c) => c.id == _selectedId);
      final edge = _tempPositionFromEdge ?? curtain.positionFromEdge;
      itemRect = _wallStripRect(
        wall: curtain.wall,
        positionFromEdge: edge,
        widthFt: curtain.width,
        roomRect: roomRect,
        scale: scale,
      );
    } else if (_selectedType == 'ac_unit_wall') {
      final unit = design.acUnits.firstWhere((a) => a.id == _selectedId);
      final edge = _tempPositionFromEdge ?? unit.positionFromEdge;
      itemRect = _wallStripRect(
        wall: unit.wall,
        positionFromEdge: edge,
        widthFt: unit.width,
        roomRect: roomRect,
        scale: scale,
      );
    } else if (_selectedType == 'wall_tv_wall') {
      final unit = design.wallTvUnits.firstWhere((t) => t.id == _selectedId);
      final edge = _tempPositionFromEdge ?? unit.positionFromEdge;
      itemRect = _wallStripRect(
        wall: unit.wall,
        positionFromEdge: edge,
        widthFt: unit.width,
        roomRect: roomRect,
        scale: scale,
      );
    }

    if (itemRect == null) return const SizedBox.shrink();

    return Positioned(
      left: itemRect.center.dx - 88,
      top: itemRect.top - 44,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.primary,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedType == 'door_wall') ...[
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.swap_vert, color: Colors.white, size: 18),
                  tooltip: 'Flip open direction',
                  onPressed: () => _flipDoorSwing(design),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.flip, color: Colors.white, size: 18),
                  tooltip: 'Flip hinge side',
                  onPressed: () => _flipDoorHinge(design),
                ),
              ],
              if (canRotate) ...[
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.rotate_left, color: Colors.white, size: 18),
                  tooltip: 'Rotate left',
                  onPressed: () => _rotateSelected(design, -15),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.rotate_right, color: Colors.white, size: 18),
                  tooltip: 'Rotate right',
                  onPressed: () => _rotateSelected(design, 15),
                ),
              ],
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                tooltip: 'Delete',
                onPressed: () => _deleteSelected(design),
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

  double _edgeFromCenter({
    required WallId wall,
    required Offset center,
    required double itemWidthFt,
    required Rect roomRect,
    required double scale,
    required double maxEdge,
  }) {
    final edgePos = switch (wall) {
      WallId.front || WallId.back => (center.dx - roomRect.left) / scale - itemWidthFt / 2,
      WallId.left || WallId.right => (center.dy - roomRect.top) / scale - itemWidthFt / 2,
    };
    return edgePos.clamp(0, maxEdge).toDouble();
  }

  Rect _wallStripRect({
    required WallId wall,
    required double positionFromEdge,
    required double widthFt,
    required Rect roomRect,
    required double scale,
  }) {
    const visualDepth = 14.0;
    final along = positionFromEdge * scale;
    final alongSize = widthFt * scale;

    return switch (wall) {
      WallId.front => Rect.fromLTWH(
          roomRect.left + along,
          roomRect.top - visualDepth / 2,
          alongSize,
          visualDepth,
        ),
      WallId.back => Rect.fromLTWH(
          roomRect.left + along,
          roomRect.bottom - visualDepth / 2,
          alongSize,
          visualDepth,
        ),
      WallId.left => Rect.fromLTWH(
          roomRect.left - visualDepth / 2,
          roomRect.top + along,
          visualDepth,
          alongSize,
        ),
      WallId.right => Rect.fromLTWH(
          roomRect.right - visualDepth / 2,
          roomRect.top + along,
          visualDepth,
          alongSize,
        ),
    };
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
    FurnitureItem? item,
    bool premiumFurniture = false,
    BlueprintPremiumImages? premiumImages,
    required RoomDesign design,
    required Rect roomRect,
    required double scale,
    double? innerWidth,
    double? innerHeight,
    VoidCallback? onFloorDrag,
    void Function(Offset center)? onWallDrag,
  }) {
    final isSelected = _selectedId == id;
    final isDragging = isSelected && _isDragging;
    final innerW = innerWidth ?? width;
    final innerH = innerHeight ?? height;
    final premiumImage = item != null ? premiumImages?.forItem(item) : null;
    final showPremiumSprite = premiumFurniture && premiumImage != null;

    final itemCenter = Offset(left + width / 2, top + height / 2);

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
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
        child: SizedBox(
          width: width,
          height: height,
          child: Center(
            // Bbox is smaller than width×depth at diagonal angles; OverflowBox keeps
            // the visual footprint at true dimensions so rotation matches 3D.
            child: OverflowBox(
              maxWidth: innerW,
              maxHeight: innerH,
              minWidth: innerW,
              minHeight: innerH,
              alignment: Alignment.center,
              child: Transform.rotate(
                angle: rotation * math.pi / 180,
                child: showPremiumSprite
                    ? _PremiumFurnitureBlueprintTile(
                        width: innerW,
                        height: innerH,
                        image: premiumImage,
                        isSelected: isSelected,
                        isDragging: isDragging,
                      )
                    : AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        width: innerW,
                        height: innerH,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isDragging ? 0.9 : 0.75),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : Colors.black54,
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
          ),
        ),
      ),
    );
  }
}

class _PremiumFurnitureBlueprintTile extends StatelessWidget {
  const _PremiumFurnitureBlueprintTile({
    required this.width,
    required this.height,
    required this.image,
    required this.isSelected,
    required this.isDragging,
  });

  final double width;
  final double height;
  final ui.Image image;
  final bool isSelected;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE6DC),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSelected ? AppTheme.primary : Colors.black54,
          width: isSelected ? 2.5 : 1,
        ),
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
      clipBehavior: Clip.antiAlias,
      child: RawImage(
        image: image,
        width: width,
        height: height,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _DoorSymbolPainter extends CustomPainter {
  _DoorSymbolPainter({
    required this.door,
    required this.roomRect,
    required this.scale,
    required this.hitRect,
    required this.selected,
    required this.dragging,
  });

  final DoorConfig door;
  final Rect roomRect;
  final double scale;
  final Rect hitRect;
  final bool selected;
  final bool dragging;

  @override
  void paint(Canvas canvas, Size size) {
    BlueprintDoorPaint.draw(
      canvas: canvas,
      roomRect: roomRect.shift(Offset(-hitRect.left, -hitRect.top)),
      scale: scale,
      door: door,
      fillColor: ColorUtils.fromHex(door.color),
      strokeColor: selected ? AppTheme.primary : ColorUtils.fromHex(door.color),
      selected: selected || dragging,
    );
  }

  @override
  bool shouldRepaint(covariant _DoorSymbolPainter oldDelegate) =>
      oldDelegate.door != door ||
      oldDelegate.selected != selected ||
      oldDelegate.dragging != dragging ||
      oldDelegate.hitRect != hitRect;
}

class _StairSymbolPainter extends CustomPainter {
  _StairSymbolPainter({
    required this.stair,
    required this.fillColor,
    required this.selected,
    required this.dragging,
  });

  final StairConfig stair;
  final Color fillColor;
  final bool selected;
  final bool dragging;

  @override
  void paint(Canvas canvas, Size size) {
    BlueprintStairPaint.draw(
      canvas: canvas,
      rect: Offset.zero & size,
      stair: stair,
      fillColor: fillColor.withValues(alpha: dragging ? 0.55 : 0.42),
      lineColor: selected ? AppTheme.primary : const Color(0xFF263238),
    );
    if (selected) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = AppTheme.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StairSymbolPainter oldDelegate) =>
      oldDelegate.stair != stair ||
      oldDelegate.selected != selected ||
      oldDelegate.dragging != dragging ||
      oldDelegate.fillColor != fillColor;
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
    BlueprintWallBorderPaint.drawRoomBorder(
      canvas,
      roomRect: roomRect,
      design: design,
      scale: scale,
      paint: borderPaint,
    );

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

    _drawDimensions(canvas);
    _drawWallLabels(canvas);
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
