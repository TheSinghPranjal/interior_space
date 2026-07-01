import '../core/constants/room_constants.dart';
import '../sketch/domain/sketch_models.dart';
import 'apartment_details.dart';

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
    this.name = 'Apartment 1',
    this.widthFt = 60,
    this.lengthFt = 60,
    this.placements = const [],
    this.sketch = const SketchDocument(),
    this.details = const ApartmentDetails(),
  });

  final String name;
  final double widthFt;
  final double lengthFt;
  final List<ApartmentRoomPlacement> placements;
  final SketchDocument sketch;
  final ApartmentDetails details;

  ApartmentLayout copyWith({
    String? name,
    double? widthFt,
    double? lengthFt,
    List<ApartmentRoomPlacement>? placements,
    SketchDocument? sketch,
    ApartmentDetails? details,
  }) {
    return ApartmentLayout(
      name: name ?? this.name,
      widthFt: widthFt ?? this.widthFt,
      lengthFt: lengthFt ?? this.lengthFt,
      placements: placements ?? this.placements,
      sketch: sketch ?? this.sketch,
      details: details ?? this.details,
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
        'name': name,
        'widthFt': widthFt,
        'lengthFt': lengthFt,
        'placements': placements.map((p) => p.toJson()).toList(),
        'sketch': sketch.toJson(),
        if (details.hasAny) 'details': details.toJson(),
      };

  factory ApartmentLayout.fromJson(Map<String, dynamic> json) {
    return ApartmentLayout(
      name: json['name'] as String? ?? 'Apartment 1',
      widthFt: (json['widthFt'] as num?)?.toDouble() ?? 60,
      lengthFt: (json['lengthFt'] as num?)?.toDouble() ?? 60,
      placements: (json['placements'] as List<dynamic>?)
              ?.map((e) => ApartmentRoomPlacement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sketch: SketchDocument.fromJson(json['sketch'] as Map<String, dynamic>?),
      details: ApartmentDetails.fromJson(json['details'] as Map<String, dynamic>?),
    );
  }

  static ApartmentLayout initial({String name = 'Apartment 1'}) =>
      ApartmentLayout(name: name);
}
