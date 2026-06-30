import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/polygon_room_geometry.dart';
import '../core/utils/room_geometry.dart';
import '../models/ac_unit_config.dart';
import '../models/ceiling_config.dart';
import '../models/curtain_config.dart';
import '../models/door_config.dart';
import '../models/enums.dart';
import '../models/fan_config.dart';
import '../models/floor_config.dart';
import '../models/furniture_item.dart';
import '../models/light_config.dart';
import '../models/premium_catalog_item.dart';
import '../models/placed_item_config_snapshot.dart';
import '../models/project_design.dart';
import '../models/room_design.dart';
import '../models/room_dimensions.dart';
import '../models/wall_config.dart';
import '../models/wall_tv_unit_config.dart';
import '../models/window_config.dart';
import '../sketch/domain/sketch_models.dart';
import 'project_provider.dart';

final roomDesignProvider =
    StateNotifierProvider<RoomDesignNotifier, RoomDesign>((ref) {
  return RoomDesignNotifier(ref);
});

final cameraModeProvider = StateProvider<CameraMode>((ref) => CameraMode.orbit);

final showWallDimensionLabelsProvider = StateProvider<bool>((ref) => true);

/// When enabled, 3D furniture uses high-detail premium meshes (bed, flower pot, etc.).
final premiumFurnitureProvider = StateProvider<bool>((ref) => false);

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

  void setRoomType(RoomType? roomType) => _mutate(
        (r) => roomType == null
            ? r.copyWith(clearRoomType: true)
            : r.copyWith(roomType: roomType),
      );

  void updateDimensions(RoomDimensions dimensions) {
    _mutate((r) {
      var dims = dimensions.clamped();
      if (dims.useCustomWallLengths) {
        dims = dims.withSyncedCustomWalls();
      }
      return r.copyWith(dimensions: dims);
    });
  }

  void setCustomWallLengthsEnabled(bool enabled) {
    _mutate((r) {
      var dims = r.dimensions;
      if (enabled) {
        dims = dims.withSyncedCustomWalls().copyWith(useCustomWallLengths: true);
      } else {
        dims = dims.copyWith(useCustomWallLengths: false, clearCustomWalls: true);
      }
      return r.copyWith(dimensions: dims.clamped());
    });
  }

  void updateCustomWallLength(WallId wall, double lengthFt) {
    _mutate((r) {
      final dims = r.dimensions;
      final updated = switch (wall) {
        WallId.front => dims.copyWith(customWallFront: lengthFt),
        WallId.back => dims.copyWith(customWallBack: lengthFt),
        WallId.left => dims.copyWith(customWallLeft: lengthFt),
        WallId.right => dims.copyWith(customWallRight: lengthFt),
      };
      return r.copyWith(dimensions: updated.clamped());
    });
  }

  void updateWall(WallConfig wall) {
    _mutate((r) {
      final walls = [...r.walls];
      final index = walls.indexWhere((w) => w.wallIndex == wall.wallIndex);
      if (index >= 0) {
        walls[index] = wall;
        return r.copyWith(walls: walls);
      }
      return r;
    });
  }

  void setPolygonRoom(List<RoomCorner> vertices) {
    final snapped = PolygonRoomGeometry.snapVertices(vertices);
    final error = PolygonRoomGeometry.validate(snapped);
    if (error != null) return;

    final normalized = PolygonRoomGeometry.normalizeToOrigin(snapped);
    final b = PolygonRoomGeometry.bounds(snapped);
    final bboxW = b.maxX - b.minX;
    final bboxL = b.maxY - b.minY;

    _mutate((r) {
      final walls = WallConfig.syncWallCount(r.walls, normalized.length);
      return r.copyWith(
        dimensions: r.dimensions.copyWith(
          shapeMode: RoomShapeMode.polygon,
          polygonVertices: snapped,
          width: bboxW,
          length: bboxL,
          useCustomWallLengths: true,
        ),
        walls: walls,
      );
    });
  }

  void setRectangularRoom() {
    _mutate((r) {
      return r.copyWith(
        dimensions: r.dimensions.copyWith(
          shapeMode: RoomShapeMode.rectangular,
          clearPolygon: true,
          useCustomWallLengths: false,
          clearCustomWalls: true,
        ),
        walls: WallConfig.defaultWalls(),
      );
    });
  }

  void setAllWallsVisibility(double fraction) {
    _mutate((r) {
      final walls = r.walls
          .map((w) => w.copyWith(visibleFraction: fraction.clamp(0.0, 1.0)))
          .toList();
      return r.copyWith(walls: walls);
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

  void addCurtain({WallId wall = WallId.front}) {
    final curtain = CurtainConfig(id: _uuid.v4(), wall: wall);
    _mutate((r) => r.copyWith(curtains: [...r.curtains, curtain]));
  }

  void updateCurtain(CurtainConfig curtain) {
    _mutate(
      (r) => r.copyWith(
        curtains: r.curtains.map((c) => c.id == curtain.id ? curtain : c).toList(),
      ),
    );
  }

  void removeCurtain(String id) {
    _mutate(
      (r) => r.copyWith(curtains: r.curtains.where((c) => c.id != id).toList()),
    );
  }

  void addAcUnit({WallId wall = WallId.front}) {
    final unit = AcUnitConfig(id: _uuid.v4(), wall: wall);
    _mutate((r) => r.copyWith(acUnits: [...r.acUnits, unit]));
  }

  void updateAcUnit(AcUnitConfig unit) {
    _mutate(
      (r) => r.copyWith(
        acUnits: r.acUnits.map((a) => a.id == unit.id ? unit : a).toList(),
      ),
    );
  }

  void removeAcUnit(String id) {
    _mutate(
      (r) => r.copyWith(acUnits: r.acUnits.where((a) => a.id != id).toList()),
    );
  }

  void addWallTvUnit({WallId wall = WallId.front}) {
    final unit = WallTvUnitConfig(id: _uuid.v4(), wall: wall);
    _mutate((r) => r.copyWith(wallTvUnits: [...r.wallTvUnits, unit]));
  }

  void updateWallTvUnit(WallTvUnitConfig unit) {
    _mutate(
      (r) => r.copyWith(
        wallTvUnits: r.wallTvUnits.map((t) => t.id == unit.id ? unit : t).toList(),
      ),
    );
  }

  void removeWallTvUnit(String id) {
    _mutate(
      (r) => r.copyWith(
        wallTvUnits: r.wallTvUnits.where((t) => t.id != id).toList(),
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

  void addFan() {
    final fan = FanConfig(id: _uuid.v4());
    _mutate((r) => r.copyWith(fans: [...r.fans, fan]));
  }

  void updateFan(FanConfig fan) {
    _mutate(
      (r) => r.copyWith(
        fans: r.fans.map((f) => f.id == fan.id ? fan : f).toList(),
      ),
    );
  }

  void removeFan(String id) {
    _mutate(
      (r) => r.copyWith(fans: r.fans.where((f) => f.id != id).toList()),
    );
  }

  void addFurniture(FurnitureType type) {
    _mutate((r) {
      final sameTypeCount = r.furniture.where((f) => f.type == type && !f.isPremiumCatalogItem).length;
      final item = FurnitureItem.defaultForType(
        type,
        _uuid.v4(),
        index: sameTypeCount,
        dimensions: r.dimensions,
      );
      return r.copyWith(furniture: [...r.furniture, item]);
    });
  }

  void addPremiumCatalogItem(PremiumCatalogId catalogId) {
    _mutate((r) {
      final def = catalogId.definition;
      final sameCatalogCount = r.furniture
          .where((f) => f.premiumCatalogId == def.idKey)
          .length;
      final item = FurnitureItem.fromPremiumCatalog(
        def,
        _uuid.v4(),
        index: sameCatalogCount,
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

  /// Applies a copied furniture configuration to [targetId] in the active room.
  bool pasteFurnitureConfig(String targetId, FurnitureConfigSnapshot snapshot) {
    var applied = false;
    _mutate((r) {
      final index = r.furniture.indexWhere((f) => f.id == targetId);
      if (index < 0) return r;
      final target = r.furniture[index];
      if (target.type != snapshot.type) return r;
      final furniture = [...r.furniture];
      furniture[index] = snapshot.applyTo(target, r.dimensions);
      applied = true;
      return r.copyWith(furniture: furniture);
    });
    return applied;
  }

  /// Applies a copied wall TV configuration to [targetId] in the active room.
  bool pasteWallTvConfig(String targetId, WallTvUnitConfigSnapshot snapshot) {
    var applied = false;
    _mutate((r) {
      final index = r.wallTvUnits.indexWhere((u) => u.id == targetId);
      if (index < 0) return r;
      final target = r.wallTvUnits[index];
      final units = [...r.wallTvUnits];
      units[index] = snapshot.applyTo(target, r.dimensions);
      applied = true;
      return r.copyWith(wallTvUnits: units);
    });
    return applied;
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

  void updateSketch(SketchDocument sketch) {
    _mutate((r) => r.copyWith(sketch: sketch));
  }

  final _uuid = const Uuid();
}
