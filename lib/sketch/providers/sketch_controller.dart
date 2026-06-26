import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../providers/app_mode_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/room_design_provider.dart';
import '../domain/sketch_models.dart';
import '../domain/sketch_tool.dart';
import '../engine/sketch_hit_tester.dart';
import '../engine/sketch_undo_manager.dart';

final sketchControllerProvider =
    StateNotifierProvider<SketchController, SketchDocument>((ref) {
  return SketchController(ref);
});

class SketchController extends StateNotifier<SketchDocument> {
  SketchController(this._ref) : super(const SketchDocument()) {
    _reloadForScope();
    _ref.listen(appSpaceModeProvider, (_, __) => _reloadForScope());
    _ref.listen(projectProvider, (_, __) => _reloadForScope());
  }

  final Ref _ref;
  final SketchUndoManager _undo = SketchUndoManager();
  final _uuid = const Uuid();
  String? _scopeKey;

  bool get canUndo => _undo.canUndo;
  bool get canRedo => _undo.canRedo;

  bool get _isApartment =>
      _ref.read(appSpaceModeProvider) == AppSpaceMode.apartment;

  String _scopeKeyForCurrent() {
    if (_isApartment) {
      return 'apt_${_ref.read(projectProvider).safeActiveApartmentIndex}';
    }
    return 'room_${_ref.read(roomDesignProvider).id}';
  }

  SketchDocument _loadFromProject() {
    if (_isApartment) {
      return _ref.read(projectProvider).apartmentLayout.sketch;
    }
    return _ref.read(roomDesignProvider).sketch;
  }

  void _reloadForScope() {
    final key = _scopeKeyForCurrent();
    if (key == _scopeKey) return;
    _scopeKey = key;
    _undo.reset();
    state = _loadFromProject();
  }

  void _commit(SketchDocument next, {bool recordUndo = true}) {
    if (recordUndo) {
      _undo.push(state);
    }
    state = next;
    _persist();
  }

  void _persist() {
    if (_isApartment) {
      _ref.read(projectProvider.notifier).updateApartmentSketch(state);
    } else {
      _ref.read(roomDesignProvider.notifier).updateSketch(state);
    }
  }

  void setTool(SketchTool tool) {
    _commit(
      state.copyWith(
        toolSettings: state.toolSettings.copyWith(activeTool: tool),
        clearSelection: true,
      ),
      recordUndo: false,
    );
  }

  void setBrushSize(SketchBrushSize size) {
    _commit(
      state.copyWith(toolSettings: state.toolSettings.copyWith(brushSize: size)),
      recordUndo: false,
    );
  }

  void setPenColor(int argb) {
    _commit(
      state.copyWith(toolSettings: state.toolSettings.copyWith(penColorArgb: argb)),
      recordUndo: false,
    );
  }

  void setHighlighterColor(int argb) {
    _commit(
      state.copyWith(
        toolSettings: state.toolSettings.copyWith(highlighterColorArgb: argb),
      ),
      recordUndo: false,
    );
  }

  void setShapeKind(SketchShapeKind kind) {
    _commit(
      state.copyWith(toolSettings: state.toolSettings.copyWith(shapeKind: kind)),
      recordUndo: false,
    );
  }

  void setEraserMode(EraserMode mode) {
    _commit(
      state.copyWith(toolSettings: state.toolSettings.copyWith(eraserMode: mode)),
      recordUndo: false,
    );
  }

  void setEraserSize(double size) {
    _commit(
      state.copyWith(toolSettings: state.toolSettings.copyWith(eraserSize: size)),
      recordUndo: false,
    );
  }

  void setIncludeInPdf(bool value) {
    _commit(state.copyWith(includeInPdfExport: value), recordUndo: false);
  }

  void setViewport({double? zoom, double? panX, double? panY}) {
    _commit(
      state.copyWith(zoom: zoom, panX: panX, panY: panY),
      recordUndo: false,
    );
  }

  void resetViewport() {
    _commit(state.copyWith(zoom: 1, panX: 0, panY: 0), recordUndo: false);
  }

  void beginStroke(Offset normalized) {
    final settings = state.toolSettings;
    final isHighlighter = settings.activeTool == SketchTool.highlighter;
    final stroke = SketchStroke(
      id: _uuid.v4(),
      points: [SketchPoint(normalized.dx, normalized.dy)],
      colorArgb: isHighlighter ? settings.highlighterColorArgb : settings.penColorArgb,
      width: settings.brushSize.width,
      isHighlighter: isHighlighter,
    );
    _commit(state.copyWith(strokes: [...state.strokes, stroke]));
  }

