import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../models/enums.dart';
import '../../models/furniture_item.dart';

/// Top-down premium blueprint sprites.
abstract final class BlueprintPremiumAssets {
  static const bedTopAsset = 'assets/blueprint/premium_bed_top.png';

  static ui.Image? _bedImage;
  static Future<ui.Image?>? _loadFuture;

  static void clearCache() {
    _bedImage?.dispose();
    _bedImage = null;
    _loadFuture = null;
  }

  static Future<ui.Image?> loadBedImage() {
    if (_bedImage != null) return Future.value(_bedImage);
    return _loadFuture ??= _decodeBedImage();
  }

  static Future<ui.Image?> _decodeBedImage() async {
    try {
      final data = await rootBundle.load(bedTopAsset);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 1024,
      );
      final frame = await codec.getNextFrame();
      _bedImage = frame.image;
      return _bedImage;
    } catch (error, stackTrace) {
      debugPrint('BlueprintPremiumAssets: failed to load bed image: $error');
      debugPrint('$stackTrace');
      clearCache();
      return null;
    }
  }

  static bool isBedItem(FurnitureItem item) => item.type == FurnitureType.bed;

  static bool shouldDrawPremiumBed({
    required bool premiumFurniture,
    required FurnitureItem item,
    required ui.Image? bedImage,
  }) {
    return premiumFurniture && isBedItem(item) && bedImage != null;
  }
}
