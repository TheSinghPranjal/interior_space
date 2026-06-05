import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/room_design.dart';

class ProjectStorageService {
  static const _currentProjectKey = 'current_room_design';
  static const _savedProjectsKey = 'saved_room_projects';

  Future<void> saveCurrent(RoomDesign design) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentProjectKey, jsonEncode(design.toJson()));
  }

  Future<RoomDesign?> loadCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_currentProjectKey);
    if (data == null) return null;
    return RoomDesign.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }

  Future<List<Map<String, String>>> listSavedProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_savedProjectsKey) ?? [];
    return list
        .map((e) {
          final map = jsonDecode(e) as Map<String, dynamic>;
          return {
            'id': map['id'] as String,
            'name': map['name'] as String,
          };
        })
        .toList();
  }

  Future<void> saveProject(RoomDesign design, {String? id}) async {
    final prefs = await SharedPreferences.getInstance();
    final projectId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final entry = jsonEncode({
      'id': projectId,
      'name': design.name,
      'design': design.toJson(),
      'savedAt': DateTime.now().toIso8601String(),
    });

    final list = prefs.getStringList(_savedProjectsKey) ?? [];
    final index = list.indexWhere((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      return map['id'] == projectId;
    });
    if (index >= 0) {
      list[index] = entry;
    } else {
      list.add(entry);
    }
    await prefs.setStringList(_savedProjectsKey, list);
    await saveCurrent(design);
  }

  Future<RoomDesign?> loadProject(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_savedProjectsKey) ?? [];
    for (final entry in list) {
      final map = jsonDecode(entry) as Map<String, dynamic>;
      if (map['id'] == id) {
        return RoomDesign.fromJson(
          map['design'] as Map<String, dynamic>,
        );
      }
    }
    return null;
  }

  Future<String?> exportProjectFile(RoomDesign design) async {
    if (kIsWeb) return null;
    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${dir.path}/exports');
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }
    final file = File(
      '${exportsDir.path}/${design.name.replaceAll(' ', '_')}.ispace',
    );
    await file.writeAsString(jsonEncode(design.toJson()));
    return file.path;
  }
}

final projectStorageProvider = Provider<ProjectStorageService>((ref) {
  return ProjectStorageService();
});
