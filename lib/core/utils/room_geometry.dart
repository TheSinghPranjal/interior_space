import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/room_constants.dart';
import '../../models/enums.dart';
import '../../models/room_dimensions.dart';

/// Floor-plan corner in feet (x = width axis, y = length/depth axis).
class RoomCorner {
  const RoomCorner(this.x, this.y);

  final double x;
  final double y;

  Offset get offset => Offset(x, y);
}

class RoomGeometryResult {
  const RoomGeometryResult({
    required this.corners,
    required this.boundingWidth,
    required this.boundingLength,
    required this.isValid,
    this.validationMessage,
  });

  final List<RoomCorner> corners;
  final double boundingWidth;
  final double boundingLength;
  final bool isValid;
  final String? validationMessage;

  /// Corners ordered: front-left, front-right, back-right, back-left.
  static RoomGeometryResult invalid(String message) => RoomGeometryResult(
        corners: const [],
        boundingWidth: 0,
        boundingLength: 0,
        isValid: false,
        validationMessage: message,
      );
}

/// Computes a closed quadrilateral from four wall lengths (feet).
abstract final class RoomGeometry {
  static RoomGeometryResult fromDimensions(RoomDimensions dims) {
    final front = dims.lengthForWall(WallId.front);
    final back = dims.lengthForWall(WallId.back);
    final left = dims.lengthForWall(WallId.left);
    final right = dims.lengthForWall(WallId.right);
    return fromWallLengths(front: front, back: back, left: left, right: right);
  }

  static RoomGeometryResult fromWallLengths({
    required double front,
    required double back,
    required double left,
    required double right,
  }) {
    const minSide = RoomConstants.minWidth;
    if (front < minSide || back < minSide || left < minSide || right < minSide) {
      return RoomGeometryResult.invalid(
        'Each wall must be at least ${minSide.toStringAsFixed(0)} ft.',
      );
    }

    // Rectangle fast path.
    if ((front - back).abs() < 0.01 && (left - right).abs() < 0.01) {
      final corners = _rectangleCorners(front, left);
      return RoomGeometryResult(
        corners: corners,
        boundingWidth: front,
        boundingLength: left,
        isValid: true,
      );
    }

    // General quadrilateral: FL(0,0), FR(front,0), find BR and BL.
    const fl = RoomCorner(0, 0);
    final fr = RoomCorner(front, 0);

    RoomCorner? bestBl;
    RoomCorner? bestBr;
    var bestError = double.infinity;

    for (var i = 1; i < 359; i++) {
      final angle = i * math.pi / 180;
      final bl = RoomCorner(
        left * math.cos(angle),
        left * math.sin(angle),
      );
      final brCandidates = _circleIntersections(
        fr.x,
        fr.y,
        right,
        bl.x,
        bl.y,
        back,
      );
      for (final br in brCandidates) {
        if (br.y < -0.01) continue;
        final err = (front - back).abs() +
            (_dist(bl, br) - back).abs() +
            (_dist(fr, br) - right).abs() +
            (_dist(fl, bl) - left).abs();
        if (err < bestError) {
          bestError = err;
          bestBl = bl;
          bestBr = br;
        }
      }
    }

    if (bestBl == null || bestBr == null || bestError > 0.5) {
      return RoomGeometryResult.invalid(
        'These wall lengths cannot form a valid room. '
        'Opposite walls should be similar, and no wall should be longer than the sum of its neighbors.',
      );
    }

    final corners = [fl, fr, bestBr, bestBl];
    final xs = corners.map((c) => c.x);
    final ys = corners.map((c) => c.y);
    return RoomGeometryResult(
      corners: corners,
      boundingWidth: xs.reduce(math.max) - xs.reduce(math.min),
      boundingLength: ys.reduce(math.max) - ys.reduce(math.min),
      isValid: true,
    );
  }

  static List<RoomCorner> _rectangleCorners(double frontBack, double leftRight) {
    return [
      const RoomCorner(0, 0),
      RoomCorner(frontBack, 0),
      RoomCorner(frontBack, leftRight),
      RoomCorner(0, leftRight),
    ];
  }

  static double _dist(RoomCorner a, RoomCorner b) =>
      math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));

  static List<RoomCorner> _circleIntersections(
    double x1,
    double y1,
    double r1,
    double x2,
    double y2,
    double r2,
  ) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    final d = math.sqrt(dx * dx + dy * dy);
    if (d > r1 + r2 || d < (r1 - r2).abs() || d == 0) return [];

    final a = (r1 * r1 - r2 * r2 + d * d) / (2 * d);
    final h = math.sqrt(math.max(0, r1 * r1 - a * a));
    final px = x1 + a * dx / d;
    final py = y1 + a * dy / d;

    return [
      RoomCorner(px + h * dy / d, py - h * dx / d),
      RoomCorner(px - h * dy / d, py + h * dx / d),
    ];
  }

  static double wallLengthBetween(
    List<RoomCorner> corners,
    WallId wall,
  ) {
    if (corners.length != 4) return 0;
    final i = switch (wall) {
      WallId.front => 0,
      WallId.right => 1,
      WallId.back => 2,
      WallId.left => 3,
    };
    final a = corners[i];
    final b = corners[(i + 1) % 4];
    return _dist(a, b);
  }
}
