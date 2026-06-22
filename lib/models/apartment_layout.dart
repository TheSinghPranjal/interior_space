import '../core/constants/room_constants.dart';

class ApartmentRoomPlacement {
  const ApartmentRoomPlacement({
    required this.id,
    required this.roomId,
    this.blueprintX = 0.5,
    this.blueprintY = 0.5,
    this.rotation = 0,
  });

  final String id;
  final String roomId;
  final double blueprintX;
  final double blueprintY;
  final double rotation;

  ApartmentRoomPlacement copyWith({
    String? roomId,
    double? blueprintX,
    double? blueprintY,
    double? rotation,
  }) {
    return ApartmentRoomPlacement(
      id: id,
      roomId: roomId ?? this.roomId,
      blueprintX: blueprintX ?? this.blueprintX,
      blueprintY: blueprintY ?? this.blueprintY,
      rotation: rotation ?? this.rotation,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'blueprintX': blueprintX,
        'blueprintY': blueprintY,
        'rotation': rotation,
      };

  factory ApartmentRoomPlacement.fromJson(Map<String, dynamic> json) {
    return ApartmentRoomPlacement(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      blueprintX: (json['blueprintX'] as num?)?.toDouble() ?? 0.5,
      blueprintY: (json['blueprintY'] as num?)?.toDouble() ?? 0.5,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ApartmentLayout {
  const ApartmentLayout({
    this.widthFt = 60,
    this.lengthFt = 60,
    this.placements = const [],
  });

  final double widthFt;
  final double lengthFt;
  final List<ApartmentRoomPlacement> placements;

  ApartmentLayout copyWith({
    double? widthFt,
    double? lengthFt,
    List<ApartmentRoomPlacement>? placements,
  }) {
    return ApartmentLayout(
      widthFt: widthFt ?? this.widthFt,
      lengthFt: lengthFt ?? this.lengthFt,
      placements: placements ?? this.placements,
    );
  }

  ApartmentLayout clamped() {
    return copyWith(
      widthFt: widthFt.clamp(
        RoomConstants.minApartmentWidth,
        RoomConstants.maxApartmentWidth,
      ),
      lengthFt: lengthFt.clamp(
        RoomConstants.minApartmentLength,
        RoomConstants.maxApartmentLength,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'widthFt': widthFt,
        'lengthFt': lengthFt,
        'placements': placements.map((p) => p.toJson()).toList(),
      };

  factory ApartmentLayout.fromJson(Map<String, dynamic> json) {
    return ApartmentLayout(
      widthFt: (json['widthFt'] as num?)?.toDouble() ?? 60,
      lengthFt: (json['lengthFt'] as num?)?.toDouble() ?? 60,
      placements: (json['placements'] as List<dynamic>?)
              ?.map((e) => ApartmentRoomPlacement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static ApartmentLayout initial() => const ApartmentLayout();
}
