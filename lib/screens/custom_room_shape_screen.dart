import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/room_constants.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/polygon_room_geometry.dart';
import '../core/utils/room_geometry.dart';
import '../providers/room_design_provider.dart';
import 'custom_walls_editor_screen.dart';

/// Draw a custom room by tapping grid intersections (0.25 ft snap) on a 20×20 ft board.
class CustomRoomShapeScreen extends ConsumerStatefulWidget {
  const CustomRoomShapeScreen({super.key});

  @override
  ConsumerState<CustomRoomShapeScreen> createState() => _CustomRoomShapeScreenState();
}

class _CustomRoomShapeScreenState extends ConsumerState<CustomRoomShapeScreen> {
  List<RoomCorner> _vertices = [];
  bool _isClosed = false;
  String? _error;

  static const double _vertexHitRadiusPx = 22;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dims = ref.read(roomDesignProvider).dimensions;
      if (dims.isPolygon && dims.polygonVertices.isNotEmpty && mounted) {
        setState(() => _vertices = [...dims.polygonVertices]);
      }
    });
  }

  void _addPoint(Offset local, Size boardSize) {
    final grid = RoomConstants.customRoomGridSizeFt;
    final scale = boardSize.width / grid;

    // Prefer tapping an existing corner marker (larger hit target than grid snap).
    for (var i = 0; i < _vertices.length; i++) {
      final marker = Offset(_vertices[i].x * scale, _vertices[i].y * scale);
      if ((local - marker).distance > _vertexHitRadiusPx) continue;

      if (i == 0) {
        if (_vertices.length < RoomConstants.minPolygonWalls) {
          setState(() => _error =
              'Add at least ${RoomConstants.minPolygonWalls} corners before closing.');
          return;
        }
        setState(() {
          _error = null;
          _isClosed = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shape closed — tap Save when ready'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      setState(() => _error = 'Tap corner 1 to close the shape.');
      return;
    }

    final x = PolygonRoomGeometry.snap(local.dx / scale);
    final y = PolygonRoomGeometry.snap(local.dy / scale);

    // Snap tap near first corner to exact first corner (grid tolerance).
    if (_vertices.length >= RoomConstants.minPolygonWalls) {
      final first = _vertices.first;
      final dist = math.sqrt(math.pow(x - first.x, 2) + math.pow(y - first.y, 2));
      if (dist < RoomConstants.customRoomGridSnapFt * 1.5) {
        setState(() {
          _error = null;
          _isClosed = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shape closed — tap Save when ready'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    setState(() {
      _error = null;
      _isClosed = false;
      _vertices = [..._vertices, RoomCorner(x, y)];
    });
  }

  void _closeShape() {
    if (_vertices.length < RoomConstants.minPolygonWalls) {
      setState(() => _error =
          'Add at least ${RoomConstants.minPolygonWalls} corners before closing.');
      return;
    }
    setState(() {
      _error = null;
      _isClosed = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shape closed — tap Save when ready'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _undo() {
    if (_vertices.isEmpty) return;
    setState(() {
      _vertices = _vertices.sublist(0, _vertices.length - 1);
      _error = null;
      _isClosed = false;
    });
  }

  void _clear() {
    setState(() {
      _vertices = [];
      _error = null;
      _isClosed = false;
    });
  }

  void _save() {
    final error = PolygonRoomGeometry.validate(_vertices);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    ref.read(roomDesignProvider.notifier).setPolygonRoom(_vertices);
    if (!mounted) return;
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Custom room shape saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final edgeLengths = _vertices.length >= 2
        ? PolygonRoomGeometry.edgeLengthsFt(_vertices)
        : <double>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Room Shape'),
        actions: [
          TextButton(
            onPressed: _vertices.length >= RoomConstants.minPolygonWalls ? _save : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Text(
            'Tap grid intersections to place corners. Each segment becomes a wall. '
            'When finished, tap corner 1 or Close shape to join the last wall to the first. '
            'Snap: ${RoomConstants.customRoomGridSnapFt} ft • Board: '
            '${RoomConstants.customRoomGridSizeFt.toStringAsFixed(0)} × '
            '${RoomConstants.customRoomGridSizeFt.toStringAsFixed(0)} ft',
            style: theme.textTheme.bodyMedium,
          ),
          if (_vertices.length >= RoomConstants.minPolygonWalls && !_isClosed)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Tap corner 1 (highlighted) or use Close shape below.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (_isClosed)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Shape closed — ${_vertices.length} walls',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ),
          AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  onTapDown: (d) => _addPoint(d.localPosition, size),
                  child: CustomPaint(
                    size: size,
                    painter: _CustomRoomGridPainter(
                      vertices: _vertices,
                      isClosed: _isClosed,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _vertices.isNotEmpty ? _undo : null,
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('Undo corner'),
              ),
              OutlinedButton.icon(
                onPressed: _vertices.isNotEmpty ? _clear : null,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Clear'),
              ),
              if (_vertices.length >= RoomConstants.minPolygonWalls && !_isClosed)
                FilledButton.icon(
                  onPressed: _closeShape,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Close shape'),
                ),
              if (_vertices.length >= RoomConstants.minPolygonWalls)
                FilledButton.icon(
                  onPressed: () {
                    _save();
                    if (!mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CustomWallsEditorScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.wallpaper_outlined, size: 18),
                  label: const Text('Save & edit walls'),
                ),
            ],
          ),
          if (edgeLengths.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Walls (${edgeLengths.length})', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            ...List.generate(edgeLengths.length, (i) {
              return Text('Wall ${i + 1}: ${edgeLengths[i].toStringAsFixed(2)} ft');
            }),
          ],
        ],
      ),
    );
  }
}

class _CustomRoomGridPainter extends CustomPainter {
  _CustomRoomGridPainter({
    required this.vertices,
    required this.isClosed,
  });

  final List<RoomCorner> vertices;
  final bool isClosed;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = RoomConstants.customRoomGridSizeFt;
    final snap = RoomConstants.customRoomGridSnapFt;
    final scale = size.width / grid;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFF5F5F0),
    );

    final majorPaint = Paint()
      ..color = Colors.blueGrey.shade300
      ..strokeWidth = 1;
    final minorPaint = Paint()
      ..color = Colors.blueGrey.shade100
      ..strokeWidth = 0.5;

    for (var ft = 0.0; ft <= grid; ft += snap) {
      final p = ft * scale;
      final paint = ft % 1 == 0 ? majorPaint : minorPaint;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), paint);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), paint);
    }

    if (vertices.length >= 2) {
      final path = Path();
      final first = Offset(vertices.first.x * scale, vertices.first.y * scale);
      path.moveTo(first.dx, first.dy);
      for (var i = 1; i < vertices.length; i++) {
        final v = vertices[i];
        path.lineTo(v.x * scale, v.y * scale);
      }
      if (vertices.length >= RoomConstants.minPolygonWalls) {
        path.close();
      }

      final fillAlpha = isClosed ? 0.18 : 0.10;
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.blue.withValues(alpha: fillAlpha)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = isClosed ? Colors.green.shade700 : Colors.blueGrey.shade800
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    final canClose = vertices.length >= RoomConstants.minPolygonWalls && !isClosed;
    for (var i = 0; i < vertices.length; i++) {
      final v = vertices[i];
      final c = Offset(v.x * scale, v.y * scale);
      final isFirst = i == 0;
      if (isFirst && canClose) {
        canvas.drawCircle(
          c,
          12,
          Paint()
            ..color = Colors.green.withValues(alpha: 0.25)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          c,
          12,
          Paint()
            ..color = Colors.green.shade600
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      canvas.drawCircle(
        c,
        5,
        Paint()..color = isFirst && isClosed ? Colors.green.shade700 : Colors.blue.shade700,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _CustomRoomGridPainter oldDelegate) =>
      oldDelegate.vertices != vertices || oldDelegate.isClosed != isClosed;
}
