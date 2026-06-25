import 'dart:ui';

import '../domain/sketch_models.dart';

/// Catmull-Rom spline smoothing for pen strokes.
class SketchPathSmoother {
  static List<SketchPoint> smooth(
    List<SketchPoint> points, {
    int subdivisions = 4,
  }) {
    if (points.length < 3) return points;

    final result = <SketchPoint>[points.first];
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;

      for (var t = 1; t <= subdivisions; t++) {
        final u = t / subdivisions;
        result.add(_catmullRom(p0, p1, p2, p3, u));
      }
    }
    return result;
  }

  static SketchPoint _catmullRom(
    SketchPoint p0,
    SketchPoint p1,
    SketchPoint p2,
    SketchPoint p3,
    double t,
  ) {
    final t2 = t * t;
    final t3 = t2 * t;
    double f(double a, double b, double c, double d) =>
        0.5 *
        ((2 * b) +
            (-a + c) * t +
            (2 * a - 5 * b + 4 * c - d) * t2 +
            (-a + 3 * b - 3 * c + d) * t3);
    return SketchPoint(f(p0.x, p1.x, p2.x, p3.x), f(p0.y, p1.y, p2.y, p3.y));
  }

  static Path strokeToPath(List<SketchPoint> points, Size size) {
    final path = Path();
    if (points.isEmpty) return path;
    final first = points.first.toOffset(size);
    path.moveTo(first.dx, first.dy);
    for (var i = 1; i < points.length; i++) {
      final p = points[i].toOffset(size);
      path.lineTo(p.dx, p.dy);
    }
    return path;
  }
}
