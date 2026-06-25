import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../domain/sketch_models.dart';
import '../domain/sketch_tool.dart';
import 'sketch_path_smoother.dart';

class SketchRenderer {
  const SketchRenderer();

  void paint(
    Canvas canvas,
    Size size,
    SketchDocument doc, {
    List<SketchPoint>? previewStroke,
    bool previewHighlighter = false,
    double previewWidth = 3,
    int previewColorArgb = 0xFF000000,
    SketchShape? previewShape,
    ui.Image? blueprintImage,
  }) {
    canvas.save();
    canvas.translate(doc.panX, doc.panY);
    canvas.scale(doc.zoom);

    if (blueprintImage != null) {
      _paintBlueprint(canvas, size, doc, blueprintImage);
    }

    for (final stroke in doc.strokes) {
      if (!stroke.visible) continue;
      _paintStroke(canvas, size, stroke);
    }

    if (previewStroke != null && previewStroke.isNotEmpty) {
      _paintPreviewStroke(
        canvas,
        size,
        previewStroke,
        previewHighlighter,
        previewWidth,
        previewColorArgb,
      );
    }

    for (final shape in doc.shapes) {
      if (!shape.visible) continue;
      _paintShape(canvas, size, shape);
    }

    if (previewShape != null) {
      _paintShape(canvas, size, previewShape);
    }

    for (final text in doc.texts) {
      if (!text.visible) continue;
      _paintText(canvas, size, text);
    }

  // Images painted by widget layer for async decode; export handles separately.

    if (doc.selectedObjectId != null) {
      _paintSelection(canvas, size, doc);
    }

    canvas.restore();
  }

  void _paintBlueprint(Canvas canvas, Size size, SketchDocument doc, ui.Image image) {
    final t = doc.blueprintTransform;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.save();
    canvas.translate(center.dx + t.x, center.dy + t.y);
    canvas.rotate(t.rotation);
    canvas.scale(t.scale);

    final aspect = image.width / image.height;
    double w = size.width * 0.9;
    double h = w / aspect;
    if (h > size.height * 0.9) {
      h = size.height * 0.9;
      w = h * aspect;
    }

    final dst = Rect.fromCenter(center: Offset.zero, width: w, height: h);
    final src = t.cropRect ??
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    final paint = Paint()..filterQuality = FilterQuality.high;
    canvas.drawImageRect(image, src, dst, paint);
    canvas.restore();
  }

  void _paintStroke(Canvas canvas, Size size, SketchStroke stroke) {
    final points = stroke.isHighlighter
        ? stroke.points
        : SketchPathSmoother.smooth(stroke.points);
    final path = SketchPathSmoother.strokeToPath(points, size);
    final color = colorFromArgb(stroke.colorArgb).withValues(alpha: stroke.opacity);
    final paint = Paint()
      ..color = stroke.isHighlighter ? color.withValues(alpha: color.a * 0.35) : color
      ..strokeWidth = stroke.width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..blendMode = stroke.isHighlighter ? BlendMode.multiply : BlendMode.srcOver;
    canvas.drawPath(path, paint);
  }

  void _paintPreviewStroke(
    Canvas canvas,
    Size size,
    List<SketchPoint> points,
    bool highlighter,
    double width,
    int colorArgb,
  ) {
    final smoothed = highlighter ? points : SketchPathSmoother.smooth(points);
    final path = SketchPathSmoother.strokeToPath(smoothed, size);
    final color = colorFromArgb(colorArgb);
    final paint = Paint()
      ..color = highlighter ? color.withValues(alpha: 0.35) : color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..blendMode = highlighter ? BlendMode.multiply : BlendMode.srcOver;
    canvas.drawPath(path, paint);
  }

