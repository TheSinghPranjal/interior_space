import 'dart:math' as math;
import 'dart:ui';

class BlueprintPlacement {
  static double effectiveWidthFt(double width, double depth, double rotationDeg) {
    final rad = rotationDeg * math.pi / 180;
    return width * math.cos(rad).abs() + depth * math.sin(rad).abs();
  }

  static double effectiveDepthFt(double width, double depth, double rotationDeg) {
    final rad = rotationDeg * math.pi / 180;
    return width * math.sin(rad).abs() + depth * math.cos(rad).abs();
  }

  static ({double halfX, double halfY}) normalizedHalfExtents({
    required double widthFt,
    required double depthFt,
    required double rotationDeg,
    required double roomWidthFt,
    required double roomLengthFt,
  }) {
    final effW = effectiveWidthFt(widthFt, depthFt, rotationDeg);
    final effD = effectiveDepthFt(widthFt, depthFt, rotationDeg);
    return (
      halfX: ((effW / roomWidthFt) / 2).clamp(0, 0.5),
      halfY: ((effD / roomLengthFt) / 2).clamp(0, 0.5),
    );
  }

  static ({double bx, double by}) clampBlueprintCenter({
    required double centerXNorm,
    required double centerYNorm,
    required double widthFt,
    required double depthFt,
    required double rotationDeg,
    required double roomWidthFt,
    required double roomLengthFt,
  }) {
    final half = normalizedHalfExtents(
      widthFt: widthFt,
      depthFt: depthFt,
      rotationDeg: rotationDeg,
      roomWidthFt: roomWidthFt,
      roomLengthFt: roomLengthFt,
    );
    return (
      bx: centerXNorm.clamp(half.halfX, 1 - half.halfX),
      by: centerYNorm.clamp(half.halfY, 1 - half.halfY),
    );
  }

  static ({
    double left,
    double top,
    double bboxW,
    double bboxH,
    double innerW,
    double innerH,
  }) layoutPixels({
    required double blueprintX,
    required double blueprintY,
    required double widthFt,
    required double depthFt,
    required double rotationDeg,
    required Rect roomRect,
    required double scale,
  }) {
    final innerW = widthFt * scale;
    final innerH = depthFt * scale;
    final rad = rotationDeg * math.pi / 180;
    final cos = math.cos(rad).abs();
    final sin = math.sin(rad).abs();
    final bboxW = innerW * cos + innerH * sin;
    final bboxH = innerW * sin + innerH * cos;
    final cx = roomRect.left + blueprintX * roomRect.width;
    final cy = roomRect.top + blueprintY * roomRect.height;
    return (
      left: cx - bboxW / 2,
      top: cy - bboxH / 2,
      bboxW: bboxW,
      bboxH: bboxH,
      innerW: innerW,
      innerH: innerH,
    );
  }
}
