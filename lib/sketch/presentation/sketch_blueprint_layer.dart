import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/blueprint_placement.dart';
import '../../models/apartment_layout.dart';
import '../../models/project_design.dart';
import '../../providers/project_provider.dart';
import '../../providers/room_design_provider.dart';
import '../../widgets/blueprint/room_blueprint_layout_painter.dart';

class SketchRoomBlueprintLayer extends ConsumerWidget {
  const SketchRoomBlueprintLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomDesignProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = 32.0;
        final availW = constraints.maxWidth - padding * 2;
        final availH = constraints.maxHeight - padding * 2;
        final dims = room.dimensions;
        final scale = math.min(
          availW / dims.effectiveWidth,
          availH / dims.effectiveLength,
        );
        final roomW = dims.effectiveWidth * scale;
        final roomH = dims.effectiveLength * scale;
        final offsetX = (constraints.maxWidth - roomW) / 2;
        final offsetY = (constraints.maxHeight - roomH) / 2;
        final roomRect = Rect.fromLTWH(offsetX, offsetY, roomW, roomH);

        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: RoomBlueprintLayoutPainter(
            design: room,
            roomRect: roomRect,
            scale: scale,
            showDimensions: true,
          ),
        );
      },
    );
  }
}

class SketchApartmentBlueprintLayer extends ConsumerWidget {
  const SketchApartmentBlueprintLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider);
    final layout = project.apartmentLayout;

    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = 32.0;
        final availW = constraints.maxWidth - padding * 2;
        final availH = constraints.maxHeight - padding * 2;
        final scale = math.min(availW / layout.widthFt, availH / layout.lengthFt);
        final aptW = layout.widthFt * scale;
        final aptH = layout.lengthFt * scale;
        final offsetX = (constraints.maxWidth - aptW) / 2;
        final offsetY = (constraints.maxHeight - aptH) / 2;
        final aptRect = Rect.fromLTWH(offsetX, offsetY, aptW, aptH);

        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _SketchApartmentFloorPainter(
            aptRect: aptRect,
            scale: scale,
            layout: layout,
            project: project,
          ),
        );
      },
    );
  }
}

class _SketchApartmentFloorPainter extends CustomPainter {
  _SketchApartmentFloorPainter({
    required this.aptRect,
    required this.scale,
    required this.layout,
    required this.project,
  });

  final Rect aptRect;
  final double scale;
  final ApartmentLayout layout;
  final ProjectDesign project;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.blue.shade50);
    canvas.drawRect(aptRect, Paint()..color = const Color(0xFFF5F5F5));
    canvas.drawRect(
      aptRect,
      Paint()
        ..color = Colors.grey.shade600
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    for (final placement in layout.placements) {
      final room = project.roomById(placement.roomId);
      if (room == null) continue;
      final pixelLayout = BlueprintPlacement.layoutPixels(
        blueprintX: placement.blueprintX,
        blueprintY: placement.blueprintY,
        widthFt: room.dimensions.width,
        depthFt: room.dimensions.length,
        rotationDeg: placement.rotation,
        roomRect: aptRect,
        scale: scale,
      );
      canvas.save();
      canvas.translate(
        pixelLayout.left + pixelLayout.bboxW / 2,
        pixelLayout.top + pixelLayout.bboxH / 2,
      );
      canvas.rotate(placement.rotation * math.pi / 180);
      final roomRect = Rect.fromCenter(
        center: Offset.zero,
        width: pixelLayout.innerW,
        height: pixelLayout.innerH,
      );
      final roomScale = math.min(
        pixelLayout.innerW / room.dimensions.width,
        pixelLayout.innerH / room.dimensions.length,
      );
      RoomBlueprintLayoutPainter(
        design: room,
        roomRect: roomRect,
        scale: roomScale,
        showDimensions: true,
      ).paint(canvas, size);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SketchApartmentFloorPainter oldDelegate) =>
      oldDelegate.aptRect != aptRect ||
      oldDelegate.layout != layout ||
      oldDelegate.project != project;
}
