import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project_design.dart';
import '../models/room_design.dart';

final projectProvider =
    StateNotifierProvider<ProjectNotifier, ProjectDesign>((ref) {
  return ProjectNotifier();
});

class ProjectNotifier extends StateNotifier<ProjectDesign> {
  ProjectNotifier() : super(ProjectDesign.initial());

  void load(ProjectDesign project) => state = project;

  void resetAll() => state = ProjectDesign.initial();

  void setActiveRoom(int index) {
    if (index < 0 || index >= state.roomsOrDefault.length) return;
    state = state.copyWith(activeRoomIndex: index);
  }

  void addRoom() {
    if (!state.canAddRoom) return;
    final roomNumber = state.roomsOrDefault.length + 1;
    final newRoom = RoomDesign.initial().copyWith(name: 'Room $roomNumber');
    final rooms = [...state.roomsOrDefault, newRoom];
    state = state.copyWith(
      rooms: rooms,
      activeRoomIndex: rooms.length - 1,
    );
  }

  void removeRoom(int index) {
    if (!state.canRemoveRoom) return;
    if (index < 0 || index >= state.roomsOrDefault.length) return;

    final rooms = [...state.roomsOrDefault]..removeAt(index);
    var newIndex = state.safeActiveIndex;
    if (newIndex >= rooms.length) {
      newIndex = rooms.length - 1;
    } else if (index < newIndex) {
      newIndex -= 1;
    }

    state = state.copyWith(
      rooms: rooms,
      activeRoomIndex: newIndex,
    );
  }

  void resetActiveRoom() {
    updateActiveRoom((_) => RoomDesign.initial());
  }

  void updateActiveRoom(RoomDesign Function(RoomDesign) update) {
    final rooms = [...state.roomsOrDefault];
    final index = state.safeActiveIndex;
    rooms[index] = update(rooms[index]);
    state = state.copyWith(rooms: rooms);
  }
}
