import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/apartment_layout.dart';
import '../models/project_design.dart';
import '../models/room_design.dart';
import '../sketch/data/sketch_composite_exporter.dart';
import '../sketch/data/sketch_image_storage.dart';
import 'texture_service.dart';

class ApartmentShareException implements Exception {
  ApartmentShareException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApartmentShareImportResult {
  const ApartmentShareImportResult({
    required this.apartment,
    required this.rooms,
  });

  final ApartmentLayout apartment;
  final List<RoomDesign> rooms;
}

/// Exports and imports a full apartment (layout + all rooms) as a `.ispace` ZIP bundle.
class ApartmentShareService {
  ApartmentShareService(this._textureService);

  static const formatId = 'interior-space-apartment';
  static const formatVersion = 1;
  static const fileExtension = 'ispace';
  static const mimeType = 'application/zip';
  static const assetsPrefix = 'assets/';

  static const _manifestFile = 'manifest.json';
  static const _apartmentFile = 'apartment.json';
  static const _previewFile = 'preview.png';

  static const _texturePathKeys = {'texturePath', 'wallpaperPath'};
  static const _sketchPathKeys = {'storagePath'};

  final TextureService _textureService;

  Future<void> shareApartment({
    required ApartmentLayout apartment,
    required List<RoomDesign> rooms,
  }) async {
    final exported = await exportApartment(apartment: apartment, rooms: rooms);

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
        subject: apartment.name,
        text: 'Interior Space apartment design: ${apartment.name}',
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
      subject: apartment.name,
      text: 'Interior Space apartment design: ${apartment.name}',
    );
  }

