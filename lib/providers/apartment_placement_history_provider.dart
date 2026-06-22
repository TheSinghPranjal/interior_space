import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/apartment_layout.dart';
import 'project_provider.dart';

class ApartmentPlacementHistoryState {
  const ApartmentPlacementHistoryState({
    this.canUndo = false,
    this.canRedo = false,
  });

  final bool canUndo;
  final bool canRedo;

  ApartmentPlacementHistoryState copyWith({bool? canUndo, bool? canRedo}) {
    return ApartmentPlacementHistoryState(
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
    );
  }
}

class ApartmentPlacementHistoryNotifier
    extends StateNotifier<ApartmentPlacementHistoryState> {
  ApartmentPlacementHistoryNotifier(this.ref)
      : super(const ApartmentPlacementHistoryState());

  final Ref ref;
  final _undoStack = <List<ApartmentRoomPlacement>>[];
  final _redoStack = <List<ApartmentRoomPlacement>>[];

  static const _maxDepth = 50;

  List<ApartmentRoomPlacement> _copy(List<ApartmentRoomPlacement> placements) =>
      placements.map((p) => p.copyWith()).toList();

  void _syncState() {
    state = ApartmentPlacementHistoryState(
      canUndo: _undoStack.isNotEmpty,
      canRedo: _redoStack.isNotEmpty,
    );
  }

  void recordBeforeChange() {
    final placements = ref.read(projectProvider).apartmentLayout.placements;
    _undoStack.add(_copy(placements));
    if (_undoStack.length > _maxDepth) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    _syncState();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final current = ref.read(projectProvider).apartmentLayout.placements;
    _redoStack.add(_copy(current));
    final previous = _undoStack.removeLast();
    ref.read(projectProvider.notifier).setApartmentPlacements(previous);
    _syncState();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final current = ref.read(projectProvider).apartmentLayout.placements;
    _undoStack.add(_copy(current));
    final next = _redoStack.removeLast();
    ref.read(projectProvider.notifier).setApartmentPlacements(next);
    _syncState();
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _syncState();
  }
}

final apartmentPlacementHistoryProvider = StateNotifierProvider<
    ApartmentPlacementHistoryNotifier, ApartmentPlacementHistoryState>((ref) {
  return ApartmentPlacementHistoryNotifier(ref);
});
