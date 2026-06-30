import 'curtain_config.dart';
import '../sketch/domain/sketch_models.dart';
import 'enums.dart';
import 'ac_unit_config.dart';
import 'ceiling_config.dart';
import 'cupboard_config.dart';
import 'door_config.dart';
import 'fan_config.dart';
import 'floor_config.dart';
import 'furniture_item.dart';
import 'light_config.dart';
import 'room_dimensions.dart';
import 'wall_config.dart';
import 'wall_tv_unit_config.dart';
import 'window_config.dart';

class RoomDesign {
  const RoomDesign({
    required this.id,
    this.name = 'My Room',
    this.roomType,
    this.apartmentIndex = 0,
    this.dimensions = const RoomDimensions(),
    this.walls = const [],
    this.floor = const FloorConfig(),
    this.ceiling = const CeilingConfig(),
    this.doors = const [],
    this.windows = const [],
    this.curtains = const [],
    this.acUnits = const [],
    this.wallTvUnits = const [],
    this.cupboards = const [],
    this.lights = const [],
    this.fans = const [],
    this.furniture = const [],
    this.aiPromptHistory = const [],
    this.sketch = const SketchDocument(),
  });

  final String id;
  final String name;
  final RoomType? roomType;
  final int apartmentIndex;
  final RoomDimensions dimensions;
  final List<WallConfig> walls;
  final FloorConfig floor;
  final CeilingConfig ceiling;
  final List<DoorConfig> doors;
  final List<WindowConfig> windows;
  final List<CurtainConfig> curtains;
  final List<AcUnitConfig> acUnits;
  final List<WallTvUnitConfig> wallTvUnits;
  final List<CupboardConfig> cupboards;
  final List<LightConfig> lights;
  final List<FanConfig> fans;
  final List<FurnitureItem> furniture;
  final List<String> aiPromptHistory;
  final SketchDocument sketch;

