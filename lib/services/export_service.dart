import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/pdf_export_settings.dart';
import '../models/apartment_details.dart';
import '../models/apartment_layout.dart';
import '../models/ac_unit_config.dart';
import '../models/door_config.dart';
import '../models/enums.dart';
import '../models/fan_config.dart';
import '../models/furniture_item.dart';
import '../models/light_config.dart';
import '../models/project_design.dart';
import '../models/room_design.dart';
import '../models/room_3d_export_images.dart';
import '../models/stair_config.dart';
import '../models/wall_tv_unit_config.dart';
import '../models/window_config.dart';
import 'blueprint_image_exporter.dart';
import '../sketch/data/sketch_composite_exporter.dart';
import '../widgets/company/company_image.dart';
import 'company_profile_storage_service.dart';
import 'pdf_export_theme.dart';
import 'public_download_saver.dart';

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
    final fileName =
        '${name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png';
    return PublicDownloadSaver.saveBytes(bytes: bytes, fileName: fileName);
  }

  /// Exports a design report as PDF.
  ///
  /// When [roomId] is set, only that room is included.
  /// Otherwise all rooms in [apartmentIndex] (or the active apartment) are included.
  Future<String?> generatePdf(
    ProjectDesign project, {
    String? roomId,
    int? apartmentIndex,
    Map<int, Room3DExportImages>? render3dImagesByRoomIndex,
    Uint8List? apartmentTopView3d,
    Uint8List? apartmentFrontView3d,
    PdfExportSettings pdfSettings = const PdfExportSettings(),
    bool includeApartmentSections = false,
  }) async {
    if (kIsWeb) return null;

    final pdf = pw.Document();
    final aptIndex = apartmentIndex ?? project.safeActiveApartmentIndex;
    final apartmentLayout = project.apartmentsOrDefault[
        aptIndex.clamp(0, project.apartmentsOrDefault.length - 1)];
    final apartmentName = apartmentLayout.name;

    final List<RoomDesign> rooms;
    final bool singleRoomExport;
    if (roomId != null) {
      final room = project.roomById(roomId);
      if (room == null) return null;
      rooms = [room];
      singleRoomExport = true;
    } else {
      rooms = project.roomsForApartment(aptIndex);
      singleRoomExport = false;
    }
    if (rooms.isEmpty) return null;

    final reportTitle = singleRoomExport
        ? rooms.first.name
        : includeApartmentSections
            ? apartmentName
            : '$apartmentName — All Rooms';
    final generatedAt = DateFormat('MMMM d, yyyy  h:mm a').format(DateTime.now());

    final companyProfile = await CompanyProfileStorageService().load();
    pw.MemoryImage? companyLogoImage;
    if (companyProfile.hasLogo) {
      final logoBytes =
          await CompanyImageLoader.loadBytes(companyProfile.logoPath!);
      if (logoBytes != null) {
        companyLogoImage = pw.MemoryImage(logoBytes);
      }
    }

    final blueprintImages = <int, Uint8List>{};
    for (var i = 0; i < rooms.length; i++) {
      blueprintImages[i] = await _renderRoomBlueprint(rooms[i]);
    }

    Uint8List? apartmentBlueprintImage;
    if (!singleRoomExport && includeApartmentSections) {
      apartmentBlueprintImage = await SketchCompositeExporter.renderApartmentBlueprint(
        project: project,
        apartmentIndex: aptIndex,
      );
    }

    final sketchPages = pdfSettings.includeSketchInPdf
        ? await _renderSketchPages(
            project: project,
            apartmentLayout: apartmentLayout,
            rooms: rooms,
            aptIndex: aptIndex,
            includeApartmentSections: includeApartmentSections,
          )
        : const <_SketchPdfPage>[];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          ..._buildCoverLogo(companyLogoImage),
          pw.Header(
            level: 0,
            child: pw.Text(reportTitle, style: PdfTextStyles.reportTitle()),
          ),
          pw.Text(
            'Interior Space Design Report',
            style: PdfTextStyles.reportSubtitle(),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Generated: $generatedAt', style: PdfTextStyles.body()),
          pw.Text('Total rooms: ${rooms.length}', style: PdfTextStyles.body()),
          if (!singleRoomExport && includeApartmentSections) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Apartment size: ${apartmentLayout.widthFt.toStringAsFixed(1)} x '
              '${apartmentLayout.lengthFt.toStringAsFixed(1)} ft',
              style: PdfTextStyles.body(),
            ),
          ],
          if (!singleRoomExport &&
              includeApartmentSections &&
              apartmentLayout.details.hasAny) ...[
            pw.SizedBox(height: 12),
            ..._buildApartmentDetailsSection(apartmentLayout.details),
          ],
        ],
      ),
    );

    if (!singleRoomExport &&
        includeApartmentSections &&
        apartmentBlueprintImage != null) {
      final floorPlanImage = apartmentBlueprintImage;
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _sectionTitle('Apartment Floor Plan'),
              pw.SizedBox(height: 16),
              pw.Expanded(
                child: pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(floorPlanImage),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    for (final entry in rooms.asMap().entries) {
      final index = entry.key;
      final room = entry.value;
      final room3dImages = pdfSettings.shouldCapture3d &&
              render3dImagesByRoomIndex != null
          ? render3dImagesByRoomIndex[index]
          : null;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => _buildRoomSection(
            room: room,
            roomIndex: index,
            blueprintImage: blueprintImages[index]!,
            render3dImages: room3dImages,
            pdfSettings: pdfSettings,
            standalonePage: true,
          ),
        ),
      );
    }

    if (!singleRoomExport &&
        includeApartmentSections &&
        pdfSettings.shouldCapture3d) {
      if (apartmentTopView3d != null) {
        pdf.addPage(
          _buildApartmentImagePage(
            title: 'Apartment 3D Top View',
            image: apartmentTopView3d,
          ),
        );
      }
      if (apartmentFrontView3d != null) {
        pdf.addPage(
          _buildApartmentImagePage(
            title: 'Apartment 3D Front View',
            image: apartmentFrontView3d,
          ),
        );
      }
    }

    for (final sketchPage in sketchPages) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                sketchPage.title,
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 16),
              pw.Expanded(
                child: pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(sketchPage.image),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final fileName = '${reportTitle.replaceAll(' ', '_')}_design.pdf';
    return PublicDownloadSaver.saveBytes(
      bytes: Uint8List.fromList(await pdf.save()),
      fileName: fileName,
    );
  }

  List<pw.Widget> _buildApartmentDetailsSection(ApartmentDetails details) {
    final rows = <List<String>>[];

    void addRow(String label, String value) {
      if (value.trim().isEmpty) return;
      rows.add([label, value.trim()]);
    }

    addRow('Unit Type', details.unitType);
    addRow('Tower', details.tower);
    addRow('Super Built-Up Area', details.superBuiltUpArea);
    addRow('Carpet Area', details.carpetArea);
    addRow('Block Name', details.blockName);
    addRow('Block', details.block);
    if (details.facing != null) {
      addRow('Facing', details.facing!.label);
    }
    addRow('Description', details.description);

    if (rows.isEmpty) return const [];

    return [
      _sectionTitle('Apartment Information'),
      styledTable(
        headers: const ['Field', 'Value'],
        rows: rows,
      ),
    ];
  }

  List<pw.Widget> _buildRoomSection({
    required RoomDesign room,
    required int roomIndex,
    required Uint8List blueprintImage,
    Room3DExportImages? render3dImages,
    PdfExportSettings pdfSettings = const PdfExportSettings(),
    bool standalonePage = false,
  }) {
    final d = room.dimensions;
    final floorArea = (d.width * d.length).toStringAsFixed(1);

    return [
      if (!standalonePage) pw.SizedBox(height: 20),
      pw.Header(
        level: 1,
        child: pw.Text(
          'Room ${roomIndex + 1}: ${room.name}',
          style: PdfTextStyles.roomHeading(),
        ),
      ),
      pw.SizedBox(height: 8),
      _sectionTitle('Room Dimensions'),
      pw.Text(
        'Width: ${d.width} ft     Length: ${d.length} ft     Height: ${d.height} ft',
        style: PdfTextStyles.body(),
      ),
      pw.Text('Floor area: $floorArea sq ft', style: PdfTextStyles.body()),
      pw.SizedBox(height: 12),
      _sectionTitle('Floor Plan'),
      pw.Center(
        child: pw.Image(
          pw.MemoryImage(blueprintImage),
          fit: pw.BoxFit.contain,
          height: 260,
        ),
      ),
      if (render3dImages != null && pdfSettings.shouldCapture3d) ...[
        pw.SizedBox(height: 12),
        _sectionTitle('3D Preview'),
        if (pdfSettings.includeFrontView && render3dImages.front != null) ...[
          pw.Text('Front view', style: PdfTextStyles.caption()),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Image(
              pw.MemoryImage(render3dImages.front!),
              fit: pw.BoxFit.contain,
              height: 200,
            ),
          ),
        ],
        if (pdfSettings.includeTopView && render3dImages.top != null) ...[
          pw.SizedBox(height: 8),
          pw.Text('Top view', style: PdfTextStyles.caption()),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Image(
              pw.MemoryImage(render3dImages.top!),
              fit: pw.BoxFit.contain,
              height: 200,
            ),
          ),
        ],
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
        'Material: ${room.floor.material.name}     Color: ${room.floor.color}',
        style: PdfTextStyles.body(),
      ),
      pw.Text(
        'Floor dimensions: ${d.width.toStringAsFixed(1)} x ${d.length.toStringAsFixed(1)} ft',
        style: PdfTextStyles.body(),
      ),
      pw.Text(
        'Tile size: ${room.floor.tileWidth.toStringAsFixed(1)} x ${room.floor.tileLength.toStringAsFixed(1)} ft     Pattern: ${room.floor.pattern.name}',
        style: PdfTextStyles.body(),
      ),
      pw.SizedBox(height: 10),
      _sectionTitle('Ceiling'),
      pw.Text(
        'Material: ${room.ceiling.material.name}     Color: ${room.ceiling.color}',
        style: PdfTextStyles.body(),
      ),
      pw.Text(
        'Ceiling height: ${d.height.toStringAsFixed(1)} ft',
        style: PdfTextStyles.body(),
      ),
      if (room.ceiling.falseCeilingEnabled)
        pw.Text(
          'False ceiling: ${room.ceiling.falseCeilingType.name}     '
          'Depth: ${room.ceiling.falseCeilingDepth.toStringAsFixed(1)} ft     '
          'Thickness: ${room.ceiling.falseCeilingThickness.toStringAsFixed(1)} ft',
          style: PdfTextStyles.body(),
        ),

      if (room.doors.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        _sectionTitle('Doors (${room.doors.length})'),
        _detailTable(
          headers: const ['Wall', 'Width', 'Height', 'From edge', 'Rotation', 'Material', 'Color'],
          rows: room.doors.map(_doorRow).toList(),
        ),
      ],
      if (room.stairs.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        _sectionTitle('Stairs (${room.stairs.length})'),
        _detailTable(
          headers: const [
            'Width',
            'Height',
            'Length',
            'Steps',
            'Rise',
            'Tread',
            'Shape',
            'Finish',
          ],
          rows: room.stairs.map(_stairRow).toList(),
        ),
      ],
      if (room.windows.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        _sectionTitle('Windows (${room.windows.length})'),
        _detailTable(
          headers: const ['Wall', 'Width', 'Height', 'From edge', 'From floor', 'Rotation', 'Color'],
          rows: room.windows.map(_windowRow).toList(),
        ),
      ],
      if (room.acUnits.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        _sectionTitle('AC Units (${room.acUnits.length})'),
        _detailTable(
          headers: const ['Wall', 'Width', 'Height', 'From edge', 'From floor', 'Rotation', 'Color'],
          rows: room.acUnits.map(_acUnitRow).toList(),
        ),
      ],
      if (room.furniture.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        _sectionTitle('Furniture (${room.furniture.length})'),
        _detailTable(
          headers: const ['Item', 'W×D×H (ft)', 'Position', 'Rotation', 'Color'],
          rows: room.furniture.map((f) => _furnitureRow(f, room)).toList(),
        ),
      ],
      if (room.wallTvUnits.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        _sectionTitle('Wall TV Units (${room.wallTvUnits.length})'),
        _detailTable(
          headers: const ['Wall', 'Width', 'Height', 'From edge', 'From floor', 'Rotation', 'Color'],
          rows: room.wallTvUnits.map(_wallTvUnitRow).toList(),
        ),
      ],
      if (room.lights.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        _sectionTitle('Lighting (${room.lights.length})'),
        _detailTable(
          headers: const ['Type', 'Brightness', 'Temperature', 'Position (X,Y,Z)', 'Color', 'On'],
          rows: room.lights.map(_lightRow).toList(),
        ),
      ],
      if (room.fans.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        _sectionTitle('Ceiling Fans (${room.fans.length})'),
        _detailTable(
          headers: const ['Position (X,Y)', 'Height', 'Color'],
          rows: room.fans.map(_fanRow).toList(),
        ),
      ],
      if (!standalonePage) ...[
        pw.SizedBox(height: 8),
        pw.Divider(),
      ],
    ];
  }

  pw.Page _buildApartmentImagePage({
    required String title,
    required Uint8List image,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(title),
          pw.SizedBox(height: 16),
          pw.Expanded(
            child: pw.Center(
              child: pw.Image(
                pw.MemoryImage(image),
                fit: pw.BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4, top: 4),
      child: pw.Text(text, style: PdfTextStyles.sectionTitle()),
    );
  }

  pw.Widget _detailTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return styledTable(headers: headers, rows: rows);
  }

  List<String> _doorRow(DoorConfig door) => [
        door.wall.label,
        '${door.width.toStringAsFixed(1)} ft',
        '${door.height.toStringAsFixed(1)} ft',
        '${door.positionFromEdge.toStringAsFixed(1)} ft',
        '${door.rotation.toStringAsFixed(0)}°',
        door.material.name,
        door.color,
      ];

  List<String> _windowRow(WindowConfig window) => [
        window.wall.label,
        '${window.width.toStringAsFixed(1)} ft',
        '${window.height.toStringAsFixed(1)} ft',
        '${window.positionFromEdge.toStringAsFixed(1)} ft',
        '${window.positionFromFloor.toStringAsFixed(1)} ft',
        '${window.rotation.toStringAsFixed(0)}°',
        window.glassColor,
      ];

  List<String> _acUnitRow(AcUnitConfig unit) => [
        unit.wall.label,
        '${unit.width.toStringAsFixed(1)} ft',
        '${unit.height.toStringAsFixed(1)} ft',
        '${unit.positionFromEdge.toStringAsFixed(1)} ft',
        '${unit.positionFromFloor.toStringAsFixed(1)} ft',
        '${unit.rotation.toStringAsFixed(0)}°',
        unit.color,
      ];

  List<String> _wallTvUnitRow(WallTvUnitConfig unit) => [
        unit.wall.label,
        '${unit.width.toStringAsFixed(1)} ft',
        '${unit.height.toStringAsFixed(1)} ft',
        '${unit.positionFromEdge.toStringAsFixed(1)} ft',
        '${unit.positionFromFloor.toStringAsFixed(1)} ft',
        '${unit.rotation.toStringAsFixed(0)}°',
        unit.color,
      ];

  List<String> _furnitureRow(FurnitureItem item, RoomDesign room) {
    final position = item.isWallMounted
        ? '${item.wall?.label ?? 'Wall'} @ ${item.positionFromEdge.toStringAsFixed(1)} ft from edge'
        : '${item.positionFromLeftFt(room.dimensions).toStringAsFixed(1)} ft left, '
            '${item.positionFromFrontFt(room.dimensions).toStringAsFixed(1)} ft front';
    return [
      FurnitureItem.displayLabel(room.furniture, item),
      '${item.width.toStringAsFixed(1)}×${item.depth.toStringAsFixed(1)}×${item.height.toStringAsFixed(1)}',
      position,
      '${item.rotation.toStringAsFixed(0)}°',
      item.color,
    ];
  }

  List<String> _lightRow(LightConfig light) => [
        light.type.name,
        light.brightness.toStringAsFixed(1),
        light.temperature.name,
        '${light.positionX.toStringAsFixed(2)}, ${light.positionY.toStringAsFixed(2)}, ${light.positionZ.toStringAsFixed(2)}',
        light.color,
        light.enabled ? 'Yes' : 'No',
      ];

  List<String> _fanRow(FanConfig fan) => [
        '${fan.positionX.toStringAsFixed(2)}, ${fan.positionY.toStringAsFixed(2)}',
        fan.height.toStringAsFixed(2),
        fan.color,
      ];

  List<String> _stairRow(StairConfig stair) => [
        '${stair.width.toStringAsFixed(1)} ft',
        '${stair.height.toStringAsFixed(1)} ft',
        '${stair.depth.toStringAsFixed(1)} ft',
        '${stair.safeStepCount}',
        '${stair.risePerStep.toStringAsFixed(2)} ft',
        '${stair.treadDepth.toStringAsFixed(2)} ft',
        stair.shape.label,
        stair.materialPreset.label,
      ];

  Future<Uint8List> _renderRoomBlueprint(RoomDesign room) async {
    return BlueprintImageExporter.render(room);
  }

  Future<List<_SketchPdfPage>> _renderSketchPages({
    required ProjectDesign project,
    required ApartmentLayout apartmentLayout,
    required List<RoomDesign> rooms,
    required int aptIndex,
    required bool includeApartmentSections,
  }) async {
    final pages = <_SketchPdfPage>[];

    if (includeApartmentSections && !apartmentLayout.sketch.isEmpty) {
      pages.add(
        _SketchPdfPage(
          title: 'Apartment Sketch — ${apartmentLayout.name}',
          image: await SketchCompositeExporter.renderApartment(
            project: project,
            apartmentIndex: aptIndex,
            sketch: apartmentLayout.sketch,
          ),
        ),
      );
    }

    for (final room in rooms) {
      if (room.sketch.isEmpty) continue;
      pages.add(
        _SketchPdfPage(
          title: 'Room Sketch — ${room.name}',
          image: await SketchCompositeExporter.renderRoom(
            room: room,
            sketch: room.sketch,
          ),
        ),
      );
    }

    return pages;
  }

  List<pw.Widget> _buildCoverLogo(pw.MemoryImage? logo) {
    if (logo == null) return const [];

    return [
      pw.Center(
        child: pw.Container(
          width: 120,
          height: 120,
          alignment: pw.Alignment.center,
          child: pw.Image(
            logo,
            fit: pw.BoxFit.contain,
          ),
        ),
      ),
      pw.SizedBox(height: 20),
    ];
  }
}

class _SketchPdfPage {
  const _SketchPdfPage({
    required this.title,
    required this.image,
  });

  final String title;
  final Uint8List image;
}

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});
