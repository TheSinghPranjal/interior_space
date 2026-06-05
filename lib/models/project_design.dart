import 'room_design.dart';

class ProjectDesign {
  const ProjectDesign({
    this.projectName = 'My Project',
    this.rooms = const [],
    this.activeRoomIndex = 0,
  });

  static const int maxRooms = 10;

  final String projectName;
  final List<RoomDesign> rooms;
  final int activeRoomIndex;

  List<RoomDesign> get roomsOrDefault =>
      rooms.isEmpty ? [RoomDesign.initial()] : rooms;

  int get safeActiveIndex =>
      activeRoomIndex.clamp(0, roomsOrDefault.length - 1);

  RoomDesign get activeRoom => roomsOrDefault[safeActiveIndex];

  bool get canAddRoom => roomsOrDefault.length < maxRooms;

  bool get canRemoveRoom => roomsOrDefault.length > 1;

  ProjectDesign copyWith({
    String? projectName,
    List<RoomDesign>? rooms,
    int? activeRoomIndex,
  }) {
    return ProjectDesign(
      projectName: projectName ?? this.projectName,
      rooms: rooms ?? this.rooms,
      activeRoomIndex: activeRoomIndex ?? this.activeRoomIndex,
    );
  }

  Map<String, dynamic> toJson() => {
        'projectName': projectName,
        'activeRoomIndex': safeActiveIndex,
        'rooms': roomsOrDefault.map((r) => r.toJson()).toList(),
      };

  factory ProjectDesign.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('rooms')) {
      final rooms = (json['rooms'] as List<dynamic>)
          .map((e) => RoomDesign.fromJson(e as Map<String, dynamic>))
          .toList();
      return ProjectDesign(
        projectName: json['projectName'] as String? ?? 'My Project',
        rooms: rooms.isEmpty ? [RoomDesign.initial()] : rooms,
        activeRoomIndex: (json['activeRoomIndex'] as num?)?.toInt() ?? 0,
      );
    }

    return ProjectDesign(
      projectName: json['name'] as String? ?? 'My Project',
      rooms: [RoomDesign.fromJson(json)],
      activeRoomIndex: 0,
    );
  }

  static ProjectDesign initial() {
    return ProjectDesign(
      rooms: [RoomDesign.initial()],
      activeRoomIndex: 0,
    );
  }
}
