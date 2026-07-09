import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:interior_space/core/utils/blueprint_premium_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('premium bed asset loads and decodes', () async {
    BlueprintPremiumAssets.clearCache();
    final image = await BlueprintPremiumAssets.loadBedImage();
    expect(image, isNotNull, reason: 'Bed image failed to decode');
    expect(image!.width, greaterThan(0));
    expect(image.height, greaterThan(0));
  });

  test('premium bed asset is in bundle', () async {
    final data = await rootBundle.load(BlueprintPremiumAssets.bedTopAsset);
    expect(data.lengthInBytes, greaterThan(1000));
  });
}
