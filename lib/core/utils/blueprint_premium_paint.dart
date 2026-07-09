import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Draws premium top-down furniture sprites in blueprint painters.
abstract final class BlueprintPremiumPaint {
  static void drawBed({
    required Canvas canvas,
    required Rect rect,
    required ui.Image image,
    bool selected = false,
  }) {
    if (rect.width < 2 || rect.height < 2) return;

    final background = Paint()..color = const Color(0xFFEDE6DC);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      background,
    );

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)));

    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    canvas.drawImageRect(
      image,
      src,
      rect,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();

    final border = Paint()
      ..color = selected ? const Color(0xFF2D5A4A) : Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2.5 : 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      border,
    );
  }
}
