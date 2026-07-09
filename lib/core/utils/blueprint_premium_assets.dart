import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../../models/enums.dart';
import '../../models/furniture_item.dart';

/// Loaded premium blueprint sprites keyed by furniture type.
class BlueprintPremiumImages {
  const BlueprintPremiumImages(this._images);

  final Map<FurnitureType, ui.Image> _images;

  ui.Image? forItem(FurnitureItem item) => _images[item.type];

  ui.Image? get bed => _images[FurnitureType.bed];

  ui.Image? get sofa => _images[FurnitureType.sofa];

  ui.Image? get wardrobe => _images[FurnitureType.wardrobe];

  bool get isEmpty => _images.isEmpty;
}

/// Top-down premium blueprint sprites.
abstract final class BlueprintPremiumAssets {
  static const bedTopAsset = 'assets/blueprint/premium_bed_top.png';
  static const twoSeaterSofaAsset = 'assets/blueprint/premium_two_seater_sofa.png';
  static const threeDoorCupboardAsset =
      'assets/blueprint/premium_three_door_cupboard.png';

  static const Map<FurnitureType, String> assetPaths = {
    FurnitureType.bed: bedTopAsset,
    FurnitureType.sofa: twoSeaterSofaAsset,
    FurnitureType.wardrobe: threeDoorCupboardAsset,
  };

  static Future<BlueprintPremiumImages>? _loadFuture;

  static void clearCache() {
    _loadFuture = null;
  }

  static Future<BlueprintPremiumImages> loadAll() {
    return _loadFuture ??= _decodeAll().whenComplete(() {
      _loadFuture = null;
    });
  }

  static Future<BlueprintPremiumImages> _decodeAll() async {
    final images = <FurnitureType, ui.Image>{};

    for (final entry in assetPaths.entries) {
      try {
        final decoded = await _decodeAsset(entry.value);
        if (decoded != null) {
          images[entry.key] = decoded;
          debugPrint(
            'BlueprintPremiumAssets: loaded ${entry.value} '
            '(${decoded.width}x${decoded.height})',
          );
        } else {
          debugPrint(
            'BlueprintPremiumAssets: decode returned null for ${entry.value}',
          );
        }
      } catch (error, stackTrace) {
        debugPrint(
          'BlueprintPremiumAssets: failed to load ${entry.value}: $error',
        );
        debugPrint('$stackTrace');
      }
    }

    return BlueprintPremiumImages(images);
  }

  static Future<ui.Image?> _decodeAsset(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();

    final raster = img.decodeImage(bytes);
    if (raster == null) {
      return _decodeRawBytes(bytes);
    }

    _keyOutDarkBackground(raster);
    final trimmed = _trimTransparent(raster);
    final resized = img.copyResize(
      trimmed,
      width: trimmed.width > 1024 ? 1024 : null,
      height: trimmed.height > 1024 ? 1024 : null,
      maintainAspect: true,
      interpolation: img.Interpolation.linear,
    );

    final pngBytes = img.encodePng(resized);
    return _decodeRawBytes(pngBytes);
  }

  static Future<ui.Image?> _decodeRawBytes(List<int> bytes) async {
    final codec = await ui.instantiateImageCodec(
      Uint8List.fromList(bytes),
    );
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static void _keyOutDarkBackground(img.Image image, {int threshold = 42}) {
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        if (r <= threshold && g <= threshold && b <= threshold) {
          image.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }
  }

  static img.Image _trimTransparent(img.Image image) {
    var minX = image.width;
    var minY = image.height;
    var maxX = 0;
    var maxY = 0;

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        if (image.getPixel(x, y).a.toInt() > 12) {
          minX = minX > x ? x : minX;
          minY = minY > y ? y : minY;
          maxX = maxX < x ? x : maxX;
          maxY = maxY < y ? y : maxY;
        }
      }
    }

    if (maxX <= minX || maxY <= minY) return image;

    return img.copyCrop(
      image,
      x: minX,
      y: minY,
      width: maxX - minX + 1,
      height: maxY - minY + 1,
    );
  }

  static bool shouldDrawPremium({
    required bool premiumFurniture,
    required FurnitureItem item,
    required BlueprintPremiumImages? images,
  }) {
    return premiumFurniture &&
        images != null &&
        images.forItem(item) != null;
  }
}
