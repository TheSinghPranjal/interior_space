import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/utils/blueprint_placement.dart';
import '../../widgets/blueprint/room_blueprint_layout_painter.dart';
import '../../models/apartment_layout.dart';
import '../../models/project_design.dart';
import '../../models/room_design.dart';
import '../../services/blueprint_image_exporter.dart';
import '../domain/sketch_models.dart';
import '../engine/sketch_renderer.dart';
import 'sketch_image_storage.dart';

class SketchCompositeExporter {
  static Future<Uint8List> renderRoom({
    required RoomDesign room,
    required SketchDocument sketch,
    Size size = const Size(1200, 900),
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    final blueprintBytes = await BlueprintImageExporter.render(room, size: size);
    final codec = await ui.instantiateImageCodec(blueprintBytes);
    final frame = await codec.getNextFrame();
    return _composite(frame.image, sketch, size);
  }

  static Future<Uint8List> renderApartment({
    required ProjectDesign project,
    required int apartmentIndex,
    required SketchDocument sketch,
    Size size = const Size(1200, 900),
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    final blueprintBytes = await renderApartmentBlueprint(
      project: project,
      apartmentIndex: apartmentIndex,
      size: size,
    );
    final codec = await ui.instantiateImageCodec(blueprintBytes);
    final frame = await codec.getNextFrame();
    return _composite(frame.image, sketch, size);
  }

  static Future<Uint8List> renderApartmentBlueprint({
    required ProjectDesign project,
    required int apartmentIndex,
    Size size = const Size(900, 700),
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    final layout = project.apartmentsOrDefault[apartmentIndex];
    final rooms = project.roomsForApartment(apartmentIndex);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = _ApartmentSketchBlueprintPainter(
      layout: layout,
      rooms: rooms,
      roomById: project.roomById,
      canvasSize: size,
    );
    painter.paint(canvas, size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static Future<Uint8List> _composite(
    ui.Image blueprint,
    SketchDocument sketch,
    Size size,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const renderer = SketchRenderer();
    renderer.paint(canvas, size, sketch, blueprintImage: blueprint);

    for (final img in sketch.images) {
      if (!img.visible) continue;
      final file = await SketchImageStorage.resolveFile(img.storagePath);
      if (file == null) continue;
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _paintImageAnnotation(canvas, size, img, frame.image);
    }

    final picture = recorder.endRecording();
    final out = await picture.toImage(size.width.toInt(), size.height.toInt());
    final data = await out.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  static void _paintImageAnnotation(
    Canvas canvas,
    Size size,
    SketchImageAnnotation annotation,
    ui.Image image,
  ) {
    final rect = Rect.fromLTWH(
      annotation.x * size.width,
      annotation.y * size.height,
      annotation.width * size.width,
      annotation.height * size.height,
    );
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(annotation.rotation);
    if (annotation.flipX) canvas.scale(-1, 1);
    final dst = Rect.fromCenter(
      center: Offset.zero,
      width: rect.width,
      height: rect.height,
    );
    final paint = Paint()
      ..color = Color.fromARGB(
        (annotation.opacity * 255).round().clamp(0, 255),
        255,
        255,
        255,
      )
      ..filterQuality = FilterQuality.high;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      paint,
    );
    canvas.restore();
  }
}

class _ApartmentSketchBlueprintPainter {
  _ApartmentSketchBlueprintPainter({
    required this.layout,
    required this.rooms,
    required this.roomById,
    required this.canvasSize,
  });

  final ApartmentLayout layout;
  final List<RoomDesign> rooms;
  final RoomDesign? Function(String id) roomById;
  final Size canvasSize;

  void paint(Canvas canvas, Size size) {
    const padding = 48.0;
    final availW = size.width - padding * 2;
    final availH = size.height - padding * 2 - 40;
    final scale = math.min(availW / layout.widthFt, availH / layout.lengthFt);
    final aptW = layout.widthFt * scale;
    final aptH = layout.lengthFt * scale;
    final offsetX = (size.width - aptW) / 2;
    final offsetY = (size.height - aptH) / 2 + 10;
    final aptRect = Rect.fromLTWH(offsetX, offsetY, aptW, aptH);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.blue.shade50,
    );
    canvas.drawRect(aptRect, Paint()..color = const Color(0xFFF5F5F5));
    canvas.drawRect(
      aptRect,
      Paint()
        ..color = Colors.grey.shade600
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final title = TextPainter(
      text: TextSpan(
        text:
            '${layout.name} — Apartment Floor Plan • ${layout.widthFt.toStringAsFixed(0)} × ${layout.lengthFt.toStringAsFixed(0)} ft',
        style: TextStyle(
          color: Colors.blueGrey.shade900,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 32);
    title.paint(canvas, const Offset(16, 12));

    for (final placement in layout.placements) {
      final room = roomById(placement.roomId);
      if (room == null) continue;
      final pixelLayout = BlueprintPlacement.layoutPixels(
        blueprintX: placement.blueprintX,
        blueprintY: placement.blueprintY,
        widthFt: room.dimensions.width,
        depthFt: room.dimensions.length,
        rotationDeg: placement.rotation,
        roomRect: aptRect,
        scale: scale,
      );
      canvas.save();
      canvas.translate(
        pixelLayout.left + pixelLayout.bboxW / 2,
        pixelLayout.top + pixelLayout.bboxH / 2,
      );
      canvas.rotate(placement.rotation * math.pi / 180);
      final roomRect = Rect.fromCenter(
        center: Offset.zero,
        width: pixelLayout.innerW,
        height: pixelLayout.innerH,
      );
      final roomScale = math.min(
        pixelLayout.innerW / room.dimensions.width,
        pixelLayout.innerH / room.dimensions.length,
      );
      final painter = RoomBlueprintLayoutPainter(
        design: room,
        roomRect: roomRect,
        scale: roomScale,
        showDimensions: true,
      );
      painter.paint(canvas, size);
      canvas.restore();
    }
  }
}
