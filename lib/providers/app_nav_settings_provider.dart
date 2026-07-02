import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_nav_settings.dart';

class AppNavSettingsNotifier extends StateNotifier<AppNavSettings> {
  AppNavSettingsNotifier() : super(const AppNavSettings()) {
    _load();
  }

  static const _storageKey = 'app_nav_settings_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    state = AppNavSettings.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }

  Future<void> setShowSketchTab(bool value) async {
    state = state.copyWith(showSketchTab: value);
    await _persist();
  }

  Future<void> setShowAiAssistTab(bool value) async {
    state = state.copyWith(showAiAssistTab: value);
    await _persist();
  }
}

final appNavSettingsProvider =
    StateNotifierProvider<AppNavSettingsNotifier, AppNavSettings>((ref) {
  return AppNavSettingsNotifier();
});
