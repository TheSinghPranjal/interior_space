import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/ceiling_config.dart';
import '../models/cupboard_config.dart';
import '../models/door_config.dart';
import '../models/enums.dart';
import '../models/floor_config.dart';
import '../models/furniture_item.dart';
import '../models/light_config.dart';
import '../models/project_design.dart';
import '../models/room_design.dart';
import '../models/room_dimensions.dart';
import '../models/wall_config.dart';
import '../models/window_config.dart';
import 'project_provider.dart';

final roomDesignProvider =
    StateNotifierProvider<RoomDesignNotifier, RoomDesign>((ref) {
  return RoomDesignNotifier(ref);
});

final cameraModeProvider = StateProvider<CameraMode>((ref) => CameraMode.orbit);

final blueprintModeProvider = StateProvider<bool>((ref) => true);

class RoomDesignNotifier extends StateNotifier<RoomDesign> {
  RoomDesignNotifier(this._ref) : super(_ref.read(projectProvider).activeRoom) {
    _ref.listen<ProjectDesign>(projectProvider, (_, next) {
      state = next.activeRoom;
    });
  }

  final Ref _ref;

  ProjectNotifier get _project => _ref.read(projectProvider.notifier);

  void _mutate(RoomDesign Function(RoomDesign) update) {
    _project.updateActiveRoom(update);
  }

  void reset() => _project.resetActiveRoom();

  void load(RoomDesign design) {
    _project.load(ProjectDesign(rooms: [design]));
  }

  void setName(String name) => _mutate((r) => r.copyWith(name: name));

  void updateDimensions(RoomDimensions dimensions) {
    _mutate((r) => r.copyWith(dimensions: dimensions.clamped()));
  }

  void updateWall(WallConfig wall) {
    _mutate((r) {
      final walls = [...r.walls];
      final index = walls.indexWhere((w) => w.id == wall.id);
      if (index >= 0) {
        walls[index] = wall;
        return r.copyWith(walls: walls);
      }
      return r;
    });
  }

  void updateFloor(FloorConfig floor) =>
      _mutate((r) => r.copyWith(floor: floor));

  void updateCeiling(CeilingConfig ceiling) =>
      _mutate((r) => r.copyWith(ceiling: ceiling));

  void addDoor({WallId wall = WallId.front}) {
    final door = DoorConfig(id: _uuid.v4(), wall: wall);
    _mutate((r) => r.copyWith(doors: [...r.doors, door]));
  }

  void updateDoor(DoorConfig door) {
    _mutate(
      (r) => r.copyWith(
        doors: r.doors.map((d) => d.id == door.id ? door : d).toList(),
      ),
    );
  }

  void removeDoor(String id) {
    _mutate(
      (r) => r.copyWith(doors: r.doors.where((d) => d.id != id).toList()),
    );
  }

  void addWindow({WallId wall = WallId.front}) {
    final window = WindowConfig(id: _uuid.v4(), wall: wall);
    _mutate((r) => r.copyWith(windows: [...r.windows, window]));
  }

  void updateWindow(WindowConfig window) {
    _mutate(
      (r) => r.copyWith(
        windows: r.windows.map((w) => w.id == window.id ? window : w).toList(),
      ),
    );
  }

  void removeWindow(String id) {
    _mutate(
      (r) => r.copyWith(windows: r.windows.where((w) => w.id != id).toList()),
    );
  }

  void addCupboard() {
    _mutate((r) {
      final index = r.cupboards.length;
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
      return r.copyWith(cupboards: [...r.cupboards, cupboard]);
    });
  }

  void updateCupboard(CupboardConfig cupboard) {
    _mutate(
      (r) => r.copyWith(
        cupboards: r.cupboards
            .map((c) => c.id == cupboard.id ? cupboard : c)
            .toList(),
      ),
    );
  }

  void removeCupboard(String id) {
    _mutate(
      (r) => r.copyWith(
        cupboards: r.cupboards.where((c) => c.id != id).toList(),
      ),
    );
  }

  void addLight({LightType type = LightType.ceiling}) {
    final light = LightConfig(id: _uuid.v4(), type: type);
    _mutate((r) => r.copyWith(lights: [...r.lights, light]));
  }

  void updateLight(LightConfig light) {
    _mutate(
      (r) => r.copyWith(
        lights: r.lights.map((l) => l.id == light.id ? light : l).toList(),
      ),
    );
  }

  void removeLight(String id) {
    _mutate(
      (r) => r.copyWith(lights: r.lights.where((l) => l.id != id).toList()),
    );
  }

  void addFurniture(FurnitureType type) {
    _mutate((r) {
      final sameTypeCount = r.furniture.where((f) => f.type == type).length;
      final item = FurnitureItem.defaultForType(
        type,
        _uuid.v4(),
        index: sameTypeCount,
        dimensions: r.dimensions,
      );
      return r.copyWith(furniture: [...r.furniture, item]);
    });
  }

  void updateFurniture(FurnitureItem item) {
    _mutate(
      (r) => r.copyWith(
        furniture: r.furniture.map((f) => f.id == item.id ? item : f).toList(),
      ),
    );
  }

  void removeFurniture(String id) {
    _mutate(
      (r) => r.copyWith(
        furniture: r.furniture.where((f) => f.id != id).toList(),
      ),
    );
  }

  void applyAiSuggestion(String prompt) {
    _mutate((r) {
      final history = [...r.aiPromptHistory, prompt];
      final lower = prompt.toLowerCase();

      if (lower.contains('modern')) {
        return r.copyWith(
          aiPromptHistory: history,
          walls: r.walls
              .map(
                (w) => w.copyWith(
                  surfaceType: SurfaceType.solidColor,
                  color: '#F5F5F5',
                ),
              )
              .toList(),
          floor: r.floor.copyWith(
            material: FloorMaterial.porcelain,
            color: '#E0E0E0',
          ),
        );
      } else if (lower.contains('luxury') || lower.contains('bedroom')) {
        return r.copyWith(
          aiPromptHistory: history,
          walls: r.walls
              .map(
                (w) => w.copyWith(
                  surfaceType: SurfaceType.texture,
                  texture: WallTexture.marble,
                  color: '#FAFAFA',
                ),
              )
              .toList(),
          floor: r.floor.copyWith(
            material: FloorMaterial.marble,
            color: '#EEEEEE',
          ),
          ceiling: r.ceiling.copyWith(
            falseCeilingEnabled: true,
            falseCeilingType: FalseCeilingType.cove,
          ),
        );
      } else {
        return r.copyWith(aiPromptHistory: history);
      }
    });
  }

  final _uuid = const Uuid();
}
