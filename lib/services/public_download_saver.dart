import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Saves exported files to the user-visible Android Downloads folder.
class PublicDownloadSaver {
  static const _androidDownloadRoot = '/storage/emulated/0/Download';

  static Future<String?> saveBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (kIsWeb) return null;

    final sanitized = _sanitizeFileName(fileName);

    if (Platform.isAndroid) {
      return _saveOnAndroid(bytes, sanitized);
    }

    return _saveToDownloadsDirectory(bytes, sanitized);
  }

  static Future<String?> _saveOnAndroid(Uint8List bytes, String fileName) async {
    if (MediaStore.appFolder.isEmpty) {
      MediaStore.appFolder = 'InteriorSpace';
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(bytes, flush: true);

    try {
      final mediaStore = MediaStore();
      final saveInfo = await mediaStore.saveFile(
        tempFilePath: tempFile.path,
        dirType: DirType.download,
        dirName: DirName.download,
        relativePath: FilePath.root,
      );

      if (saveInfo != null) {
        final savedName = saveInfo.name;
        final path = await mediaStore.getFilePathFromUri(uriString: saveInfo.uri.toString());
        return path ?? 'Downloads/$savedName';
      }
    } catch (e) {
      debugPrint('MediaStore save failed: $e');
    }

    return _saveDirectlyToDownloadRoot(bytes, fileName);
  }

  static Future<String?> _saveDirectlyToDownloadRoot(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final downloadDir = Directory(_androidDownloadRoot);
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      final file = File('${downloadDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('Direct Download save failed: $e');
      return null;
    }
  }

  static Future<String?> _saveToDownloadsDirectory(
    Uint8List bytes,
    String fileName,
  ) async {
    final downloadsDir = await getDownloadsDirectory();
    final targetDir = downloadsDir ?? await getApplicationDocumentsDirectory();
    final file = File('${targetDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  static String displayPath(String? path) {
    if (path == null) return 'Downloads';

    if (path.startsWith('Downloads/')) return path;

    const downloadSegments = ['/Download/', '/Downloads/'];
    for (final segment in downloadSegments) {
      final index = path.indexOf(segment);
      if (index >= 0) {
        return 'Downloads/${path.substring(index + segment.length)}';
      }
    }

    return path;
  }
}
