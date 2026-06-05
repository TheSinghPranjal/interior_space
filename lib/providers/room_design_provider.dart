import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/ceiling_config.dart';
import '../models/cupboard_config.dart';
import '../models/door_config.dart';
import '../models/enums.dart';
import '../models/floor_config.dart';
import '../models/furniture_item.dart';
import '../models/light_config.dart';
import '../models/room_design.dart';
import '../models/room_dimensions.dart';
import '../models/wall_config.dart';
import '../models/window_config.dart';

final roomDesignProvider =
    StateNotifierProvider<RoomDesignNotifier, RoomDesign>((ref) {
  return RoomDesignNotifier();
});

final cameraModeProvider = StateProvider<CameraMode>((ref) => CameraMode.orbit);

final blueprintModeProvider = StateProvider<bool>((ref) => true);

class RoomDesignNotifier extends StateNotifier<RoomDesign> {
  RoomDesignNotifier() : super(RoomDesign.initial());

  final _uuid = const Uuid();

  void reset() => state = RoomDesign.initial();

  void load(RoomDesign design) => state = design;

  void setName(String name) => state = state.copyWith(name: name);

  void updateDimensions(RoomDimensions dimensions) {
    state = state.copyWith(dimensions: dimensions.clamped());
  }

  void updateWall(WallConfig wall) {
    final walls = [...state.walls];
    final index = walls.indexWhere((w) => w.id == wall.id);
    if (index >= 0) {
      walls[index] = wall;
      state = state.copyWith(walls: walls);
    }
  }

  void updateFloor(FloorConfig floor) => state = state.copyWith(floor: floor);

  void updateCeiling(CeilingConfig ceiling) =>
      state = state.copyWith(ceiling: ceiling);

  void addDoor({WallId wall = WallId.front}) {
    final door = DoorConfig(id: _uuid.v4(), wall: wall);
    state = state.copyWith(doors: [...state.doors, door]);
  }

  void updateDoor(DoorConfig door) {
    state = state.copyWith(
      doors: state.doors.map((d) => d.id == door.id ? door : d).toList(),
    );
  }

  void removeDoor(String id) {
    state = state.copyWith(
      doors: state.doors.where((d) => d.id != id).toList(),
    );
  }

  void addWindow({WallId wall = WallId.front}) {
    final window = WindowConfig(id: _uuid.v4(), wall: wall);
    state = state.copyWith(windows: [...state.windows, window]);
  }

  void updateWindow(WindowConfig window) {
    state = state.copyWith(
      windows:
          state.windows.map((w) => w.id == window.id ? window : w).toList(),
    );
  }

  void removeWindow(String id) {
    state = state.copyWith(
      windows: state.windows.where((w) => w.id != id).toList(),
    );
  }

  void addCupboard() {
    final index = state.cupboards.length;
    final cols = 3;
    final row = index ~/ cols;
    final col = index % cols;
    final bx = 0.22 + col * 0.28;
    final by = 0.28 + row * 0.22;
    final cupboard = CupboardConfig(
      id: _uuid.v4(),
      wall: WallId.left,
      blueprintX: bx.clamp(0.12, 0.88),
      blueprintY: by.clamp(0.12, 0.88),
    );
    state = state.copyWith(cupboards: [...state.cupboards, cupboard]);
  }

  void updateCupboard(CupboardConfig cupboard) {
    state = state.copyWith(
      cupboards: state.cupboards
          .map((c) => c.id == cupboard.id ? cupboard : c)
          .toList(),
    );
  }

  void removeCupboard(String id) {
    state = state.copyWith(
      cupboards: state.cupboards.where((c) => c.id != id).toList(),
    );
  }

  void addLight({LightType type = LightType.ceiling}) {
    final light = LightConfig(id: _uuid.v4(), type: type);
    state = state.copyWith(lights: [...state.lights, light]);
  }

  void updateLight(LightConfig light) {
    state = state.copyWith(
      lights: state.lights.map((l) => l.id == light.id ? light : l).toList(),
    );
  }

  void removeLight(String id) {
    state = state.copyWith(
      lights: state.lights.where((l) => l.id != id).toList(),
    );
  }

  void addFurniture(FurnitureType type) {
    final sameTypeCount = state.furniture.where((f) => f.type == type).length;
    final item = FurnitureItem.defaultForType(
      type,
      _uuid.v4(),
      index: sameTypeCount,
      dimensions: state.dimensions,
    );
    state = state.copyWith(furniture: [...state.furniture, item]);
  }

  void updateFurniture(FurnitureItem item) {
    state = state.copyWith(
      furniture:
          state.furniture.map((f) => f.id == item.id ? item : f).toList(),
    );
  }

  void removeFurniture(String id) {
    state = state.copyWith(
      furniture: state.furniture.where((f) => f.id != id).toList(),
    );
  }

  void applyAiSuggestion(String prompt) {
    final history = [...state.aiPromptHistory, prompt];
    final lower = prompt.toLowerCase();

    if (lower.contains('modern')) {
      state = state.copyWith(
        aiPromptHistory: history,
        walls: state.walls
            .map(
              (w) => w.copyWith(
                surfaceType: SurfaceType.solidColor,
                color: '#F5F5F5',
              ),
            )
            .toList(),
        floor: state.floor.copyWith(
          material: FloorMaterial.porcelain,
          color: '#E0E0E0',
        ),
      );
    } else if (lower.contains('luxury') || lower.contains('bedroom')) {
      state = state.copyWith(
        aiPromptHistory: history,
        walls: state.walls
            .map(
              (w) => w.copyWith(
                surfaceType: SurfaceType.texture,
                texture: WallTexture.marble,
                color: '#FAFAFA',
              ),
            )
            .toList(),
        floor: state.floor.copyWith(
          material: FloorMaterial.marble,
          color: '#EEEEEE',
        ),
        ceiling: state.ceiling.copyWith(
          falseCeilingEnabled: true,
          falseCeilingType: FalseCeilingType.cove,
        ),
      );
    } else {
      state = state.copyWith(aiPromptHistory: history);
    }
  }
}