  void _paintShape(Canvas canvas, Size size, SketchShape shape) {
    final rect = shape.boundsRect(size);
    final strokeColor =
        colorFromArgb(shape.strokeColorArgb).withValues(alpha: shape.opacity);
    final fillColor = shape.fillColorArgb != null
        ? colorFromArgb(shape.fillColorArgb!).withValues(alpha: shape.opacity)
        : null;

    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(shape.rotation);
    final local = Rect.fromCenter(
      center: Offset.zero,
      width: rect.width,
      height: rect.height,
    );

    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = shape.strokeWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final fillPaint = fillColor != null
        ? (Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill
          ..isAntiAlias = true)
        : null;

    switch (shape.kind) {
      case SketchShapeKind.rectangle:
        if (fillPaint != null) canvas.drawRect(local, fillPaint);
        canvas.drawRect(local, strokePaint);
      case SketchShapeKind.circle:
        final r = math.min(local.width, local.height) / 2;
        if (fillPaint != null) canvas.drawCircle(Offset.zero, r, fillPaint);
        canvas.drawCircle(Offset.zero, r, strokePaint);
      case SketchShapeKind.ellipse:
        if (fillPaint != null) canvas.drawOval(local, fillPaint);
        canvas.drawOval(local, strokePaint);
      case SketchShapeKind.line:
        canvas.drawLine(local.topLeft, local.bottomRight, strokePaint);
      case SketchShapeKind.arrow:
        _drawArrow(canvas, local.topLeft, local.bottomRight, strokePaint);
      case SketchShapeKind.doubleArrow:
        _drawArrow(canvas, local.topLeft, local.bottomRight, strokePaint, doubleHead: true);
      case SketchShapeKind.triangle:
        final path = Path()
          ..moveTo(local.topCenter.dx, local.topCenter.dy)
          ..lineTo(local.bottomRight.dx, local.bottomRight.dy)
          ..lineTo(local.bottomLeft.dx, local.bottomLeft.dy)
          ..close();
        if (fillPaint != null) canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
      case SketchShapeKind.speechBubble:
        final rrect = RRect.fromRectAndRadius(local, const Radius.circular(12));
        if (fillPaint != null) canvas.drawRRect(rrect, fillPaint);
        canvas.drawRRect(rrect, strokePaint);
        final tail = Path()
          ..moveTo(local.left + local.width * 0.2, local.bottom)
          ..lineTo(local.left + local.width * 0.15, local.bottom + local.height * 0.25)
          ..lineTo(local.left + local.width * 0.35, local.bottom);
        canvas.drawPath(tail, fillPaint ?? strokePaint);
    }
    canvas.restore();
  }

  void _drawArrow(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint, {
    bool doubleHead = false,
  }) {
    canvas.drawLine(from, to, paint);
    const headLen = 12.0;
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    _drawArrowHead(canvas, to, angle, paint, headLen);
    if (doubleHead) {
      _drawArrowHead(canvas, from, angle + math.pi, paint, headLen);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset tip, double angle, Paint paint, double len) {
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - len * math.cos(angle - math.pi / 6),
        tip.dy - len * math.sin(angle - math.pi / 6),
      )
      ..lineTo(
        tip.dx - len * math.cos(angle + math.pi / 6),
        tip.dy - len * math.sin(angle + math.pi / 6),
      )
      ..close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  void _paintText(Canvas canvas, Size size, SketchTextAnnotation text) {
    final pos = Offset(text.x * size.width, text.y * size.height);
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(text.rotation);

    final style = TextStyle(
      color: colorFromArgb(text.colorArgb).withValues(alpha: text.opacity),
      fontSize: text.fontSize,
      fontWeight: text.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: text.italic ? FontStyle.italic : FontStyle.normal,
      decoration: text.underline ? TextDecoration.underline : TextDecoration.none,
    );

    final span = TextSpan(text: text.text, style: style);
    final painter = TextPainter(
      text: span,
      textAlign: text.alignment,
      textDirection: TextDirection.ltr,
    )..layout();

    if (text.backgroundColorArgb != null) {
      final bg = colorFromArgb(text.backgroundColorArgb!)
          .withValues(alpha: text.opacity * 0.85);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-4, -4, painter.width + 8, painter.height + 8),
          const Radius.circular(4),
        ),
        Paint()..color = bg,
      );
    }

    painter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  void _paintSelection(Canvas canvas, Size size, SketchDocument doc) {
    final id = doc.selectedObjectId!;
    Rect? bounds;

    for (final shape in doc.shapes) {
      if (shape.id == id) bounds = shape.boundsRect(size);
    }
    for (final text in doc.texts) {
      if (text.id == id) {
        bounds = Rect.fromLTWH(
          text.x * size.width,
          text.y * size.height,
          120,
          text.fontSize * 2,
        );
      }
    }

    if (bounds == null) return;
    final paint = Paint()
      ..color = const Color(0xFF1565C0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(bounds.inflate(6), paint);
  }
}
