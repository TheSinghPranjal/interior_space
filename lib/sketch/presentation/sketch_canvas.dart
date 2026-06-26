import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../data/sketch_image_storage.dart';
import '../domain/sketch_models.dart';
import '../domain/sketch_tool.dart';
import '../engine/sketch_renderer.dart';
import '../providers/sketch_controller.dart';
import 'sketch_blueprint_layer.dart';

/// Fixed 4:3 artboard aspect ratio for consistent drawing coordinates.
const _artboardAspect = 4 / 3;

class SketchCanvas extends ConsumerStatefulWidget {
  const SketchCanvas({super.key, required this.isApartment});

  final bool isApartment;

  @override
  ConsumerState<SketchCanvas> createState() => _SketchCanvasState();
}

class _SketchCanvasState extends ConsumerState<SketchCanvas> {
  static const _renderer = SketchRenderer();

  final TransformationController _transformController = TransformationController();
  final Set<int> _activePointers = {};
  List<SketchPoint> _previewStroke = [];
  Offset? _shapeStart;
  Offset? _shapeEnd;
  bool _multiTouch = false;
  bool _strokeInProgress = false;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_syncViewport);
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreTransform());
  }

  @override
  void dispose() {
    _transformController.removeListener(_syncViewport);
    _transformController.dispose();
    super.dispose();
  }

  void _restoreTransform() {
    final doc = ref.read(sketchControllerProvider);
    _transformController.value = Matrix4.identity()
      ..translateByDouble(doc.panX, doc.panY, 0, 1)
      ..scaleByDouble(doc.zoom, doc.zoom, 1, 1);
  }

  void _syncViewport() {
    final m = _transformController.value;
    ref.read(sketchControllerProvider.notifier).setViewport(
          zoom: m.getMaxScaleOnAxis(),
          panX: m.getTranslation().x,
          panY: m.getTranslation().y,
        );
  }

  Size _artboardSize(BoxConstraints constraints) {
    const margin = 28.0;
    var w = constraints.maxWidth - margin * 2;
    var h = constraints.maxHeight - margin * 2;
    if (w / h > _artboardAspect) {
      w = h * _artboardAspect;
    } else {
      h = w / _artboardAspect;
    }
    return Size(w.clamp(280, constraints.maxWidth), h.clamp(210, constraints.maxHeight));
  }

  Offset _normalize(Offset local, Size artboardSize) {
    return Offset(
      (local.dx / artboardSize.width).clamp(0.0, 1.0),
      (local.dy / artboardSize.height).clamp(0.0, 1.0),
    );
  }

  bool get _drawMode {
    final tool = ref.read(sketchControllerProvider).toolSettings.activeTool;
    return tool == SketchTool.pen ||
        tool == SketchTool.highlighter ||
        tool == SketchTool.eraser ||
        tool == SketchTool.shapes ||
        tool == SketchTool.text;
  }

  bool get _canDraw => !_multiTouch && _activePointers.length <= 1;

  void _cancelDrawing() {
    if (_strokeInProgress) {
      ref.read(sketchControllerProvider.notifier).cancelActiveStroke();
      _strokeInProgress = false;
    }
    setState(() {
      _previewStroke = [];
      _shapeStart = null;
      _shapeEnd = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final doc = ref.watch(sketchControllerProvider);
    final tool = doc.toolSettings.activeTool;

    return LayoutBuilder(
      builder: (context, constraints) {
        final artboardSize = _artboardSize(constraints);

        SketchShape? previewShape;
        if (_shapeStart != null && _shapeEnd != null) {
          final start = _normalize(_shapeStart!, artboardSize);
          final end = _normalize(_shapeEnd!, artboardSize);
          previewShape = SketchShape(
            id: 'preview',
            kind: doc.toolSettings.shapeKind,
            x: start.dx < end.dx ? start.dx : end.dx,
            y: start.dy < end.dy ? start.dy : end.dy,
            width: (start.dx - end.dx).abs().clamp(0.02, 1),
            height: (start.dy - end.dy).abs().clamp(0.02, 1),
            strokeColorArgb: doc.toolSettings.strokeColorArgb,
            fillColorArgb: doc.toolSettings.fillColorArgb,
          );
        }

        return InteractiveViewer(
          transformationController: _transformController,
          minScale: 0.5,
          maxScale: 5,
          panEnabled: !_drawMode || _multiTouch,
          scaleEnabled: true,
          boundaryMargin: const EdgeInsets.all(80),
          clipBehavior: Clip.none,
          child: Center(
            child: SizedBox(
              width: artboardSize.width,
              height: artboardSize.height,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) => _onPointerDown(e, artboardSize),
                onPointerMove: (e) => _onPointerMove(e, artboardSize),
                onPointerUp: (e) => _onPointerUp(e, artboardSize),
                onPointerCancel: (e) => _onPointerCancel(e),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.border, width: 2),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: Colors.blue.shade50.withValues(alpha: 0.35)),
                        widget.isApartment
                            ? const SketchApartmentBlueprintLayer()
                            : const SketchRoomBlueprintLayer(),
                        CustomPaint(
                          painter: _SketchAnnotationPainter(
                            doc: doc,
                            renderer: _renderer,
                            previewStroke: _previewStroke,
                            previewShape: previewShape,
                            previewHighlighter: tool == SketchTool.highlighter,
                            previewWidth: doc.toolSettings.brushSize.width,
                            previewColorArgb: tool == SketchTool.highlighter
                                ? doc.toolSettings.highlighterColorArgb
                                : doc.toolSettings.penColorArgb,
                          ),
                        ),
                        ...doc.images.where((i) => i.visible).map(
                              (img) => _SketchImageOverlay(
                                annotation: img,
                                canvasSize: artboardSize,
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onPointerDown(PointerDownEvent e, Size artboardSize) {
    _activePointers.add(e.pointer);
    if (_activePointers.length > 1) {
      _multiTouch = true;
      _cancelDrawing();
      return;
    }

    final controller = ref.read(sketchControllerProvider.notifier);
    final tool = ref.read(sketchControllerProvider).toolSettings.activeTool;
    final norm = _normalize(e.localPosition, artboardSize);
    final local = e.localPosition;

    switch (tool) {
      case SketchTool.pen:
      case SketchTool.highlighter:
        _strokeInProgress = true;
        setState(() {
          _previewStroke = [SketchPoint(norm.dx, norm.dy)];
        });
        controller.beginStroke(norm);
      case SketchTool.eraser:
        controller.eraseAt(local, artboardSize);
      case SketchTool.shapes:
        setState(() {
          _shapeStart = local;
          _shapeEnd = local;
        });
      case SketchTool.text:
        _promptText(context, norm);
      case SketchTool.select:
        controller.selectAt(local, artboardSize);
      case SketchTool.image:
        controller.selectAt(local, artboardSize);
      case SketchTool.rotate:
      case SketchTool.crop:
        break;
    }
  }

  void _onPointerMove(PointerMoveEvent e, Size artboardSize) {
    if (!_canDraw) return;

    final controller = ref.read(sketchControllerProvider.notifier);
    final tool = ref.read(sketchControllerProvider).toolSettings.activeTool;
    final norm = _normalize(e.localPosition, artboardSize);
    final local = e.localPosition;

    switch (tool) {
      case SketchTool.pen:
      case SketchTool.highlighter:
        setState(() {
          _previewStroke = [..._previewStroke, SketchPoint(norm.dx, norm.dy)];
        });
        controller.extendStroke(norm);
      case SketchTool.eraser:
        controller.eraseAt(local, artboardSize);
      case SketchTool.shapes:
        setState(() => _shapeEnd = local);
      default:
        break;
    }
  }

  void _onPointerUp(PointerUpEvent e, Size artboardSize) {
    _activePointers.remove(e.pointer);
    if (_activePointers.isEmpty) {
      _multiTouch = false;
    }
    if (!_canDraw && _activePointers.isNotEmpty) return;

    final controller = ref.read(sketchControllerProvider.notifier);
    final tool = ref.read(sketchControllerProvider).toolSettings.activeTool;

    if (tool == SketchTool.pen || tool == SketchTool.highlighter) {
      setState(() => _previewStroke = []);
      if (_strokeInProgress) {
        controller.finalizeStroke();
        _strokeInProgress = false;
      }
    }
    if (tool == SketchTool.shapes && _shapeStart != null && _shapeEnd != null) {
      controller.addShapeFromDrag(
        _normalize(_shapeStart!, artboardSize),
        _normalize(_shapeEnd!, artboardSize),
      );
      setState(() {
        _shapeStart = null;
        _shapeEnd = null;
      });
    }
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _activePointers.remove(e.pointer);
    if (_activePointers.isEmpty) _multiTouch = false;
    _cancelDrawing();
  }

  Future<void> _promptText(BuildContext context, Offset normalized) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add text'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Apartment notes, pricing, facing…'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (text != null && mounted) {
      ref.read(sketchControllerProvider.notifier).addTextAt(normalized, text);
    }
  }
}

class _SketchAnnotationPainter extends CustomPainter {
  _SketchAnnotationPainter({
    required this.doc,
    required this.renderer,
    this.previewStroke = const [],
    this.previewShape,
    this.previewHighlighter = false,
    this.previewWidth = 3,
    this.previewColorArgb = 0xFF000000,
  });

  final SketchDocument doc;
  final SketchRenderer renderer;
  final List<SketchPoint> previewStroke;
  final SketchShape? previewShape;
  final bool previewHighlighter;
  final double previewWidth;
  final int previewColorArgb;

  @override
  void paint(Canvas canvas, Size size) {
    renderer.paint(
      canvas,
      size,
      doc.copyWith(zoom: 1, panX: 0, panY: 0),
      previewStroke: previewStroke.isEmpty ? null : previewStroke,
      previewHighlighter: previewHighlighter,
      previewWidth: previewWidth,
      previewColorArgb: previewColorArgb,
      previewShape: previewShape,
    );
  }

  @override
  bool shouldRepaint(covariant _SketchAnnotationPainter oldDelegate) =>
      oldDelegate.doc != doc ||
      oldDelegate.previewStroke != previewStroke ||
      oldDelegate.previewShape != previewShape;
}

class _SketchImageOverlay extends ConsumerWidget {
  const _SketchImageOverlay({
    required this.annotation,
    required this.canvasSize,
  });

  final SketchImageAnnotation annotation;
  final Size canvasSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doc = ref.watch(sketchControllerProvider);
    final current = doc.images.firstWhere(
      (i) => i.id == annotation.id,
      orElse: () => annotation,
    );
    final isSelected = doc.selectedObjectId == current.id;
    final left = current.x * canvasSize.width;
    final top = current.y * canvasSize.height;
    final width = current.width * canvasSize.width;
    final height = current.height * canvasSize.height;
    final notifier = ref.read(sketchControllerProvider.notifier);

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: current.rotation,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scaleByDouble(current.flipX ? -1.0 : 1.0, 1.0, 1.0, 1.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => notifier.selectObject(current.id),
                onPanUpdate: isSelected
                    ? (details) {
                        notifier.updateImage(
                          current.id,
                          x: (current.x + details.delta.dx / canvasSize.width)
                              .clamp(0.0, 1.0 - current.width),
                          y: (current.y + details.delta.dy / canvasSize.height)
                              .clamp(0.0, 1.0 - current.height),
                        );
                      }
                    : null,
                child: Opacity(
                  opacity: current.opacity,
                  child: FutureBuilder<File?>(
                    future: SketchImageStorage.resolveFile(current.storagePath),
                    builder: (context, snapshot) {
                      final file = snapshot.data;
                      if (file == null) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.image_outlined, color: Colors.grey),
                          ),
                        );
                      }
                      return Image.file(file, fit: BoxFit.contain);
                    },
                  ),
                ),
              ),
              if (isSelected) ...[
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.accent, width: 2),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: _ResizeHandle(
                    onDrag: (delta) {
                      notifier.updateImage(
                        current.id,
                        width: (current.width + delta.dx / canvasSize.width)
                            .clamp(0.05, 1.0 - current.x),
                        height: (current.height + delta.dy / canvasSize.height)
                            .clamp(0.05, 1.0 - current.y),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({required this.onDrag});

  final ValueChanged<Offset> onDrag;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (d) => onDrag(d.delta),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppTheme.accent,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
            ),
          ],
        ),
        child: const Icon(Icons.open_in_full, size: 12, color: Colors.white),
      ),
    );
  }
}
