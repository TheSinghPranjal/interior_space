import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/material_item.dart';

class TextureService {
  static const _cacheKey = 'texture_cache_index';
  final _picker = ImagePicker();
  final _dataUrlCache = <String, String?>{};

  void clearDataUrlCache() => _dataUrlCache.clear();

  Future<String?> pickAndSaveTexture() async {
    try {
      if (kIsWeb) {
        return _pickAndSaveWeb();
      }
      return _pickAndSaveNative(ImageSource.gallery);
    } catch (e) {
      debugPrint('Texture pick error: $e');
      return null;
    }
  }

  Future<String?> pickAndSaveTextureFromCamera() async {
    if (kIsWeb) return pickAndSaveTexture();
    try {
      return _pickAndSaveNative(ImageSource.camera);
    } catch (e) {
      debugPrint('Texture camera pick error: $e');
      return null;
    }
  }

  Future<String?> _pickAndSaveWeb() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    if (file.bytes == null) return null;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('texture_$id', base64Encode(file.bytes!));
    await _addToCacheIndex(prefs, id);
    return 'memory://$id';
  }

  Future<String?> _pickAndSaveNative(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final texturesDir = Directory('${dir.path}/textures');
    if (!await texturesDir.exists()) {
      await texturesDir.create(recursive: true);
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
    final saved = File('${texturesDir.path}/$fileName');
    await File(picked.path).copy(saved.path);
    await _addToCacheIndex(
      await SharedPreferences.getInstance(),
      saved.path,
    );
    return saved.path;
  }

  Future<String> saveUserMaterialFile(File sourceFile) async {
    if (kIsWeb) {
      final bytes = await sourceFile.readAsBytes();
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('texture_$id', base64Encode(bytes));
      await _addToCacheIndex(prefs, id);
      return 'memory://$id';
    }

    final dir = await getApplicationDocumentsDirectory();
    final destDir = Directory('${dir.path}/user_materials');
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }
    final ext = _fileExtension(sourceFile.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final saved = await sourceFile.copy('${destDir.path}/$fileName');
    return saved.path;
  }

  String _fileExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1) return '.png';
    return path.substring(dot);
  }

  Future<String> materialToTexturePath(MaterialItem item) async {
    if (item.filePath != null) return item.filePath!;
    if (item.assetPath != null) return item.assetPath!;
    if (item.colorHex != null) {
      return getOrCreateColorTexturePath(item.colorHex!);
    }
    throw ArgumentError('Material "${item.name}" has no visual source');
  }

  Future<String> getOrCreateColorTexturePath(String hex) async {
    final normalized = hex.replaceAll('#', '').toUpperCase();
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final key = 'color_texture_$normalized';
      final existing = prefs.getString(key);
      if (existing != null) return 'memory://$existing';

      final pngBytes = await _solidColorPngBytes(normalized);
      final id = 'color_$normalized';
      await prefs.setString('texture_$id', base64Encode(pngBytes));
      await prefs.setString(key, id);
      await _addToCacheIndex(prefs, id);
      return 'memory://$id';
    }

    final dir = await getApplicationDocumentsDirectory();
    final texturesDir = Directory('${dir.path}/textures');
    if (!await texturesDir.exists()) {
      await texturesDir.create(recursive: true);
    }
    final path = '${texturesDir.path}/color_$normalized.png';
    if (!await File(path).exists()) {
      final pngBytes = await _solidColorPngBytes(normalized);
      await File(path).writeAsBytes(pngBytes);
      await _addToCacheIndex(await SharedPreferences.getInstance(), path);
    }
    return path;
  }

  Future<Uint8List> _solidColorPngBytes(String hex) async {
    final color = _parseHexColor(hex);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 8, 8),
      Paint()..color = color,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(8, 8);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Color _parseHexColor(String hex) {
    final value = hex.replaceAll('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }

  Future<void> _addToCacheIndex(SharedPreferences prefs, String path) async {
    final index = prefs.getStringList(_cacheKey) ?? [];
    index.add(path);
    await prefs.setStringList(_cacheKey, index);
  }

  Future<String?> resolveTextureDataUrl(String? path) async {
    if (path == null) return null;
    if (_dataUrlCache.containsKey(path)) return _dataUrlCache[path];

    final result = await _resolveTextureDataUrl(path);
    _dataUrlCache[path] = result;
    return result;
  }

  Future<String?> _resolveTextureDataUrl(String path) async {
    if (path.startsWith('memory://')) {
      final id = path.replaceFirst('memory://', '');
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('texture_$id');
      if (data == null) return null;
      return 'data:image/png;base64,$data';
    }

    if (kIsWeb) return path;

    final file = File(path);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    final ext = path.split('.').last.toLowerCase();
    final mime = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      _ => 'image/png',
    };
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }
}

final textureServiceProvider = Provider<TextureService>((ref) {
  return TextureService();
});
