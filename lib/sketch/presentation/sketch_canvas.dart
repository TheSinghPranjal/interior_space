import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sketch_image_storage.dart';
import '../domain/sketch_models.dart';
import '../domain/sketch_tool.dart';
import '../engine/sketch_renderer.dart';
import '../providers/sketch_controller.dart';
import 'sketch_blueprint_layer.dart';

class SketchCanvas extends ConsumerStatefulWidget {
  const SketchCanvas({super.key, required this.isApartment});

  final bool isApartment;

  @override
  ConsumerState<SketchCanvas> createState() => _SketchCanvasState();
}

class _SketchCanvasState extends ConsumerState<SketchCanvas> {
  static const _renderer = SketchRenderer();

  final TransformationController _transformController = TransformationController();
  List<SketchPoint> _previewStroke = [];
  Offset? _shapeStart;
  Offset? _shapeEnd;

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
      ..translate(doc.panX, doc.panY)
      ..scale(doc.zoom);
  }

  void _syncViewport() {
    final m = _transformController.value;
    final zoom = m.getMaxScaleOnAxis();
    final panX = m.getTranslation().x;
    final panY = m.getTranslation().y;
    ref.read(sketchControllerProvider.notifier).setViewport(
          zoom: zoom,
          panX: panX,
          panY: panY,
        );
  }

  Offset _normalize(Offset local, Size size) {
    final scene = _transformController.toScene(local);
    return Offset(
      (scene.dx / size.width).clamp(0.0, 1.0),
      (scene.dy / size.height).clamp(0.0, 1.0),
    );
  }

  Offset _scenePoint(Offset local) => _transformController.toScene(local);

  bool get _drawMode {
    final tool = ref.read(sketchControllerProvider).toolSettings.activeTool;
    return tool == SketchTool.pen ||
        tool == SketchTool.highlighter ||
        tool == SketchTool.eraser ||
        tool == SketchTool.shapes ||
        tool == SketchTool.text;
  }

  @override
  Widget build(BuildContext context) {
    final doc = ref.watch(sketchControllerProvider);
    final tool = doc.toolSettings.activeTool;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        SketchShape? previewShape;
        if (_shapeStart != null && _shapeEnd != null) {
          final start = _normalize(_shapeStart!, size);
          final end = _normalize(_shapeEnd!, size);
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
          minScale: 0.4,
          maxScale: 6,
          panEnabled: !_drawMode,
          scaleEnabled: true,
          boundaryMargin: const EdgeInsets.all(200),
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (e) => _onPointerDown(e, size),
            onPointerMove: (e) => _onPointerMove(e, size),
            onPointerUp: (e) => _onPointerUp(e, size),
            child: Stack(
              fit: StackFit.expand,
              children: [
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
                ...doc.images.where((i) => i.visible).map((img) {
                  return _SketchImageOverlay(annotation: img, canvasSize: size);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onPointerDown(PointerDownEvent e, Size size) {
    final controller = ref.read(sketchControllerProvider.notifier);
    final tool = ref.read(sketchControllerProvider).toolSettings.activeTool;
    final local = _scenePoint(e.localPosition);

    switch (tool) {
      case SketchTool.pen:
      case SketchTool.highlighter:
        setState(() {
          _previewStroke = [SketchPoint(local.dx / size.width, local.dy / size.height)];
        });
        controller.beginStroke(_normalize(e.localPosition, size));
      case SketchTool.eraser:
        controller.eraseAt(local, size);
      case SketchTool.shapes:
        setState(() {
          _shapeStart = e.localPosition;
          _shapeEnd = e.localPosition;
        });
      case SketchTool.text:
        _promptText(context, _normalize(e.localPosition, size));
      case SketchTool.select:
        controller.selectAt(local, size);
      case SketchTool.rotate:
      case SketchTool.crop:
      case SketchTool.image:
        break;
    }
  }

  void _onPointerMove(PointerMoveEvent e, Size size) {
    final controller = ref.read(sketchControllerProvider.notifier);
    final tool = ref.read(sketchControllerProvider).toolSettings.activeTool;

    switch (tool) {
      case SketchTool.pen:
      case SketchTool.highlighter:
        setState(() {
          final norm = _normalize(e.localPosition, size);
          _previewStroke = [..._previewStroke, SketchPoint(norm.dx, norm.dy)];
        });
        controller.extendStroke(_normalize(e.localPosition, size));
      case SketchTool.eraser:
        controller.eraseAt(_scenePoint(e.localPosition), size);
      case SketchTool.shapes:
        setState(() => _shapeEnd = e.localPosition);
      default:
        break;
    }
  }

  void _onPointerUp(PointerUpEvent e, Size size) {
    final controller = ref.read(sketchControllerProvider.notifier);
    final tool = ref.read(sketchControllerProvider).toolSettings.activeTool;

    if (tool == SketchTool.pen || tool == SketchTool.highlighter) {
      setState(() => _previewStroke = []);
      controller.finalizeStroke();
    }
    if (tool == SketchTool.shapes && _shapeStart != null && _shapeEnd != null) {
      controller.addShapeFromDrag(
        _normalize(_shapeStart!, size),
        _normalize(_shapeEnd!, size),
      );
      setState(() {
        _shapeStart = null;
        _shapeEnd = null;
      });
    }
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

class _SketchImageOverlay extends StatelessWidget {
  const _SketchImageOverlay({
    required this.annotation,
    required this.canvasSize,
  });

  final SketchImageAnnotation annotation;
  final Size canvasSize;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: annotation.x * canvasSize.width,
      top: annotation.y * canvasSize.height,
      width: annotation.width * canvasSize.width,
      height: annotation.height * canvasSize.height,
      child: Transform.rotate(
        angle: annotation.rotation,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(annotation.flipX ? -1.0 : 1.0, 1.0),
          child: Opacity(
            opacity: annotation.opacity,
            child: FutureBuilder<File?>(
              future: SketchImageStorage.resolveFile(annotation.storagePath),
              builder: (context, snapshot) {
                final file = snapshot.data;
                if (file == null) return const SizedBox.shrink();
                return Image.file(file, fit: BoxFit.contain);
              },
            ),
          ),
        ),
      ),
    );
  }
}
