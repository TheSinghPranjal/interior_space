import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/enums.dart';
import '../models/room_design.dart';

class ExportService {
  Future<void> shareProjectFile(RoomDesign design, String? filePath) async {
    if (filePath != null && !kIsWeb) {
      await Share.shareXFiles([XFile(filePath)], text: design.name);
      return;
    }
    final json = const JsonEncoder.withIndent('  ').convert(design.toJson());
    await Share.share(json, subject: '${design.name} - Interior Space');
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

  Future<String?> generatePdf(RoomDesign design) async {
    if (kIsWeb) return null;

    final pdf = pw.Document();
    final d = design.dimensions;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              design.name,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Room Dimensions', style: pw.TextStyle(fontSize: 16)),
          pw.Text('Width: ${d.width} ft  |  Length: ${d.length} ft  |  Height: ${d.height} ft'),
          pw.SizedBox(height: 16),
          pw.Text('Walls', style: pw.TextStyle(fontSize: 16)),
          ...design.walls.map(
            (w) => pw.Text('${w.id.label}: ${w.surfaceType.name} - ${w.color}'),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Floor: ${design.floor.material.name} - ${design.floor.color}'),
          pw.Text('Ceiling: ${design.ceiling.material.name} - ${design.ceiling.color}'),
          pw.SizedBox(height: 16),
          pw.Text('Doors: ${design.doors.length}'),
          pw.Text('Windows: ${design.windows.length}'),
          pw.Text('Cupboards: ${design.cupboards.length}'),
          pw.Text('Lights: ${design.lights.length}'),
          pw.Text('Furniture: ${design.furniture.length}'),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${dir.path}/exports');
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }
    final file = File(
      '${exportsDir.path}/${design.name.replaceAll(' ', '_')}_design.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});
