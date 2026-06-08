import 'package:uuid/uuid.dart';

import 'apartment_layout.dart';
import 'room_design.dart';

class ProjectDesign {
  const ProjectDesign({
    this.projectName = 'My Project',
    this.rooms = const [],
    this.activeRoomIndex = 0,
    this.apartmentLayout = const ApartmentLayout(),
  });

  static const int maxRooms = 10;

  final String projectName;
  final List<RoomDesign> rooms;
  final int activeRoomIndex;
  final ApartmentLayout apartmentLayout;

  List<RoomDesign> get roomsOrDefault =>
      rooms.isEmpty ? [RoomDesign.initial()] : rooms;

  int get safeActiveIndex =>
      activeRoomIndex.clamp(0, roomsOrDefault.length - 1);

  RoomDesign get activeRoom => roomsOrDefault[safeActiveIndex];

  bool get canAddRoom => roomsOrDefault.length < maxRooms;

  bool get canRemoveRoom => roomsOrDefault.length > 1;

  RoomDesign? roomById(String id) {
    for (final room in roomsOrDefault) {
      if (room.id == id) return room;
    }
    return null;
  }

  ProjectDesign copyWith({
    String? projectName,
    List<RoomDesign>? rooms,
    int? activeRoomIndex,
    ApartmentLayout? apartmentLayout,
  }) {
    return ProjectDesign(
      projectName: projectName ?? this.projectName,
      rooms: rooms ?? this.rooms,
      activeRoomIndex: activeRoomIndex ?? this.activeRoomIndex,
      apartmentLayout: apartmentLayout ?? this.apartmentLayout,
    );
  }

  Map<String, dynamic> toJson() => {
        'projectName': projectName,
        'activeRoomIndex': safeActiveIndex,
        'rooms': roomsOrDefault.map((r) => r.toJson()).toList(),
        'apartmentLayout': apartmentLayout.toJson(),
      };

  factory ProjectDesign.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('rooms')) {
      final rooms = (json['rooms'] as List<dynamic>).asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value as Map<String, dynamic>;
        return RoomDesign.fromJson(
          data,
          fallbackId: data['id'] as String? ?? 'room-$index',
        );
      }).toList();
      return ProjectDesign(
        projectName: json['projectName'] as String? ?? 'My Project',
        rooms: rooms.isEmpty ? [RoomDesign.initial(id: const Uuid().v4())] : rooms,
        activeRoomIndex: (json['activeRoomIndex'] as num?)?.toInt() ?? 0,
        apartmentLayout: json['apartmentLayout'] != null
            ? ApartmentLayout.fromJson(json['apartmentLayout'] as Map<String, dynamic>)
            : const ApartmentLayout(),
      );
    }

    return ProjectDesign(
      projectName: json['name'] as String? ?? 'My Project',
      rooms: [RoomDesign.fromJson(json, fallbackId: const Uuid().v4())],
      activeRoomIndex: 0,
    );
  }

  static ProjectDesign initial() {
    return ProjectDesign(
      rooms: [RoomDesign.initial(id: const Uuid().v4())],
      activeRoomIndex: 0,
    );
  }
}
