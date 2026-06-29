import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/company_profile.dart';

class CompanyProfileStorageService {
  static const _profileKey = 'company_profile_v1';
  static const _imageDirName = 'company_profile';

  final _picker = ImagePicker();

  Future<CompanyProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return const CompanyProfile();
    return CompanyProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(CompanyProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<String?> pickAndSaveImage({required String prefix}) async {
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
        final id = '${prefix}_${DateTime.now().millisecondsSinceEpoch}';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('company_img_$id', base64Encode(file.bytes!));
        return 'memory://company_img_$id';
      }

      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 88,
      );
      if (picked == null) return null;

      final dir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${dir.path}/$_imageDirName');
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      final ext = picked.path.split('.').last.toLowerCase();
      final safeExt = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';
      final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$safeExt';
      final saved = File('${imageDir.path}/$fileName');
      await File(picked.path).copy(saved.path);
      return saved.path;
    } catch (e) {
      debugPrint('Company image pick error: $e');
      return null;
    }
  }

  Future<void> deleteImageFile(String? path) async {
    if (path == null || path.isEmpty) return;

    if (path.startsWith('memory://')) {
      final prefs = await SharedPreferences.getInstance();
      final id = path.replaceFirst('memory://', '');
      await prefs.remove(id);
      return;
    }

    if (kIsWeb) return;

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

final companyProfileStorageProvider = Provider<CompanyProfileStorageService>((ref) {
  return CompanyProfileStorageService();
});
