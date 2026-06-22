import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/blueprint_placement.dart';
import '../models/apartment_layout.dart';
import '../models/project_design.dart';
import '../models/room_design.dart';

final projectProvider =
    StateNotifierProvider<ProjectNotifier, ProjectDesign>((ref) {
  return ProjectNotifier();
});

class ProjectNotifier extends StateNotifier<ProjectDesign> {
  ProjectNotifier() : super(ProjectDesign.initial());

  static const _uuid = Uuid();

  void load(ProjectDesign project) => state = project;

  void resetAll() => state = ProjectDesign.initial();

  void setActiveRoom(int index) {
    if (index < 0 || index >= state.roomsOrDefault.length) return;
    state = state.copyWith(activeRoomIndex: index);
  }

  void addRoom() {
    if (!state.canAddRoom) return;
    final roomNumber = state.roomsOrDefault.length + 1;
    final newRoom = RoomDesign.initial(id: _uuid.v4()).copyWith(name: 'Room $roomNumber');
    final rooms = [...state.roomsOrDefault, newRoom];
    state = state.copyWith(
      rooms: rooms,
      activeRoomIndex: rooms.length - 1,
    );
  }

  void removeRoom(int index) {
    if (!state.canRemoveRoom) return;
    if (index < 0 || index >= state.roomsOrDefault.length) return;

    final removedId = state.roomsOrDefault[index].id;
    final rooms = [...state.roomsOrDefault]..removeAt(index);
    var newIndex = state.safeActiveIndex;
    if (newIndex >= rooms.length) {
      newIndex = rooms.length - 1;
    } else if (index < newIndex) {
      newIndex -= 1;
    }

    final placements = state.apartmentLayout.placements
        .where((p) => p.roomId != removedId)
        .toList();

    state = state.copyWith(
      rooms: rooms,
      activeRoomIndex: newIndex,
      apartmentLayout: state.apartmentLayout.copyWith(placements: placements),
    );
  }

  void resetActiveRoom() {
    updateActiveRoom((room) => RoomDesign.initial(id: room.id).copyWith(name: room.name));
  }

  void updateActiveRoom(RoomDesign Function(RoomDesign) update) {
    final rooms = [...state.roomsOrDefault];
    final index = state.safeActiveIndex;
    rooms[index] = update(rooms[index]);
    state = state.copyWith(rooms: rooms);
  }

  void addRoomToApartment(String roomId) {
    final room = state.roomById(roomId);
    if (room == null) return;

    final count = state.apartmentLayout.placements.length;
    final col = count % 3;
    final row = count ~/ 3;
    final placement = ApartmentRoomPlacement(
      id: _uuid.v4(),
      roomId: roomId,
      blueprintX: 0.2 + col * 0.25,
      blueprintY: 0.2 + row * 0.25,
    );

    state = state.copyWith(
      apartmentLayout: state.apartmentLayout.copyWith(
        placements: [...state.apartmentLayout.placements, placement],
      ),
    );
  }

  void updateApartmentPlacement(ApartmentRoomPlacement placement) {
    final placements = state.apartmentLayout.placements
        .map((p) => p.id == placement.id ? placement : p)
        .toList();
    state = state.copyWith(
      apartmentLayout: state.apartmentLayout.copyWith(placements: placements),
    );
  }

  void updateApartmentDimensions({double? widthFt, double? lengthFt}) {
    var layout = state.apartmentLayout
        .copyWith(widthFt: widthFt, lengthFt: lengthFt)
        .clamped();

    final placements = layout.placements.map((placement) {
      final room = state.roomById(placement.roomId);
      if (room == null) return placement;

      final clamped = BlueprintPlacement.clampBlueprintCenter(
        centerXNorm: placement.blueprintX,
        centerYNorm: placement.blueprintY,
        widthFt: room.dimensions.width,
        depthFt: room.dimensions.length,
        rotationDeg: placement.rotation,
        roomWidthFt: layout.widthFt,
        roomLengthFt: layout.lengthFt,
      );
      return placement.copyWith(
        blueprintX: clamped.bx,
        blueprintY: clamped.by,
      );
    }).toList();

    layout = layout.copyWith(placements: placements);
    state = state.copyWith(apartmentLayout: layout);
  }

  void removeApartmentPlacement(String placementId) {
    final placements = state.apartmentLayout.placements
        .where((p) => p.id != placementId)
        .toList();
    state = state.copyWith(
      apartmentLayout: state.apartmentLayout.copyWith(placements: placements),
    );
  }

  void resetApartmentLayout() {
    state = state.copyWith(
      apartmentLayout: ApartmentLayout.initial(),
    );
  }
}
