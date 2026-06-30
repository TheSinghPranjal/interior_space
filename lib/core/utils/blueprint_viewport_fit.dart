import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fits blueprint content inside an [InteractiveViewer] viewport.
abstract final class BlueprintViewportFit {
  static void apply(
    TransformationController controller,
    Size viewportSize,
    Rect contentRect, {
    double margin = 12,
  }) {
    if (viewportSize.width <= 0 ||
        viewportSize.height <= 0 ||
        contentRect.width <= 0 ||
        contentRect.height <= 0) {
      return;
    }

    final availW = viewportSize.width - margin * 2;
    final availH = viewportSize.height - margin * 2;
    final scale = math.min(availW / contentRect.width, availH / contentRect.height);

    final dx =
        (viewportSize.width - contentRect.width * scale) / 2 - contentRect.left * scale;
    final dy =
        (viewportSize.height - contentRect.height * scale) / 2 - contentRect.top * scale;

    controller.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }
}