  RoomDesign copyWith({
    String? id,
    String? name,
    RoomType? roomType,
    bool clearRoomType = false,
    int? apartmentIndex,
    RoomDimensions? dimensions,
    List<WallConfig>? walls,
    FloorConfig? floor,
    CeilingConfig? ceiling,
    List<DoorConfig>? doors,
    List<WindowConfig>? windows,
    List<CurtainConfig>? curtains,
    List<AcUnitConfig>? acUnits,
    List<WallTvUnitConfig>? wallTvUnits,
    List<CupboardConfig>? cupboards,
    List<LightConfig>? lights,
    List<FanConfig>? fans,
    List<FurnitureItem>? furniture,
    List<String>? aiPromptHistory,
    SketchDocument? sketch,
  }) {
    return RoomDesign(
      id: id ?? this.id,
      name: name ?? this.name,
      roomType: clearRoomType ? null : (roomType ?? this.roomType),
      apartmentIndex: apartmentIndex ?? this.apartmentIndex,
      dimensions: dimensions ?? this.dimensions,
      walls: walls ?? this.walls,
      floor: floor ?? this.floor,
      ceiling: ceiling ?? this.ceiling,
      doors: doors ?? this.doors,
      windows: windows ?? this.windows,
      curtains: curtains ?? this.curtains,
      acUnits: acUnits ?? this.acUnits,
      wallTvUnits: wallTvUnits ?? this.wallTvUnits,
      cupboards: cupboards ?? this.cupboards,
      lights: lights ?? this.lights,
      fans: fans ?? this.fans,
      furniture: furniture ?? this.furniture,
      aiPromptHistory: aiPromptHistory ?? this.aiPromptHistory,
      sketch: sketch ?? this.sketch,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (roomType != null) 'roomType': roomType!.name,
        'apartmentIndex': apartmentIndex,
        'room': dimensions.toJson(),
        'walls': walls.map((w) => w.toJson()).toList(),
        'floor': floor.toJson(),
        'ceiling': ceiling.toJson(),
        'doors': doors.map((d) => d.toJson()).toList(),
        'windows': windows.map((w) => w.toJson()).toList(),
        'curtains': curtains.map((c) => c.toJson()).toList(),
        'acUnits': acUnits.map((a) => a.toJson()).toList(),
        'wallTvUnits': wallTvUnits.map((t) => t.toJson()).toList(),
        'cupboards': cupboards.map((c) => c.toJson()).toList(),
        'lights': lights.map((l) => l.toJson()).toList(),
        'fans': fans.map((f) => f.toJson()).toList(),
        'furniture': furniture.map((f) => f.toJson()).toList(),
        'aiPromptHistory': aiPromptHistory,
        'sketch': sketch.toJson(),
      };

  factory RoomDesign.fromJson(Map<String, dynamic> json, {String? fallbackId}) {
    final legacyCupboards = (json['cupboards'] as List<dynamic>?)
            ?.map((e) => CupboardConfig.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    var furniture = (json['furniture'] as List<dynamic>?)
            ?.map((e) => FurnitureItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    if (legacyCupboards.isNotEmpty) {
      furniture = [
        ...furniture,
        ...legacyCupboards.map(
          (c) => FurnitureItem(
            id: c.id,
            type: FurnitureType.wardrobe,
            width: c.width,
            height: c.height,
            depth: c.depth,
            rotation: c.rotation,
            blueprintX: c.blueprintX,
            blueprintY: c.blueprintY,
            color: c.color,
            texturePath: c.texturePath,
            variant: c.texture.name,
          ),
        ),
      ];
    }

    return RoomDesign(
      id: json['id'] as String? ?? fallbackId ?? 'room-default',
      name: json['name'] as String? ?? 'My Room',
      roomType: _roomTypeFromJson(json['roomType']),
      apartmentIndex: (json['apartmentIndex'] as num?)?.toInt() ?? 0,
      dimensions: RoomDimensions.fromJson(
        (json['room'] as Map<String, dynamic>?) ?? {},
      ),
      walls: (json['walls'] as List<dynamic>?)
              ?.map((e) => WallConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          WallConfig.defaultWalls(),
      floor: FloorConfig.fromJson(
        (json['floor'] as Map<String, dynamic>?) ?? {},
      ),
      ceiling: CeilingConfig.fromJson(
        (json['ceiling'] as Map<String, dynamic>?) ?? {},
      ),
      doors: (json['doors'] as List<dynamic>?)
              ?.map((e) => DoorConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      windows: (json['windows'] as List<dynamic>?)
              ?.map((e) => WindowConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      curtains: (json['curtains'] as List<dynamic>?)
              ?.map((e) => CurtainConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      acUnits: (json['acUnits'] as List<dynamic>?)
              ?.map((e) => AcUnitConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      wallTvUnits: (json['wallTvUnits'] as List<dynamic>?)
              ?.map((e) => WallTvUnitConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      cupboards: const [],
      lights: (json['lights'] as List<dynamic>?)
              ?.map((e) => LightConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      fans: (json['fans'] as List<dynamic>?)
              ?.map((e) => FanConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      furniture: furniture,
      aiPromptHistory: (json['aiPromptHistory'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      sketch: SketchDocument.fromJson(json['sketch'] as Map<String, dynamic>?),
    );
  }

  static RoomType? _roomTypeFromJson(dynamic value) {
    if (value == null) return null;
    final name = value as String;
    for (final type in RoomType.values) {
      if (type.name == name) return type;
    }
    return null;
  }

  static RoomDesign initial({String? id, int apartmentIndex = 0}) {
    return RoomDesign(
      id: id ?? 'room-default',
      apartmentIndex: apartmentIndex,
      walls: WallConfig.defaultWalls(),
      lights: [
        LightConfig(
          id: 'default-light',
          type: LightType.ceiling,
          positionX: 0.5,
          positionY: 0.5,
          positionZ: 0.95,
          brightness: 1.2,
        ),
      ],
    );
  }
}
