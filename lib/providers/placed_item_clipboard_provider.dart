import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/furniture_item.dart';
import '../models/placed_item_config_snapshot.dart';
import '../models/wall_tv_unit_config.dart';

class PlacedItemClipboardState {
  const PlacedItemClipboardState({
    this.furniture,
    this.wallTv,
  });

  final FurnitureConfigSnapshot? furniture;
  final WallTvUnitConfigSnapshot? wallTv;

  bool canPasteTo(FurnitureType type) => furniture?.type == type;

  bool get hasWallTvClipboard => wallTv != null;
}

final placedItemClipboardProvider =
    StateNotifierProvider<PlacedItemClipboardNotifier, PlacedItemClipboardState>(
  (ref) => PlacedItemClipboardNotifier(),
);

class PlacedItemClipboardNotifier extends StateNotifier<PlacedItemClipboardState> {
  PlacedItemClipboardNotifier() : super(const PlacedItemClipboardState());

  void copyFurniture(FurnitureItem item) {
    state = PlacedItemClipboardState(
      furniture: FurnitureConfigSnapshot.from(item),
      wallTv: state.wallTv,
    );
  }

  void copyWallTv(WallTvUnitConfig unit) {
    state = PlacedItemClipboardState(
      furniture: state.furniture,
      wallTv: WallTvUnitConfigSnapshot.from(unit),
    );
  }
}
