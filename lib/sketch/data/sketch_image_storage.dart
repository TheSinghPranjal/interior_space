import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class SketchImageStorage {
  SketchImageStorage._();

  static const _uuid = Uuid();

  static Future<String> savePickedFile(File source) async {
    final dir = await _sketchImagesDir();
    final ext = source.path.split('.').last;
    final name = '${_uuid.v4()}.$ext';
    final dest = File('${dir.path}/$name');
    await dest.writeAsBytes(await source.readAsBytes());
    return name;
  }

  static Future<File?> resolveFile(String storagePath) async {
    final dir = await _sketchImagesDir();
    final file = File('${dir.path}/$storagePath');
    if (!file.existsSync()) return null;
    return file;
  }

  static Future<Directory> _sketchImagesDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/sketch_images');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
