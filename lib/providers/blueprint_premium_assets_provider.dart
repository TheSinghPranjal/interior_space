import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/blueprint_premium_assets.dart';

final blueprintPremiumBedImageProvider = FutureProvider<ui.Image?>((ref) {
  BlueprintPremiumAssets.clearCache();
  return BlueprintPremiumAssets.loadBedImage();
});
