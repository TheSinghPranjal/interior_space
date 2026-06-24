import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/room_design.dart';
import 'blueprint_image_exporter.dart';
import 'texture_service.dart';

class RoomShareException implements Exception {
  RoomShareException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Exports and imports a single room as a self-contained `.ispace` ZIP bundle.
class RoomShareService {
  RoomShareService(this._textureService);

  static const formatId = 'interior-space-room';
  static const formatVersion = 1;
  /// ZIP archive; use a single extension (no dots/hyphens) for mobile file pickers.
  static const fileExtension = 'ispace';
  static const mimeType = 'application/zip';
  static const assetsPrefix = 'assets/';

  static const _manifestFile = 'manifest.json';
  static const _roomFile = 'room.json';
  static const _previewFile = 'preview.png';

  static const _pathKeys = {'texturePath', 'wallpaperPath'};

  final TextureService _textureService;

  /// Bundle the room (JSON + images) and open the system share sheet.
  Future<void> shareRoom(RoomDesign room) async {
    final exported = await exportRoom(room);

    if (!kIsWeb) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${exported.fileName}');
      await file.writeAsBytes(exported.bytes);
      await Share.shareXFiles(
        [
          XFile(
            file.path,
            name: exported.fileName,
            mimeType: mimeType,
          ),
        ],
        subject: room.name,
        text: 'Interior Space room design: ${room.name}',
      );
      return;
    }

    await Share.shareXFiles(
      [
        XFile.fromData(
          exported.bytes,
          name: exported.fileName,
          mimeType: mimeType,
        ),
      ],
      subject: room.name,
      text: 'Interior Space room design: ${room.name}',
    );
  }