  void extendStroke(Offset normalized) {
    if (state.strokes.isEmpty) return;
    final last = state.strokes.last;
    if (last.points.isNotEmpty) {
      final prev = last.points.last;
      final dx = normalized.dx - prev.x;
      final dy = normalized.dy - prev.y;
      if ((dx * dx + dy * dy) < 1e-6) return;
    }
    final points = [...last.points, SketchPoint(normalized.dx, normalized.dy)];
    final strokes = [...state.strokes];
    strokes[strokes.length - 1] = last.copyWith(points: points);
    state = state.copyWith(strokes: strokes);
  }

  void finalizeStroke() => _persist();

  void eraseAt(Offset local, Size canvasSize) {
    final settings = state.toolSettings;
    if (settings.eraserMode == EraserMode.object) {
      final id = SketchHitTester.hitTest(state, local, canvasSize);
      if (id == null) return;
      _eraseObjectById(id);
      return;
    }

    final radius = settings.eraserSize;
    final remaining = state.strokes.where((stroke) {
      return !stroke.points.any(
        (p) => (p.toOffset(canvasSize) - local).distance < radius,
      );
    }).toList();
    if (remaining.length == state.strokes.length) return;
    _commit(state.copyWith(strokes: remaining));
  }

  void _eraseObjectById(String id) {
    _commit(
      state.copyWith(
        strokes: state.strokes.where((s) => s.id != id).toList(),
        shapes: state.shapes.where((s) => s.id != id).toList(),
        texts: state.texts.where((t) => t.id != id).toList(),
        images: state.images.where((i) => i.id != id).toList(),
        clearSelection: true,
      ),
    );
  }

  void addShapeFromDrag(Offset start, Offset end) {
    final x = math.min(start.dx, end.dx);
    final y = math.min(start.dy, end.dy);
    final w = (start.dx - end.dx).abs().clamp(0.02, 1.0);
    final h = (start.dy - end.dy).abs().clamp(0.02, 1.0);
    final settings = state.toolSettings;
    final shape = SketchShape(
      id: _uuid.v4(),
      kind: settings.shapeKind,
      x: x,
      y: y,
      width: w,
      height: h,
      strokeColorArgb: settings.strokeColorArgb,
      fillColorArgb: settings.fillColorArgb,
    );
    _commit(state.copyWith(shapes: [...state.shapes, shape]));
  }

  void addTextAt(Offset normalized, String text) {
    if (text.trim().isEmpty) return;
    final settings = state.toolSettings;
    final annotation = SketchTextAnnotation(
      id: _uuid.v4(),
      x: normalized.dx,
      y: normalized.dy,
      text: text.trim(),
      fontSize: settings.textFontSize,
      colorArgb: settings.textColorArgb,
    );
    _commit(state.copyWith(texts: [...state.texts, annotation]));
  }

  void addImage(String storagePath) {
    final image = SketchImageAnnotation(
      id: _uuid.v4(),
      x: 0.3,
      y: 0.3,
      width: 0.25,
      height: 0.2,
      storagePath: storagePath,
    );
    _commit(
      state.copyWith(
        images: [...state.images, image],
        selectedObjectId: image.id,
        toolSettings: state.toolSettings.copyWith(activeTool: SketchTool.select),
      ),
    );
  }

  void updateImage(
    String id, {
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
  }) {
    final images = state.images.map((img) {
      if (img.id != id) return img;
      return img.copyWith(
        x: x ?? img.x,
        y: y ?? img.y,
        width: width ?? img.width,
        height: height ?? img.height,
        rotation: rotation ?? img.rotation,
      );
    }).toList();
    state = state.copyWith(images: images);
    _persist();
  }

  void selectObject(String? id) {
    _commit(
      state.copyWith(selectedObjectId: id, clearSelection: id == null),
      recordUndo: false,
    );
  }

  /// Removes the in-progress stroke when pinch/multi-touch interrupts drawing.
  void cancelActiveStroke() {
    if (state.strokes.isEmpty) return;
    final strokes = [...state.strokes]..removeLast();
    state = state.copyWith(strokes: strokes);
  }

  void selectAt(Offset local, Size canvasSize) {
    final id = SketchHitTester.hitTest(state, local, canvasSize);
    _commit(
      state.copyWith(selectedObjectId: id, clearSelection: id == null),
      recordUndo: false,
    );
  }

  void rotateBlueprintBy(double radians) {
    final t = state.blueprintTransform;
    _commit(
      state.copyWith(
        blueprintTransform: t.copyWith(rotation: t.rotation + radians),
      ),
    );
  }

  void rotateBlueprint90() => rotateBlueprintBy(1.5707963267948966);

  void resetBlueprintTransform() {
    _commit(state.copyWith(blueprintTransform: const SketchBlueprintTransform()));
  }

  void resetSketch() {
    _commit(const SketchDocument());
  }

  void undo() {
    final prev = _undo.undo(state);
    if (prev == null) return;
    state = prev;
    _persist();
  }

  void redo() {
    final next = _undo.redo(state);
    if (next == null) return;
    state = next;
    _persist();
  }
}
