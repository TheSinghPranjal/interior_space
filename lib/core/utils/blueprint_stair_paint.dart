import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';

import '../../models/stair_config.dart';

/// Architectural stair symbol for floor-plan views (parallel tread lines + UP arrow).
class BlueprintStairPaint {
  static void draw({
    required Canvas canvas,
    required Rect rect,
    required StairConfig stair,
    Color? fillColor,
    Color? lineColor,
    bool showLabel = true,
  }) {
    final fill = fillColor ?? const Color(0xFFECEFF1);
    final stroke = lineColor ?? const Color(0xFF263238);
    final steps = stair.safeStepCount;

    canvas.save();
    canvas.clipRect(rect);

    canvas.drawRect(rect, Paint()..color = fill.withValues(alpha: 0.92));

    final border = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRect(rect, border);

    final treadPaint = Paint()
      ..color = stroke.withValues(alpha: 0.85)
      ..strokeWidth = 1.1;

    for (var i = 1; i < steps; i++) {
      final t = i / steps;
      final y = rect.top + rect.height * (1 - t);
      canvas.drawLine(
        Offset(rect.left, y),
        Offset(rect.right, y),
        treadPaint,
      );
    }

    final centerX = rect.center.dx;
    final bottomY = rect.bottom - rect.height * 0.08;
    final topY = rect.top + rect.height * 0.12;

    canvas.drawCircle(
      Offset(centerX, bottomY),
      math.min(rect.width, rect.height) * 0.045,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final arrowPaint = Paint()
      ..color = stroke
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(centerX, bottomY), Offset(centerX, topY), arrowPaint);
    final head = math.min(rect.width, rect.height) * 0.07;
    canvas.drawLine(
      Offset(centerX, topY),
      Offset(centerX - head * 0.55, topY + head),
      arrowPaint,
    );

    canvas.drawLine(
      Offset(centerX, topY),
      Offset(centerX + head * 0.55, topY + head),
      arrowPaint,
    );


    if (showLabel) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'UP',
          style: TextStyle(
            color: stroke,
            fontSize: math.min(rect.width * 0.16, 11),
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width * 0.5);
      tp.paint(
        canvas,
        Offset(
          centerX - tp.width / 2,
          bottomY - rect.height * 0.14,
        ),
      );
    }

    canvas.restore();
  }

  static void drawFloorItem({
    required Canvas canvas,
    required Rect roomRect,
    required double scale,
    required StairConfig stair,
    required Color color,
  }) {
    final cx = roomRect.left + stair.blueprintX * roomRect.width;
    final cy = roomRect.top + stair.blueprintY * roomRect.height;
    final w = stair.width * scale;
    final d = stair.depth * scale;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(stair.rotation * math.pi / 180);
    draw(
      canvas: canvas,
      rect: Rect.fromLTWH(-w / 2, -d / 2, w, d),
      stair: stair,
      fillColor: color.withValues(alpha: 0.35),
      lineColor: const Color(0xFF263238),
    );
    canvas.restore();
  }
}
