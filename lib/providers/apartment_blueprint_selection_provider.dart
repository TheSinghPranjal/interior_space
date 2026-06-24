import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApartmentBlueprintSelectionNotifier extends StateNotifier<Set<String>> {
  ApartmentBlueprintSelectionNotifier() : super({});

  void selectOne(String id) => state = {id};

  void selectAll(Iterable<String> ids) {
    final all = ids.toSet();
    if (all.isEmpty) {
      state = {};
      return;
    }
    if (state.length == all.length && all.every(state.contains)) {
      state = {};
    } else {
      state = all;
    }
  }

  void clear() => state = {};

  void pruneMissing(Iterable<String> validIds) {
    final valid = validIds.toSet();
    final next = state.where(valid.contains).toSet();
    if (next.length != state.length) {
      state = next;
    }
  }
}

final apartmentBlueprintSelectionProvider =
    StateNotifierProvider<ApartmentBlueprintSelectionNotifier, Set<String>>(
  (ref) => ApartmentBlueprintSelectionNotifier(),
);
