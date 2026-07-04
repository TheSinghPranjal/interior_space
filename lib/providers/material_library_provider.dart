import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/builtin_materials.dart';
import '../models/material_item.dart';

class MaterialLibraryState {
  const MaterialLibraryState({
    this.userMaterials = const [],
    this.isLoaded = false,
  });

  final List<MaterialItem> userMaterials;
  final bool isLoaded;

  List<MaterialItem> get allMaterials => [...builtinMaterials, ...userMaterials];

  MaterialLibraryState copyWith({
    List<MaterialItem>? userMaterials,
    bool? isLoaded,
  }) {
    return MaterialLibraryState(
      userMaterials: userMaterials ?? this.userMaterials,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class MaterialLibraryNotifier extends StateNotifier<MaterialLibraryState> {
  MaterialLibraryNotifier() : super(const MaterialLibraryState());

  static const _userKey = 'user_materials_v1';

  Future<void> load() async {
    if (state.isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    var userMaterials = <MaterialItem>[];
    if (raw != null) {
      userMaterials = (jsonDecode(raw) as List)
          .map((e) => MaterialItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    state = state.copyWith(userMaterials: userMaterials, isLoaded: true);
  }

  List<MaterialItem> byCategory(MaterialCategory category) =>
      state.allMaterials.where((m) => m.category == category).toList();

  List<MaterialItem> search(String query) {
    final q = query.toLowerCase();
    return state.allMaterials
        .where(
          (m) =>
              m.name.toLowerCase().contains(q) ||
              m.subCategory.toLowerCase().contains(q) ||
              MaterialCategory.values[m.category.index].name.contains(q),
        )
        .toList();
  }

  MaterialItem? findByTexturePath(String? path) {
    if (path == null) return null;
    for (final item in state.allMaterials) {
      if (item.filePath == path || item.assetPath == path) return item;
    }
    return null;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _userKey,
      jsonEncode(state.userMaterials.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> addUserMaterial(MaterialItem item) async {
    state = state.copyWith(
      userMaterials: [...state.userMaterials, item],
    );
    await _save();
  }

  Future<void> deleteUserMaterial(String id) async {
    final item = state.userMaterials.firstWhere((m) => m.id == id);
    if (item.filePath != null && !item.filePath!.startsWith('memory://')) {
      final file = File(item.filePath!);
      if (await file.exists()) await file.delete();
    }
    state = state.copyWith(
      userMaterials: state.userMaterials.where((m) => m.id != id).toList(),
    );
    await _save();
  }
}

final materialLibraryProvider =
    StateNotifierProvider<MaterialLibraryNotifier, MaterialLibraryState>((ref) {
  final notifier = MaterialLibraryNotifier();
  notifier.load();
  return notifier;
});