  Future<ApartmentShareExportResult> exportApartment({
    required ApartmentLayout apartment,
    required List<RoomDesign> rooms,
  }) async {
    final payload = {
      'apartment': apartment.toJson(),
      'rooms': rooms.map((r) => r.toJson()).toList(),
    };
    final bundledAssets = <String, Uint8List>{};
    final sketchAssetKeys = <String>{};
    await _bundleAssetPaths(payload, bundledAssets, sketchAssetKeys);

    final manifest = {
      'format': formatId,
      'version': formatVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'apartmentName': apartment.name,
      'roomCount': rooms.length,
    };

    final archive = Archive();
    archive.addFile(
      ArchiveFile(
        _manifestFile,
        utf8.encode(jsonEncode(manifest)).length,
        utf8.encode(jsonEncode(manifest)),
      ),
    );
    archive.addFile(
      ArchiveFile(
        _apartmentFile,
        utf8.encode(jsonEncode(payload)).length,
        utf8.encode(jsonEncode(payload)),
      ),
    );

    for (final entry in bundledAssets.entries) {
      archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
    }

    try {
      final previewProject = ProjectDesign(
        apartments: [apartment],
        rooms: rooms
            .map((r) => r.copyWith(apartmentIndex: 0))
            .toList(growable: false),
        activeApartmentIndex: 0,
        activeRoomIndex: 0,
      );
      final preview = await SketchCompositeExporter.renderApartment(
        project: previewProject,
        apartmentIndex: 0,
        sketch: apartment.sketch,
      );
      archive.addFile(ArchiveFile(_previewFile, preview.length, preview));
    } catch (e) {
      debugPrint('Apartment share preview skipped: $e');
    }

    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));
    final safeName = _safeFileName(apartment.name);
    return ApartmentShareExportResult(
      bytes: zipBytes,
      fileName: '${safeName}_apartment.$fileExtension',
    );
  }

  Future<ApartmentShareImportResult> pickAndImportApartment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      throw ApartmentShareException('No file selected.');
    }

    final file = result.files.first;
    final bytes = await _readPickedFileBytes(file);
    if (bytes == null || bytes.isEmpty) {
      throw ApartmentShareException('Could not read the selected file.');
    }

    return importApartmentBytes(bytes, fileName: file.name);
  }

  Future<ApartmentShareImportResult> importApartmentBytes(
    Uint8List bytes, {
    String? fileName,
  }) async {
    if (!_looksLikeZip(bytes)) {
      throw ApartmentShareException(
        'Unsupported file${fileName != null ? ' ($fileName)' : ''}. '
        'Choose an apartment file exported from Interior Space (.ispace or .zip).',
      );
    }
    return _importZip(bytes);
  }

  Future<ApartmentShareImportResult> _importZip(Uint8List bytes) async {
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw ApartmentShareException(
        'Invalid apartment file — could not read ZIP archive.',
      );
    }

    final manifestFile = archive.findFile(_manifestFile);
    final apartmentFile = archive.findFile(_apartmentFile);
    if (apartmentFile == null) {
      throw ApartmentShareException(
        'Invalid apartment file — missing apartment.json. '
        'If this is a single room file, import it from the room blueprint view.',
      );
    }

    if (manifestFile != null) {
      final manifest = jsonDecode(utf8.decode(manifestFile.content as List<int>))
          as Map<String, dynamic>;
      final format = manifest['format'] as String?;
      final version = (manifest['version'] as num?)?.toInt() ?? 0;
      if (format == 'interior-space-room') {
        throw ApartmentShareException(
          'This is a room file. Import it from the room blueprint view.',
        );
      }
      if (format != null && format != formatId) {
        throw ApartmentShareException('Unsupported apartment file format: $format');
      }
      if (version > formatVersion) {
        throw ApartmentShareException(
          'This apartment file requires a newer app version (format v$version).',
        );
      }
    }

    final payload = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(apartmentFile.content as List<int>))
          as Map<String, dynamic>,
    );

    final textureAssetToLocal = <String, String>{};
    final sketchAssetToLocal = <String, String>{};
    for (final file in archive.files) {
      if (!file.isFile) continue;
      if (!file.name.startsWith(assetsPrefix)) continue;
      final content = Uint8List.fromList(file.content);
      if (file.name.contains('/sketch_') || file.name.contains('sketch_')) {
        sketchAssetToLocal[file.name] =
            await _installSketchAssetBytes(content, file.name);
      } else {
        textureAssetToLocal[file.name] =
            await _installTextureAssetBytes(content, file.name);
      }
    }

    _remapBundledPaths(payload, textureAssetToLocal, _texturePathKeys);
    _remapBundledPaths(payload, sketchAssetToLocal, _sketchPathKeys);
    _textureService.clearDataUrlCache();

    final apartmentJson = payload['apartment'] as Map<String, dynamic>?;
    final roomsJson = payload['rooms'] as List<dynamic>?;
    if (apartmentJson == null || roomsJson == null) {
      throw ApartmentShareException('Invalid apartment file — missing layout or rooms.');
    }

    final apartment = ApartmentLayout.fromJson(apartmentJson);
    final rooms = roomsJson
        .map((e) => RoomDesign.fromJson(e as Map<String, dynamic>))
        .toList();

    if (rooms.isEmpty) {
      throw ApartmentShareException('Apartment file contains no rooms.');
    }

    return ApartmentShareImportResult(apartment: apartment, rooms: rooms);
  }

  Future<void> _bundleAssetPaths(
    Map<String, dynamic> json,
    Map<String, Uint8List> bundledAssets,
    Set<String> sketchAssetKeys,
  ) async {
    final pathRemap = <String, String>{};
    var textureIndex = 0;
    var sketchIndex = 0;

    Future<void> walk(dynamic node) async {
      if (node is Map<String, dynamic>) {
        for (final key in _texturePathKeys) {
          final value = node[key];
          if (value is! String || value.isEmpty) continue;
          if (value.startsWith(assetsPrefix)) continue;

          var bundledKey = pathRemap[value];
          if (bundledKey == null) {
            final bytes = await _readTextureAssetBytes(value);
            if (bytes != null && bytes.isNotEmpty) {
              final ext = _extensionFromPath(value);
              bundledKey =
                  '$assetsPrefix${'tex_${textureIndex.toString().padLeft(3, '0')}.$ext'}';
              bundledAssets[bundledKey] = bytes;
              pathRemap[value] = bundledKey;
              textureIndex++;
            }
          }
          node[key] = bundledKey;
        }
        for (final key in _sketchPathKeys) {
          final value = node[key];
          if (value is! String || value.isEmpty) continue;
          if (value.startsWith(assetsPrefix)) continue;

          var bundledKey = pathRemap[value];
          if (bundledKey == null) {
            final bytes = await _readSketchAssetBytes(value);
            if (bytes != null && bytes.isNotEmpty) {
              final ext = _extensionFromPath(value);
              bundledKey =
                  '$assetsPrefix${'sketch_${sketchIndex.toString().padLeft(3, '0')}.$ext'}';
              bundledAssets[bundledKey] = bytes;
              pathRemap[value] = bundledKey;
              sketchAssetKeys.add(bundledKey);
              sketchIndex++;
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

  Future<Uint8List?> _readTextureAssetBytes(String path) async {
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

  Future<Uint8List?> _readSketchAssetBytes(String storagePath) async {
    if (kIsWeb) return null;
    final file = await SketchImageStorage.resolveFile(storagePath);
    if (file == null || !await file.exists()) return null;
    return file.readAsBytes();
  }

  Future<String> _installTextureAssetBytes(Uint8List bytes, String assetName) async {
    if (kIsWeb) {
      final id =
          'import_${DateTime.now().millisecondsSinceEpoch}_${assetName.hashCode.abs()}';
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
    final fileName =
        'import_${DateTime.now().millisecondsSinceEpoch}_${assetName.hashCode.abs()}.$ext';
    final file = File('${texturesDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<String> _installSketchAssetBytes(Uint8List bytes, String assetName) async {
    if (kIsWeb) return assetName.split('/').last;

    final dir = await getApplicationDocumentsDirectory();
    final sketchDir = Directory('${dir.path}/sketch_images');
    if (!await sketchDir.exists()) {
      await sketchDir.create(recursive: true);
    }

    final ext = _extensionFromPath(assetName);
    final fileName =
        'import_${DateTime.now().millisecondsSinceEpoch}_${assetName.hashCode.abs()}.$ext';
    final file = File('${sketchDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return fileName;
  }

  void _remapBundledPaths(
    Map<String, dynamic> json,
    Map<String, String> assetToLocal,
    Set<String> pathKeys,
  ) {
    void walk(dynamic node) {
      if (node is Map<String, dynamic>) {
        for (final key in pathKeys) {
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
    final cleaned =
        name.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_');
    return cleaned.isEmpty ? 'apartment' : cleaned;
  }
}

class ApartmentShareExportResult {
  const ApartmentShareExportResult({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
}

final apartmentShareServiceProvider = Provider<ApartmentShareService>((ref) {
  return ApartmentShareService(ref.read(textureServiceProvider));
});
