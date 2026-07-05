import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Saves exported files to a user-visible location (Android Downloads, iOS Files).
class PublicDownloadSaver {
  static const _androidDownloadRoot = '/storage/emulated/0/Download';

  static Future<String?> saveBytes({
    required Uint8List bytes,
    required String fileName,
    Rect? sharePositionOrigin,
  }) async {
    if (kIsWeb) return null;

    final sanitized = _sanitizeFileName(fileName);

    if (Platform.isAndroid) {
      return _saveOnAndroid(bytes, sanitized);
    }

    if (Platform.isIOS) {
      return _saveOnIos(
        bytes,
        sanitized,
        sharePositionOrigin: sharePositionOrigin,
      );
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

  static Future<String?> _saveOnIos(
    Uint8List bytes,
    String fileName, {
    Rect? sharePositionOrigin,
  }) async {
    try {
      final documents = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${documents.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      // iOS has no public Downloads folder API. Share sheet lets the user
      // tap "Save to Files" and pick Downloads (same UX as most iOS export flows).
      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType: _mimeTypeForFileName(fileName),
            name: fileName,
          ),
        ],
        subject: fileName,
        sharePositionOrigin:
            sharePositionOrigin ?? const Rect.fromLTWH(0, 0, 1, 1),
      );

      return 'Downloads/$fileName';
    } catch (e) {
      debugPrint('iOS save failed: $e');
      return null;
    }
  }

  static Future<String?> _saveToDownloadsDirectory(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final downloadsDir = await getDownloadsDirectory();
      final targetDir = downloadsDir ?? await getApplicationDocumentsDirectory();
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      final file = File('${targetDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('Save failed: $e');
      return null;
    }
  }

  static String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  static String? _mimeTypeForFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return null;
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

  /// User-facing message after a save attempt.
  static String saveSuccessMessage(String? path, {required String fileKind}) {
    if (path == null) {
      if (!kIsWeb && Platform.isIOS) {
        return 'Could not save $fileKind.';
      }
      return 'Could not save $fileKind. Check storage permission.';
    }

    if (!kIsWeb && Platform.isIOS) {
      return '${fileKind[0].toUpperCase()}${fileKind.substring(1)} saved. '
          'Use Save to Files → Downloads in the share sheet, or find it under '
          'Files → On My iPhone → Abode Home → Downloads.';
    }

    return '${fileKind[0].toUpperCase()}${fileKind.substring(1)} saved to ${displayPath(path)}';
  }
}
