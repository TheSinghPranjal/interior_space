import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/walkthrough_settings.dart';

class WalkthroughSettingsNotifier extends StateNotifier<WalkthroughSettings> {
  WalkthroughSettingsNotifier() : super(const WalkthroughSettings()) {
    _load();
  }

  static const _storageKey = 'walkthrough_settings_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    state = WalkthroughSettings.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }

  Future<void> setEyeHeightFt(int feet) async {
    state = state.copyWith(
      eyeHeightFt: feet.clamp(
        WalkthroughSettings.minEyeHeightFt,
        WalkthroughSettings.maxEyeHeightFt,
      ),
    );
    await _persist();
  }
}

final walkthroughSettingsProvider =
    StateNotifierProvider<WalkthroughSettingsNotifier, WalkthroughSettings>(
  (ref) => WalkthroughSettingsNotifier(),
);
