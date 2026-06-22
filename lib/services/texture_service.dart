import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TextureService {
  static const _cacheKey = 'texture_cache_index';
  final _picker = ImagePicker();
  final _dataUrlCache = <String, String?>{};

  void clearDataUrlCache() => _dataUrlCache.clear();

  Future<String?> pickAndSaveTexture() async {
    try {
      if (kIsWeb) {
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

      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
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

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final saved = File('${texturesDir.path}/$fileName');
      await File(picked.path).copy(saved.path);
      await _addToCacheIndex(
        await SharedPreferences.getInstance(),
        saved.path,
      );
      return saved.path;
    } catch (e) {
      debugPrint('Texture pick error: $e');
      return null;
    }
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
