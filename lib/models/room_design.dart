import 'enums.dart';
import 'ceiling_config.dart';
import 'cupboard_config.dart';
import 'door_config.dart';
import 'floor_config.dart';
import 'furniture_item.dart';
import 'light_config.dart';
import 'room_dimensions.dart';
import 'wall_config.dart';
import 'window_config.dart';

class RoomDesign {
  const RoomDesign({
    this.name = 'My Room',
    this.dimensions = const RoomDimensions(),
    this.walls = const [],
    this.floor = const FloorConfig(),
    this.ceiling = const CeilingConfig(),
    this.doors = const [],
    this.windows = const [],
    this.cupboards = const [],
    this.lights = const [],
    this.furniture = const [],
    this.aiPromptHistory = const [],
  });

  final String name;
  final RoomDimensions dimensions;
  final List<WallConfig> walls;
  final FloorConfig floor;
  final CeilingConfig ceiling;
  final List<DoorConfig> doors;
  final List<WindowConfig> windows;
  final List<CupboardConfig> cupboards;
  final List<LightConfig> lights;
  final List<FurnitureItem> furniture;
  final List<String> aiPromptHistory;

  RoomDesign copyWith({
    String? name,
    RoomDimensions? dimensions,
    List<WallConfig>? walls,
    FloorConfig? floor,
    CeilingConfig? ceiling,
    List<DoorConfig>? doors,
    List<WindowConfig>? windows,
    List<CupboardConfig>? cupboards,
    List<LightConfig>? lights,
    List<FurnitureItem>? furniture,
    List<String>? aiPromptHistory,
  }) {
    return RoomDesign(
      name: name ?? this.name,
      dimensions: dimensions ?? this.dimensions,
      walls: walls ?? this.walls,
      floor: floor ?? this.floor,
      ceiling: ceiling ?? this.ceiling,
      doors: doors ?? this.doors,
      windows: windows ?? this.windows,
      cupboards: cupboards ?? this.cupboards,
      lights: lights ?? this.lights,
      furniture: furniture ?? this.furniture,
      aiPromptHistory: aiPromptHistory ?? this.aiPromptHistory,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'room': dimensions.toJson(),
        'walls': walls.map((w) => w.toJson()).toList(),
        'floor': floor.toJson(),
        'ceiling': ceiling.toJson(),
        'doors': doors.map((d) => d.toJson()).toList(),
        'windows': windows.map((w) => w.toJson()).toList(),
        'cupboards': cupboards.map((c) => c.toJson()).toList(),
        'lights': lights.map((l) => l.toJson()).toList(),
        'furniture': furniture.map((f) => f.toJson()).toList(),
        'aiPromptHistory': aiPromptHistory,
      };

  factory RoomDesign.fromJson(Map<String, dynamic> json) {
    return RoomDesign(
      name: json['name'] as String? ?? 'My Room',
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
      cupboards: (json['cupboards'] as List<dynamic>?)
              ?.map((e) => CupboardConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lights: (json['lights'] as List<dynamic>?)
              ?.map((e) => LightConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      furniture: (json['furniture'] as List<dynamic>?)
              ?.map((e) => FurnitureItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      aiPromptHistory: (json['aiPromptHistory'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  static RoomDesign initial() {
    return RoomDesign(
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
