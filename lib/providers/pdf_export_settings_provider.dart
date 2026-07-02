import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pdf_export_settings.dart';

class PdfExportSettingsNotifier extends StateNotifier<PdfExportSettings> {
  PdfExportSettingsNotifier() : super(const PdfExportSettings()) {
    _load();
  }

  static const _storageKey = 'pdf_export_settings_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    state = PdfExportSettings.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }

  Future<void> setInclude3dPreview(bool value) async {
    state = state.copyWith(include3dPreview: value);
    await _persist();
  }

  Future<void> setIncludeFrontView(bool value) async {
    if (!value && !state.includeTopView && state.include3dPreview) {
      state = state.copyWith(includeFrontView: false, includeTopView: true);
    } else {
      state = state.copyWith(includeFrontView: value);
    }
    await _persist();
  }

  Future<void> setIncludeTopView(bool value) async {
    if (!value && !state.includeFrontView && state.include3dPreview) {
      state = state.copyWith(includeTopView: false, includeFrontView: true);
    } else {
      state = state.copyWith(includeTopView: value);
    }
    await _persist();
  }

  Future<void> setIncludeSketchInPdf(bool value) async {
    state = state.copyWith(includeSketchInPdf: value);
    await _persist();
  }
}

final pdfExportSettingsProvider =
    StateNotifierProvider<PdfExportSettingsNotifier, PdfExportSettings>((ref) {
  return PdfExportSettingsNotifier();
});
