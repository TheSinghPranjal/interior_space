import 'dart:math' as math;
import 'dart:ui';

import '../../models/enums.dart';
import '../../models/furniture_item.dart';

typedef BlueprintItemBoxPainter = void Function(
  Canvas canvas,
  Rect rect,
  String label,
  Color color,
);

/// Draws a floor-placed furniture item with rotation matching the room blueprint.
class BlueprintFurniturePaint {
  static void drawFloorItem({
    required Canvas canvas,
    required Rect roomRect,
    required double scale,
    required FurnitureItem item,
    required String label,
    required Color color,
    required BlueprintItemBoxPainter drawItemBox,
  }) {
    final cx = roomRect.left + item.blueprintX * roomRect.width;
    final cy = roomRect.top + item.blueprintY * roomRect.height;
    final w = item.width * scale;
    final d = item.depth * scale;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(item.rotation * math.pi / 180);
    drawItemBox(canvas, Rect.fromLTWH(-w / 2, -d / 2, w, d), label, color);
    canvas.restore();
  }

  static Rect wallItemRect({
    required Rect roomRect,
    required double scale,
    required FurnitureItem item,
  }) {
    final wall = item.wall ?? WallId.left;
    final along = item.positionFromEdge * scale;
    final into = item.depth * scale;
    final alongSize = item.width * scale;

    return switch (wall) {
      WallId.front => Rect.fromLTWH(roomRect.left + along, roomRect.top, alongSize, into),
      WallId.back => Rect.fromLTWH(roomRect.left + along, roomRect.bottom - into, alongSize, into),
      WallId.left => Rect.fromLTWH(roomRect.left, roomRect.top + along, into, alongSize),
      WallId.right => Rect.fromLTWH(roomRect.right - into, roomRect.top + along, into, alongSize),
    };
  }
}
