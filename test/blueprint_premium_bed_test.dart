import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:interior_space/core/utils/blueprint_premium_assets.dart';
import 'package:interior_space/models/enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('premium blueprint assets load and decode', () async {
    BlueprintPremiumAssets.clearCache();
    final images = await BlueprintPremiumAssets.loadAll();
    expect(images.bed, isNotNull, reason: 'Bed image failed to decode');
    expect(images.sofa, isNotNull, reason: 'Sofa image failed to decode');
    expect(images.bed!.width, greaterThan(0));
    expect(images.sofa!.height, greaterThan(0));
  });

  test('premium blueprint assets are in bundle', () async {
    for (final path in BlueprintPremiumAssets.assetPaths.values) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(1000), reason: path);
    }
  });

  test('sofa maps to two seater asset', () {
    expect(
      BlueprintPremiumAssets.assetPaths[FurnitureType.sofa],
      BlueprintPremiumAssets.twoSeaterSofaAsset,
    );
  });
}
