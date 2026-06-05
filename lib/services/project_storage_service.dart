import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/project_design.dart';
import '../models/room_design.dart';

class ProjectStorageService {
  static const _currentProjectKey = 'current_room_design';
  static const _savedProjectsKey = 'saved_room_projects';

  Future<void> saveCurrent(ProjectDesign project) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentProjectKey, jsonEncode(project.toJson()));
  }

  Future<ProjectDesign?> loadCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_currentProjectKey);
    if (data == null) return null;
    return ProjectDesign.fromJson(jsonDecode(data) as Map<String, dynamic>);
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

  Future<void> saveProject(ProjectDesign project, {String? id}) async {
    final prefs = await SharedPreferences.getInstance();
    final projectId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final entry = jsonEncode({
      'id': projectId,
      'name': project.projectName,
      'design': project.toJson(),
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
    await saveCurrent(project);
  }

  Future<ProjectDesign?> loadProject(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_savedProjectsKey) ?? [];
    for (final entry in list) {
      final map = jsonDecode(entry) as Map<String, dynamic>;
      if (map['id'] == id) {
        final design = map['design'] as Map<String, dynamic>;
        if (design.containsKey('rooms')) {
          return ProjectDesign.fromJson(design);
        }
        return ProjectDesign(
          projectName: map['name'] as String? ?? 'My Project',
          rooms: [RoomDesign.fromJson(design)],
        );
      }
    }
    return null;
  }

  Future<String?> exportProjectFile(ProjectDesign project) async {
    if (kIsWeb) return null;
    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${dir.path}/exports');
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }
    final file = File(
      '${exportsDir.path}/${project.projectName.replaceAll(' ', '_')}.ispace',
    );
    await file.writeAsString(jsonEncode(project.toJson()));
    return file.path;
  }
}

final projectStorageProvider = Provider<ProjectStorageService>((ref) {
  return ProjectStorageService();
});
