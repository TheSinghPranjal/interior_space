import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/room_constants.dart';
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

  void setActiveApartment(int index) {
    if (index < 0 || index >= state.apartmentsOrDefault.length) return;
    final aptRooms = state.roomsForApartment(index);
    var roomIndex = state.safeActiveIndex;
    if (aptRooms.isNotEmpty) {
      final global = state.globalIndexForRoom(aptRooms.first);
      if (global >= 0) roomIndex = global;
    }
    state = state.copyWith(
      activeApartmentIndex: index,
      activeRoomIndex: roomIndex,
    );
  }

  void addApartment() {
    if (!state.canAddApartment) return;
    final newIndex = state.apartmentsOrDefault.length;
    final newApartment = ApartmentLayout.initial(
      name: 'Apartment ${newIndex + 1}',
    );
    final newRoom = RoomDesign.initial(id: _uuid.v4(), apartmentIndex: newIndex)
        .copyWith(name: 'Room 1');

    state = state.copyWith(
      apartments: [...state.apartmentsOrDefault, newApartment],
      activeApartmentIndex: newIndex,
      rooms: [...state.roomsOrDefault, newRoom],
      activeRoomIndex: state.roomsOrDefault.length,
    );
  }

  void removeApartment(int index) {
    if (!state.canRemoveApartment) return;
    if (index < 0 || index >= state.apartmentsOrDefault.length) return;

    final removedRoomIds =
        state.roomsForApartment(index).map((r) => r.id).toSet();

    var rooms = state.roomsOrDefault
        .where((r) => r.apartmentIndex != index)
        .map((r) => r.apartmentIndex > index
            ? r.copyWith(apartmentIndex: r.apartmentIndex - 1)
            : r)
        .toList();

    var apartments = [...state.apartmentsOrDefault]..removeAt(index);
    apartments = apartments
        .map(
          (apt) => apt.copyWith(
            placements: apt.placements
                .where((p) => !removedRoomIds.contains(p.roomId))
                .toList(),
          ),
        )
        .toList();

    var newActiveApartmentIndex = state.safeActiveApartmentIndex;
    if (index == newActiveApartmentIndex) {
      newActiveApartmentIndex =
          (index > 0 ? index - 1 : 0).clamp(0, apartments.length - 1);
    } else if (index < newActiveApartmentIndex) {
      newActiveApartmentIndex -= 1;
    }

    var activeRoomIndex = 0;
    final aptRooms =
        rooms.where((r) => r.apartmentIndex == newActiveApartmentIndex);
    if (aptRooms.isNotEmpty) {
      activeRoomIndex = rooms.indexWhere((r) => r.id == aptRooms.first.id);
    }

    state = state.copyWith(
      apartments: apartments,
      rooms: rooms,
      activeApartmentIndex: newActiveApartmentIndex,
      activeRoomIndex: activeRoomIndex.clamp(0, rooms.length - 1),
    );
  }

  void setActiveRoom(int index) {
    final aptRooms = state.roomsForActiveApartment;
    if (index < 0 || index >= aptRooms.length) return;
    final globalIndex = state.globalIndexForRoom(aptRooms[index]);
    if (globalIndex < 0) return;
    state = state.copyWith(activeRoomIndex: globalIndex);
  }

  void addRoom() {
    if (!state.canAddRoom) return;
    final aptIndex = state.safeActiveApartmentIndex;
    final aptRoomCount = state.roomsForApartment(aptIndex).length;
    final newRoom = RoomDesign.initial(id: _uuid.v4(), apartmentIndex: aptIndex)
        .copyWith(name: 'Room ${aptRoomCount + 1}');
    final rooms = [...state.roomsOrDefault, newRoom];
    state = state.copyWith(
      rooms: rooms,
      activeRoomIndex: rooms.length - 1,
    );
  }

  void removeRoom(int indexInApartment) {
    if (!state.canRemoveRoom) return;
    final aptRooms = state.roomsForActiveApartment;
    if (indexInApartment < 0 || indexInApartment >= aptRooms.length) return;

    final removedId = aptRooms[indexInApartment].id;
    final removedGlobalIndex = state.globalIndexForRoom(aptRooms[indexInApartment]);
    final rooms = [...state.roomsOrDefault]..removeAt(removedGlobalIndex);

    var newIndex = state.safeActiveIndex;
    if (newIndex >= rooms.length) {
      newIndex = rooms.length - 1;
    } else if (removedGlobalIndex < newIndex) {
      newIndex -= 1;
    }

    final apartments = state.apartmentsOrDefault
        .map(
          (apt) => apt.copyWith(
            placements: apt.placements
                .where((p) => p.roomId != removedId)
                .toList(),
          ),
        )
        .toList();

    state = state.copyWith(
      rooms: rooms,
      activeRoomIndex: newIndex,
      apartments: apartments,
    );
  }

  void resetActiveRoom() {
    updateActiveRoom((room) => RoomDesign.initial(
          id: room.id,
          apartmentIndex: room.apartmentIndex,
        ).copyWith(name: room.name));
  }

  /// Load a room shared from another device into the active room or as a new tab.
  void importSharedRoom(RoomDesign imported, {required bool asNewRoom}) {
    if (asNewRoom) {
      final aptIndex = state.safeActiveApartmentIndex;
      final newRoom = imported.copyWith(
        id: _uuid.v4(),
        apartmentIndex: aptIndex,
        name: _uniqueRoomName(imported.name),
      );
      final rooms = [...state.roomsOrDefault, newRoom];
      state = state.copyWith(
        rooms: rooms,
        activeRoomIndex: rooms.length - 1,
      );
      return;
    }

    final active = state.activeRoom;
    updateActiveRoom(
      (_) => imported.copyWith(
        id: active.id,
        apartmentIndex: active.apartmentIndex,
        name: imported.name.trim().isEmpty ? active.name : imported.name,
      ),
    );
  }

  String _uniqueRoomName(String base) {
    final trimmed = base.trim().isEmpty ? 'Imported Room' : base.trim();
    final names = state.roomsForActiveApartment.map((r) => r.name).toSet();
    if (!names.contains(trimmed)) return trimmed;
    var i = 2;
    while (names.contains('$trimmed ($i)')) {
      i++;
    }
    return '$trimmed ($i)';
  }

  void updateActiveRoom(RoomDesign Function(RoomDesign) update) {
    final rooms = [...state.roomsOrDefault];
    final active = state.activeRoom;
    final index = state.globalIndexForRoom(active);
    if (index < 0) return;
    rooms[index] = update(rooms[index]);
    state = state.copyWith(rooms: rooms);
  }

  void _replaceActiveApartment(ApartmentLayout layout) {
    final apartments = [...state.apartmentsOrDefault];
    apartments[state.safeActiveApartmentIndex] = layout;
    state = state.copyWith(apartments: apartments);
  }

  void addRoomToApartment(String roomId) {
    final room = state.roomById(roomId);
    if (room == null) return;
    if (room.apartmentIndex != state.safeActiveApartmentIndex) return;

    final layout = state.apartmentLayout;
    final count = layout.placements.length;
    final col = count % 3;
    final row = count ~/ 3;
    final placement = ApartmentRoomPlacement(
      id: _uuid.v4(),
      roomId: roomId,
      blueprintX: 0.2 + col * 0.25,
      blueprintY: 0.2 + row * 0.25,
    );

    _replaceActiveApartment(
      layout.copyWith(
        placements: [...layout.placements, placement],
      ),
    );
  }

  void updateApartmentPlacement(ApartmentRoomPlacement placement) {
    final layout = state.apartmentLayout;
    final placements = layout.placements
        .map((p) => p.id == placement.id ? placement : p)
        .toList();
    _replaceActiveApartment(layout.copyWith(placements: placements));
  }

  void setApartmentPlacements(List<ApartmentRoomPlacement> placements) {
    _replaceActiveApartment(
      state.apartmentLayout.copyWith(placements: placements),
    );
  }

  void updateApartmentDimensions({double? widthFt, double? lengthFt}) {
    final old = state.apartmentLayout;
    final newW = (widthFt ?? old.widthFt).clamp(
      RoomConstants.minApartmentWidth,
      RoomConstants.maxApartmentWidth,
    );
    final newL = (lengthFt ?? old.lengthFt).clamp(
      RoomConstants.minApartmentLength,
      RoomConstants.maxApartmentLength,
    );

    final placements = old.placements.map((placement) {
      final absXFt = placement.blueprintX * old.widthFt;
      final absYFt = placement.blueprintY * old.lengthFt;
      return placement.copyWith(
        blueprintX: absXFt / newW,
        blueprintY: absYFt / newL,
      );
    }).toList();

    _replaceActiveApartment(
      ApartmentLayout(
        name: old.name,
        widthFt: newW,
        lengthFt: newL,
        placements: placements,
      ),
    );
  }

  void removeApartmentPlacement(String placementId) {
    final layout = state.apartmentLayout;
    final placements =
        layout.placements.where((p) => p.id != placementId).toList();
    _replaceActiveApartment(layout.copyWith(placements: placements));
  }

  void resetApartmentLayout() {
    final layout = state.apartmentLayout;
    _replaceActiveApartment(
      ApartmentLayout.initial(name: layout.name),
    );
  }
}
