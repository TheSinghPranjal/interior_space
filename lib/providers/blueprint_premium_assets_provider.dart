import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/blueprint_premium_assets.dart';

final blueprintPremiumImagesProvider =
    FutureProvider<BlueprintPremiumImages>((ref) {
  BlueprintPremiumAssets.clearCache();
  return BlueprintPremiumAssets.loadAll();
});