  /// Creates a `.ispace` ZIP in memory.
  Future<RoomShareExportResult> exportRoom(RoomDesign room) async {
    final roomJson = Map<String, dynamic>.from(room.toJson());
    final bundledAssets = <String, Uint8List>{};
    await _bundleAssetPaths(roomJson, bundledAssets);

    final manifest = {
      'format': formatId,
      'version': formatVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'roomName': room.name,
    };

    final archive = Archive();
    archive.addFile(ArchiveFile(_manifestFile, utf8.encode(jsonEncode(manifest)).length, utf8.encode(jsonEncode(manifest))));
    archive.addFile(ArchiveFile(_roomFile, utf8.encode(jsonEncode(roomJson)).length, utf8.encode(jsonEncode(roomJson))));

    for (final entry in bundledAssets.entries) {
      final assetPath = entry.key;
      final bytes = entry.value;
      archive.addFile(ArchiveFile(assetPath, bytes.length, bytes));
    }

    try {
      final preview = await BlueprintImageExporter.render(room);
      archive.addFile(ArchiveFile(_previewFile, preview.length, preview));
    } catch (e) {
      debugPrint('Room share preview skipped: $e');
    }

    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));
    final safeName = _safeFileName(room.name);
    return RoomShareExportResult(
      bytes: zipBytes,
      fileName: '${safeName}_room.$fileExtension',
    );
  }

  /// Pick a shared room file and import it.
  Future<RoomDesign> pickAndImportRoom() async {
    // FileType.any — Android/iOS reject custom extensions like "ispace-room".
    // We validate content (ZIP magic bytes or JSON) after pick.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      throw RoomShareException('No file selected.');
    }

    final file = result.files.first;
    final bytes = await _readPickedFileBytes(file);
    if (bytes == null || bytes.isEmpty) {
      throw RoomShareException('Could not read the selected file.');
    }

    return importRoomBytes(bytes, fileName: file.name);
  }

  Future<Uint8List?> _readPickedFileBytes(PlatformFile file) async {
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return file.bytes;
    }

    final path = file.path;
    if (path == null || kIsWeb) return null;

    final ioFile = File(path);
    if (!await ioFile.exists()) return null;
    return ioFile.readAsBytes();
  }

  Future<RoomDesign> importRoomBytes(Uint8List bytes, {String? fileName}) async {
    if (_looksLikeZip(bytes)) {
      return _importZip(bytes);
    }

    // Legacy plain JSON `.ispace` export (no bundled images).
    try {
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      if (json.containsKey('rooms')) {
        final rooms = json['rooms'] as List<dynamic>;
        if (rooms.isEmpty) throw RoomShareException('Project file has no rooms.');
        return RoomDesign.fromJson(rooms.first as Map<String, dynamic>);
      }
      return RoomDesign.fromJson(json);
    } catch (e) {
      if (e is RoomShareException) rethrow;
      throw RoomShareException(
        'Unsupported file${fileName != null ? ' ($fileName)' : ''}. '
        'Choose a room file exported from Interior Space (.ispace or .zip).',
      );
    }
  }

  Future<RoomDesign> _importZip(Uint8List bytes) async {
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw RoomShareException('Invalid room file — could not read ZIP archive.');
    }

    final manifestFile = archive.findFile(_manifestFile);
    final roomFile = archive.findFile(_roomFile);
    if (roomFile == null) {
      throw RoomShareException('Invalid room file — missing room.json.');
    }

    if (manifestFile != null) {
      final manifest = jsonDecode(utf8.decode(manifestFile.content as List<int>))
          as Map<String, dynamic>;
      final format = manifest['format'] as String?;
      final version = (manifest['version'] as num?)?.toInt() ?? 0;
      if (format != null && format != formatId) {
        throw RoomShareException('Unsupported room file format: $format');
      }
      if (version > formatVersion) {
        throw RoomShareException(
          'This room file requires a newer app version (format v$version).',
        );
      }
    }

    final roomJson = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(roomFile.content as List<int>)) as Map<String, dynamic>,
    );

    final assetToLocal = <String, String>{};
    for (final file in archive.files) {
      if (!file.isFile) continue;
      if (!file.name.startsWith(assetsPrefix)) continue;
      assetToLocal[file.name] = await _installAssetBytes(
        Uint8List.fromList(file.content),
        file.name,
      );
    }

    _remapBundledPaths(roomJson, assetToLocal);
    _textureService.clearDataUrlCache();
    return RoomDesign.fromJson(roomJson);
  }

  Future<void> _bundleAssetPaths(
    Map<String, dynamic> json,
    Map<String, Uint8List> bundledAssets,
  ) async {
    final pathRemap = <String, String>{};
    var assetIndex = 0;

    Future<void> walk(dynamic node) async {
      if (node is Map<String, dynamic>) {
        for (final key in _pathKeys) {
          final value = node[key];
          if (value is! String || value.isEmpty) continue;
          if (value.startsWith(assetsPrefix)) continue;

          var bundledKey = pathRemap[value];
          if (bundledKey == null) {
            final bytes = await _readAssetBytes(value);
            if (bytes != null && bytes.isNotEmpty) {
              final ext = _extensionFromPath(value);
              bundledKey =
                  '$assetsPrefix${'tex_${assetIndex.toString().padLeft(3, '0')}.$ext'}';
              bundledAssets[bundledKey] = bytes;
              pathRemap[value] = bundledKey;
              assetIndex++;
            }
          }
          node[key] = bundledKey;
        }
        for (final value in node.values) {
          await walk(value);
        }
      } else if (node is List) {
        for (final item in node) {
          await walk(item);
        }
      }
    }

    await walk(json);
  }

  Future<Uint8List?> _readAssetBytes(String path) async {
    if (path.startsWith('memory://')) {
      final id = path.replaceFirst('memory://', '');
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('texture_$id');
      if (data == null) return null;
      return base64Decode(data);
    }

    if (kIsWeb) return null;

    final file = File(path);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  Future<String> _installAssetBytes(Uint8List bytes, String assetName) async {
    if (kIsWeb) {
      final id = 'import_${DateTime.now().millisecondsSinceEpoch}_${assetName.hashCode.abs()}';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('texture_$id', base64Encode(bytes));
      return 'memory://$id';
    }

    final dir = await getApplicationDocumentsDirectory();
    final texturesDir = Directory('${dir.path}/textures');
    if (!await texturesDir.exists()) {
      await texturesDir.create(recursive: true);
    }

    final ext = _extensionFromPath(assetName);
    final fileName = 'import_${DateTime.now().millisecondsSinceEpoch}_${assetName.hashCode.abs()}.$ext';
    final file = File('${texturesDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  void _remapBundledPaths(
    Map<String, dynamic> json,
    Map<String, String> assetToLocal,
  ) {
    void walk(dynamic node) {
      if (node is Map<String, dynamic>) {
        for (final key in _pathKeys) {
          final value = node[key];
          if (value is String && assetToLocal.containsKey(value)) {
            node[key] = assetToLocal[value];
          }
        }
        for (final value in node.values) {
          walk(value);
        }
      } else if (node is List) {
        for (final item in node) {
          walk(item);
        }
      }
    }

    walk(json);
  }

  bool _looksLikeZip(Uint8List bytes) {
    return bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B;
  }

  String _extensionFromPath(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot >= path.length - 1) return 'png';
    final ext = path.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'jpg',
      'webp' => 'webp',
      'gif' => 'gif',
      _ => 'png',
    };
  }

  String _safeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_');
    return cleaned.isEmpty ? 'room' : cleaned;
  }
}

class RoomShareExportResult {
  const RoomShareExportResult({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
}

final roomShareServiceProvider = Provider<RoomShareService>((ref) {
  return RoomShareService(ref.read(textureServiceProvider));
});
