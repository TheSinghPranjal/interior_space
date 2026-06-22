import 'package:uuid/uuid.dart';

import 'apartment_layout.dart';
import 'room_design.dart';

class ProjectDesign {
  const ProjectDesign({
    this.projectName = 'My Project',
    this.rooms = const [],
    this.activeRoomIndex = 0,
    this.apartments = const [],
    this.activeApartmentIndex = 0,
  });

  static const int maxRooms = 30;
  static const int maxApartments = 10;

  final String projectName;
  final List<RoomDesign> rooms;
  final int activeRoomIndex;
  final List<ApartmentLayout> apartments;
  final int activeApartmentIndex;

  List<ApartmentLayout> get apartmentsOrDefault => apartments.isEmpty
      ? [ApartmentLayout.initial(name: 'Apartment 1')]
      : apartments;

  int get safeActiveApartmentIndex =>
      activeApartmentIndex.clamp(0, apartmentsOrDefault.length - 1);

  ApartmentLayout get apartmentLayout =>
      apartmentsOrDefault[safeActiveApartmentIndex];

  List<RoomDesign> get roomsOrDefault =>
      rooms.isEmpty ? [RoomDesign.initial(apartmentIndex: 0)] : rooms;

  List<RoomDesign> roomsForApartment(int apartmentIndex) => roomsOrDefault
      .where((room) => room.apartmentIndex == apartmentIndex)
      .toList();

  List<RoomDesign> get roomsForActiveApartment =>
      roomsForApartment(safeActiveApartmentIndex);

  int get safeActiveIndex =>
      activeRoomIndex.clamp(0, roomsOrDefault.length - 1);

  RoomDesign get activeRoom {
    final active = roomsOrDefault[safeActiveIndex];
    final aptRooms = roomsForActiveApartment;
    if (aptRooms.any((r) => r.id == active.id)) return active;
    if (aptRooms.isEmpty) return roomsOrDefault.first;
    return aptRooms.first;
  }

  bool get canAddRoom => roomsOrDefault.length < maxRooms;

  bool get canRemoveRoom => roomsForActiveApartment.length > 1;

  bool get canAddApartment => apartmentsOrDefault.length < maxApartments;

  bool get canRemoveApartment => apartmentsOrDefault.length > 1;

  RoomDesign? roomById(String id) {
    for (final room in roomsOrDefault) {
      if (room.id == id) return room;
    }
    return null;
  }

  int globalIndexForRoom(RoomDesign room) =>
      roomsOrDefault.indexWhere((r) => r.id == room.id);

  ProjectDesign copyWith({
    String? projectName,
    List<RoomDesign>? rooms,
    int? activeRoomIndex,
    List<ApartmentLayout>? apartments,
    int? activeApartmentIndex,
  }) {
    return ProjectDesign(
      projectName: projectName ?? this.projectName,
      rooms: rooms ?? this.rooms,
      activeRoomIndex: activeRoomIndex ?? this.activeRoomIndex,
      apartments: apartments ?? this.apartments,
      activeApartmentIndex: activeApartmentIndex ?? this.activeApartmentIndex,
    );
  }

  Map<String, dynamic> toJson() => {
        'projectName': projectName,
        'activeRoomIndex': safeActiveIndex,
        'activeApartmentIndex': safeActiveApartmentIndex,
        'rooms': roomsOrDefault.map((r) => r.toJson()).toList(),
        'apartments': apartmentsOrDefault.map((a) => a.toJson()).toList(),
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

      final List<ApartmentLayout> apartments;
      if (json['apartments'] != null) {
        apartments = (json['apartments'] as List<dynamic>)
            .map((e) => ApartmentLayout.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (json['apartmentLayout'] != null) {
        apartments = [
          ApartmentLayout.fromJson(
            json['apartmentLayout'] as Map<String, dynamic>,
          ).copyWith(name: 'Apartment 1'),
        ];
      } else {
        apartments = [ApartmentLayout.initial(name: 'Apartment 1')];
      }

      return ProjectDesign(
        projectName: json['projectName'] as String? ?? 'My Project',
        rooms: rooms.isEmpty
            ? [RoomDesign.initial(id: const Uuid().v4(), apartmentIndex: 0)]
            : rooms,
        activeRoomIndex: (json['activeRoomIndex'] as num?)?.toInt() ?? 0,
        apartments: apartments,
        activeApartmentIndex: (json['activeApartmentIndex'] as num?)?.toInt() ?? 0,
      );
    }

    return ProjectDesign(
      projectName: json['name'] as String? ?? 'My Project',
      rooms: [RoomDesign.fromJson(json, fallbackId: const Uuid().v4())],
      activeRoomIndex: 0,
      apartments: [ApartmentLayout.initial(name: 'Apartment 1')],
    );
  }

  static ProjectDesign initial() {
    return ProjectDesign(
      rooms: [RoomDesign.initial(id: const Uuid().v4(), apartmentIndex: 0)],
      activeRoomIndex: 0,
      apartments: [ApartmentLayout.initial(name: 'Apartment 1')],
      activeApartmentIndex: 0,
    );
  }
}
