import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/room_constants.dart';
import 'room_geometry.dart';

/// Validation + layout helpers for user-drawn polygon rooms.
abstract final class PolygonRoomGeometry {
  static double snap(double valueFt) {
    final snap = RoomConstants.customRoomGridSnapFt;
    return (valueFt / snap).round() * snap;
  }

  static RoomCorner snapCorner(RoomCorner c) =>
      RoomCorner(snap(c.x), snap(c.y));

  static List<RoomCorner> snapVertices(List<RoomCorner> vertices) =>
      vertices.map(snapCorner).toList();

  static ({double minX, double minY, double maxX, double maxY}) bounds(
    List<RoomCorner> vertices,
  ) {
    if (vertices.isEmpty) {
      return (minX: 0, minY: 0, maxX: 0, maxY: 0);
    }
    final xs = vertices.map((v) => v.x);
    final ys = vertices.map((v) => v.y);
    return (
      minX: xs.reduce(math.min),
      minY: ys.reduce(math.min),
      maxX: xs.reduce(math.max),
      maxY: ys.reduce(math.max),
    );
  }

  static List<RoomCorner> normalizeToOrigin(List<RoomCorner> vertices) {
    final b = bounds(vertices);
    return vertices
        .map((v) => RoomCorner(v.x - b.minX, v.y - b.minY))
        .toList();
  }

  static double edgeLengthFt(List<RoomCorner> vertices, int wallIndex) {
    if (vertices.length < 2) return 0;
    final a = vertices[wallIndex % vertices.length];
    final b = vertices[(wallIndex + 1) % vertices.length];
    return math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));
  }

  static List<double> edgeLengthsFt(List<RoomCorner> vertices) =>
      List.generate(vertices.length, (i) => edgeLengthFt(vertices, i));

  static String? validate(List<RoomCorner> vertices) {
    if (vertices.length < RoomConstants.minPolygonWalls) {
      return 'Add at least ${RoomConstants.minPolygonWalls} corners to form a room.';
    }
    if (vertices.length > RoomConstants.maxPolygonWalls) {
      return 'Maximum ${RoomConstants.maxPolygonWalls} walls supported.';
    }

    final grid = RoomConstants.customRoomGridSizeFt;
    for (final v in vertices) {
      if (v.x < 0 || v.y < 0 || v.x > grid || v.y > grid) {
        return 'All corners must stay within the ${grid.toStringAsFixed(0)} ft board.';
      }
    }

    for (var i = 0; i < vertices.length; i++) {
      final len = edgeLengthFt(vertices, i);
      if (len < RoomConstants.minWidth) {
        return 'Wall ${i + 1} is too short (min ${RoomConstants.minWidth.toStringAsFixed(0)} ft).';
      }
    }

    if (_hasSelfIntersection(vertices)) {
      return 'Walls cross each other. Adjust corners so edges do not intersect.';
    }

    final area = _signedArea(vertices).abs();
    if (area < 4) {
      return 'Room area is too small.';
    }

    return null;
  }

  static double _signedArea(List<RoomCorner> vertices) {
    var sum = 0.0;
    for (var i = 0; i < vertices.length; i++) {
      final a = vertices[i];
      final b = vertices[(i + 1) % vertices.length];
      sum += a.x * b.y - b.x * a.y;
    }
    return sum / 2;
  }

  static bool _segmentsIntersect(RoomCorner p1, RoomCorner p2, RoomCorner p3, RoomCorner p4) {
    double cross(RoomCorner o, RoomCorner a, RoomCorner b) =>
        (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);

    final d1 = cross(p3, p4, p1);
    final d2 = cross(p3, p4, p2);
    final d3 = cross(p1, p2, p3);
    final d4 = cross(p1, p2, p4);

    return ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
        ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0));
  }

  static bool _hasSelfIntersection(List<RoomCorner> vertices) {
    final n = vertices.length;
    for (var i = 0; i < n; i++) {
      final a1 = vertices[i];
      final a2 = vertices[(i + 1) % n];
      for (var j = i + 1; j < n; j++) {
        if (j == i || (j + 1) % n == i || j == (i + 1) % n) continue;
        final b1 = vertices[j];
        final b2 = vertices[(j + 1) % n];
        if (_segmentsIntersect(a1, a2, b1, b2)) return true;
      }
    }
    return false;
  }

  /// Map a room corner (feet, origin = bbox min) to blueprint canvas offset inside [roomRect].
  static Offset cornerToCanvas({
    required RoomCorner corner,
    required Rect roomRect,
    required double scale,
  }) {
    return Offset(
      roomRect.left + corner.x * scale,
      roomRect.top + corner.y * scale,
    );
  }

  static Path polygonPath({
    required List<RoomCorner> vertices,
    required Rect roomRect,
    required double scale,
  }) {
    final path = Path();
    if (vertices.isEmpty) return path;
    final first = cornerToCanvas(corner: vertices.first, roomRect: roomRect, scale: scale);
    path.moveTo(first.dx, first.dy);
    for (var i = 1; i < vertices.length; i++) {
      final p = cornerToCanvas(corner: vertices[i], roomRect: roomRect, scale: scale);
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    return path;
  }
}
