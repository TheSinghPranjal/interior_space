import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/cupboard_config.dart';
import '../models/door_config.dart';
import '../models/enums.dart';
import '../models/furniture_item.dart';
import '../models/light_config.dart';
import '../models/project_design.dart';
import '../models/room_design.dart';
import '../models/window_config.dart';
import 'blueprint_image_exporter.dart';

class ExportService {
  Future<void> shareProjectFile(ProjectDesign project, String? filePath) async {
    if (filePath != null && !kIsWeb) {
      await Share.shareXFiles([XFile(filePath)], text: project.projectName);
      return;
    }
    final json = const JsonEncoder.withIndent('  ').convert(project.toJson());
    await Share.share(json, subject: '${project.projectName} - Interior Space');
  }

  Future<String?> saveScreenshot(Uint8List bytes, String name) async {
    if (kIsWeb) return null;
    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${dir.path}/exports');
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }
    final file = File(
      '${exportsDir.path}/${name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<String?> generatePdf(
    ProjectDesign project, {
    Map<int, Uint8List>? render3dImagesByRoomIndex,
  }) async {
    if (kIsWeb) return null;

    final pdf = pw.Document();
    final rooms = project.roomsOrDefault;
    final generatedAt = DateFormat('MMMM d, yyyy • h:mm a').format(DateTime.now());

    final blueprintImages = <int, Uint8List>{};
    for (var i = 0; i < rooms.length; i++) {
      blueprintImages[i] = await BlueprintImageExporter.render(rooms[i]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              project.projectName,
              style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text('Interior Space Design Report', style: const pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 6),
          pw.Text('Generated: $generatedAt'),
          pw.Text('Total rooms: ${rooms.length}'),
          pw.SizedBox(height: 8),
          pw.Divider(),
          ...rooms.asMap().entries.expand((entry) {
            final index = entry.key;
            final room = entry.value;
            return _buildRoomSection(
              room: room,
              roomIndex: index,
              blueprintImage: blueprintImages[index]!,
              render3dImage: render3dImagesByRoomIndex?[index],
            );
          }),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${dir.path}/exports');
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }
    final fileName = rooms.length == 1
        ? '${rooms.first.name.replaceAll(' ', '_')}_design.pdf'
        : '${project.projectName.replaceAll(' ', '_')}_design.pdf';
    final file = File('${exportsDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  List<pw.Widget> _buildRoomSection({
    required RoomDesign room,
    required int roomIndex,
    required Uint8List blueprintImage,
    Uint8List? render3dImage,
  }) {
    final d = room.dimensions;
    final floorArea = (d.width * d.length).toStringAsFixed(1);

    return [
      pw.SizedBox(height: 20),
      pw.Header(
        level: 1,
        child: pw.Text(
          'Room ${roomIndex + 1}: ${room.name}',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.SizedBox(height: 8),
      _sectionTitle('Room Dimensions'),
      pw.Text('Width: ${d.width} ft  •  Length: ${d.length} ft  •  Height: ${d.height} ft'),
      pw.Text('Floor area: $floorArea sq ft'),
      pw.SizedBox(height: 12),
      _sectionTitle('Floor Plan'),
      pw.Center(
        child: pw.Image(
          pw.MemoryImage(blueprintImage),
          fit: pw.BoxFit.contain,
          height: 260,
        ),
      ),
      if (render3dImage != null) ...[
        pw.SizedBox(height: 12),
        _sectionTitle('3D Preview'),
        pw.Center(
          child: pw.Image(
            pw.MemoryImage(render3dImage),
            fit: pw.BoxFit.contain,
            height: 240,
          ),
        ),
      ],
      pw.SizedBox(height: 12),
      _sectionTitle('Walls'),
      _detailTable(
        headers: const ['Wall', 'Width', 'Height', 'Surface', 'Color / Texture'],
        rows: room.walls.map((wall) {
          final spansWidth = wall.id == WallId.front || wall.id == WallId.back;
          final wallWidth = spansWidth ? d.width : d.length;
          final surface = wall.surfaceType == SurfaceType.solidColor
              ? 'Solid color'
              : wall.surfaceType == SurfaceType.texture
                  ? 'Texture (${wall.texture.name})'
                  : 'Wallpaper';
          return [
            wall.id.label,
            '${wallWidth.toStringAsFixed(1)} ft',
            '${d.height.toStringAsFixed(1)} ft',
            surface,
            wall.color,
          ];
        }).toList(),
      ),
      pw.SizedBox(height: 10),
      _sectionTitle('Floor'),
      pw.Text(
        'Material: ${room.floor.material.name}  •  Color: ${room.floor.color}',
      ),
      pw.Text(
        'Floor dimensions: ${d.width.toStringAsFixed(1)} × ${d.length.toStringAsFixed(1)} ft',
      ),
      pw.Text(
        'Tile size: ${room.floor.tileWidth.toStringAsFixed(1)} × ${room.floor.tileLength.toStringAsFixed(1)} ft  •  Pattern: ${room.floor.pattern.name}',
      ),
      pw.SizedBox(height: 10),
      _sectionTitle('Ceiling'),
      pw.Text('Material: ${room.ceiling.material.name}  •  Color: ${room.ceiling.color}'),
      pw.Text('Ceiling height: ${d.height.toStringAsFixed(1)} ft'),
      if (room.ceiling.falseCeilingEnabled)
        pw.Text(
          'False ceiling: ${room.ceiling.falseCeilingType.name}  •  '
          'Depth: ${room.ceiling.falseCeilingDepth.toStringAsFixed(1)} ft  •  '
          'Thickness: ${room.ceiling.falseCeilingThickness.toStringAsFixed(1)} ft',
        ),
      pw.SizedBox(height: 10),
      _sectionTitle('Doors (${room.doors.length})'),
      if (room.doors.isEmpty)
        pw.Text('None')
      else
        _detailTable(
          headers: const ['Wall', 'Width', 'Height', 'From edge', 'Material', 'Color'],
          rows: room.doors.map(_doorRow).toList(),
        ),
      pw.SizedBox(height: 10),
      _sectionTitle('Windows (${room.windows.length})'),
      if (room.windows.isEmpty)
        pw.Text('None')
      else
        _detailTable(
          headers: const ['Wall', 'Width', 'Height', 'From edge', 'From floor', 'Color'],
          rows: room.windows.map(_windowRow).toList(),
        ),
      pw.SizedBox(height: 10),
      _sectionTitle('Furniture (${room.furniture.length})'),
      if (room.furniture.isEmpty)
        pw.Text('None')
      else
        _detailTable(
          headers: const ['Item', 'W×D×H (ft)', 'Position', 'Rotation', 'Color'],
          rows: room.furniture.map((f) => _furnitureRow(f, room)).toList(),
        ),
      pw.SizedBox(height: 10),
      _sectionTitle('Cupboards (${room.cupboards.length})'),
      if (room.cupboards.isEmpty)
        pw.Text('None')
      else
        _detailTable(
          headers: const ['W×D×H (ft)', 'From left', 'From front', 'Rotation', 'Finish', 'Color'],
          rows: room.cupboards.map((c) => _cupboardRow(c, room)).toList(),
        ),
      pw.SizedBox(height: 10),
      _sectionTitle('Lighting (${room.lights.length})'),
      if (room.lights.isEmpty)
        pw.Text('None')
      else
        _detailTable(
          headers: const ['Type', 'Brightness', 'Temperature', 'Position (X,Y,Z)', 'Color', 'On'],
          rows: room.lights.map(_lightRow).toList(),
        ),
      pw.SizedBox(height: 8),
      pw.Divider(),
    ];
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _detailTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        for (var i = 0; i < headers.length; i++)
          i: const pw.FlexColumnWidth(),
      },
    );
  }

  List<String> _doorRow(DoorConfig door) => [
        door.wall.label,
        '${door.width.toStringAsFixed(1)} ft',
        '${door.height.toStringAsFixed(1)} ft',
        '${door.positionFromEdge.toStringAsFixed(1)} ft',
        door.material.name,
        door.color,
      ];

  List<String> _windowRow(WindowConfig window) => [
        window.wall.label,
        '${window.width.toStringAsFixed(1)} ft',
        '${window.height.toStringAsFixed(1)} ft',
        '${window.positionFromEdge.toStringAsFixed(1)} ft',
        '${window.positionFromFloor.toStringAsFixed(1)} ft',
        window.glassColor,
      ];

  List<String> _furnitureRow(FurnitureItem item, RoomDesign room) {
    final position = item.isWallMounted
        ? '${item.wall?.label ?? 'Wall'} @ ${item.positionFromEdge.toStringAsFixed(1)} ft from edge'
        : '${item.positionFromLeftFt(room.dimensions).toStringAsFixed(1)} ft left, '
            '${item.positionFromFrontFt(room.dimensions).toStringAsFixed(1)} ft front';
    return [
      item.type.label,
      '${item.width.toStringAsFixed(1)}×${item.depth.toStringAsFixed(1)}×${item.height.toStringAsFixed(1)}',
      position,
      '${item.rotation.toStringAsFixed(0)}°',
      item.color,
    ];
  }

  List<String> _cupboardRow(CupboardConfig cupboard, RoomDesign room) => [
        '${cupboard.width.toStringAsFixed(1)}×${cupboard.depth.toStringAsFixed(1)}×${cupboard.height.toStringAsFixed(1)}',
        '${cupboard.positionFromLeftFt(room.dimensions).toStringAsFixed(1)} ft',
        '${cupboard.positionFromFrontFt(room.dimensions).toStringAsFixed(1)} ft',
        '${cupboard.rotation.toStringAsFixed(0)}°',
        cupboard.texture.name,
        cupboard.color,
      ];

  List<String> _lightRow(LightConfig light) => [
        light.type.name,
        light.brightness.toStringAsFixed(1),
        light.temperature.name,
        '${light.positionX.toStringAsFixed(2)}, ${light.positionY.toStringAsFixed(2)}, ${light.positionZ.toStringAsFixed(2)}',
        light.color,
        light.enabled ? 'Yes' : 'No',
      ];
}

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});
