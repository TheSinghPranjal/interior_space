import 'dart:ui';

import '../domain/sketch_models.dart';

class SketchHitTester {
  static String? hitTest(SketchDocument doc, Offset local, Size canvasSize) {
    final threshold = 12 / doc.zoom;

    for (final text in doc.texts.reversed) {
      if (!text.visible) continue;
      final pos = Offset(text.x * canvasSize.width, text.y * canvasSize.height);
      final rect = Rect.fromLTWH(pos.dx, pos.dy, 120, text.fontSize * 2);
      if (rect.inflate(threshold).contains(local)) return text.id;
    }

    for (final shape in doc.shapes.reversed) {
      if (!shape.visible) continue;
      if (shape.boundsRect(canvasSize).inflate(threshold).contains(local)) {
        return shape.id;
      }
    }

    for (final image in doc.images.reversed) {
      if (!image.visible) continue;
      final rect = Rect.fromLTWH(
        image.x * canvasSize.width,
        image.y * canvasSize.height,
        image.width * canvasSize.width,
        image.height * canvasSize.height,
      );
      if (rect.inflate(threshold).contains(local)) return image.id;
    }

    for (final stroke in doc.strokes.reversed) {
      if (!stroke.visible) continue;
      for (final p in stroke.points) {
        final offset = p.toOffset(canvasSize);
        if ((offset - local).distance < threshold + stroke.width) {
          return stroke.id;
        }
      }
    }
    return null;
  }
}
