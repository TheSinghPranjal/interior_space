import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/polygon_room_geometry.dart';
import '../core/utils/room_geometry.dart';
import '../models/enums.dart';
import '../models/project_design.dart';
import '../models/room_design.dart';
import 'texture_service.dart';

class ApartmentSceneBuilder {
  ApartmentSceneBuilder(this._roomSceneBuilder);

  final RoomSceneBuilder _roomSceneBuilder;

  Future<String> buildSceneJson(
    ProjectDesign project, {
    bool showWallDimensionLabels = true,
    bool premiumFurniture = false,
  }) async {
    final layout = project.apartmentLayout;
    final rooms = layout.placements
        .map((p) => project.roomById(p.roomId))
        .whereType<RoomDesign>()
        .toList();

    final sharedTextures = await _roomSceneBuilder.buildSharedTextureMap(rooms);

    final placementResults = await Future.wait(
      layout.placements.map((placement) async {
        final room = project.roomById(placement.roomId);
        if (room == null) return null;

        final roomPayload = await _roomSceneBuilder.buildRoomPayload(
          room,
          showWallDimensionLabels: showWallDimensionLabels,
          premiumFurniture: premiumFurniture,
          embedTextures: false,
        );

        return {
          'blueprintX': placement.blueprintX,
          'blueprintY': placement.blueprintY,
          'rotation': placement.rotation,
          'name': room.name,
          'room': roomPayload,
        };
      }),
    );

    final placements = placementResults.whereType<Map<String, dynamic>>().toList();

    final scene = {
      'mode': 'apartment',
      'performanceMode': true,
      'showWallDimensionLabels': showWallDimensionLabels,
      'premiumFurniture': premiumFurniture,
      if (sharedTextures.isNotEmpty) 'sharedTextures': sharedTextures,
      'apartment': {
        'width': layout.widthFt,
        'length': layout.lengthFt,
      },
      'placements': placements,
    };

    return jsonEncode(scene);
  }
}

class RoomSceneBuilder {
  RoomSceneBuilder(this._textureService);

  final TextureService _textureService;
  final _sceneCache = <String, String>{};

  Future<String> buildSceneJson(
    RoomDesign design, {
    bool showWallDimensionLabels = true,
    bool premiumFurniture = false,
  }) async {
    final cacheKey = jsonEncode({
      'design': design.toJson(),
      'showWallDimensionLabels': showWallDimensionLabels,
      'premiumFurniture': premiumFurniture,
      'embedTextures': true,
    });
    final cached = _sceneCache[cacheKey];
    if (cached != null) return cached;

    final payload = await buildRoomPayload(
      design,
      showWallDimensionLabels: showWallDimensionLabels,
      premiumFurniture: premiumFurniture,
      embedTextures: true,
    );
    final json = jsonEncode(payload);
    _sceneCache[cacheKey] = json;
    return json;
  }

  Future<Map<String, String>> buildSharedTextureMap(
    Iterable<RoomDesign> rooms,
  ) async {
    final paths = <String>{};

    void collect(String? path) {
      if (path != null && path.isNotEmpty) paths.add(path);
    }

    for (final room in rooms) {
      collect(room.floor.texturePath);
      collect(room.ceiling.texturePath);
      for (final wall in room.walls) {
        collect(wall.wallpaperPath);
      }
      for (final door in room.doors) {
        collect(door.texturePath);
      }
      for (final unit in room.acUnits) {
        collect(unit.texturePath);
      }
      for (final unit in room.wallTvUnits) {
        collect(unit.texturePath);
      }
      for (final item in room.furniture) {
        collect(item.texturePath);
      }
    }

    final shared = <String, String>{};
    for (final path in paths) {
      final dataUrl = await _textureService.resolveTextureDataUrl(path);
      if (dataUrl != null) {
        shared[path] = dataUrl;
      }
    }
    return shared;
  }

  Future<Map<String, dynamic>> buildRoomPayload(
    RoomDesign design, {
    bool showWallDimensionLabels = true,
    bool premiumFurniture = false,
    bool embedTextures = true,
  }) async {
    Future<String?> textureUrl(String? path) async {
      if (!embedTextures) return null;
      return _textureService.resolveTextureDataUrl(path);
    }

    final walls = <Map<String, dynamic>>[];
    for (final wall in design.walls) {
      walls.add({
        ...wall.toJson(),
        'textureDataUrl': await textureUrl(wall.wallpaperPath),
      });
    }

    final doors = <Map<String, dynamic>>[];
    for (final door in design.doors) {
      doors.add({
        ...door.toJson(),
        'textureDataUrl': await textureUrl(door.texturePath),
      });
    }

    final acUnits = <Map<String, dynamic>>[];
    for (final unit in design.acUnits) {
      acUnits.add({
        ...unit.toJson(),
        'textureDataUrl': await textureUrl(unit.texturePath),
      });
    }

    final dims = design.dimensions;
    final geometry = RoomGeometry.fromDimensions(dims);
    final floorPolygon = dims.isPolygon
        ? dims.normalizedPolygonVertices
            .map((c) => {'x': c.x, 'y': c.y})
            .toList()
        : (dims.useCustomWallLengths && geometry.isValid
            ? geometry.corners.map((c) => {'x': c.x, 'y': c.y}).toList()
            : null);

    final wallTvUnits = <Map<String, dynamic>>[];
    for (final unit in design.wallTvUnits) {
      wallTvUnits.add({
        ...unit.toJson(),
        'textureDataUrl': await textureUrl(unit.texturePath),
      });
    }

    return {
      'mode': 'single',
      'showWallDimensionLabels': showWallDimensionLabels,
      'premiumFurniture': premiumFurniture,
      'room': {
        ...dims.toJson(),
        'effectiveWidth': dims.effectiveWidth,
        'effectiveLength': dims.effectiveLength,
        if (floorPolygon != null) 'floorPolygon': floorPolygon,
        'wallCount': design.walls.length,
        'wallLengths': {
          for (final wall in design.walls)
            'wall_${wall.wallIndex}': dims.isPolygon
                ? PolygonRoomGeometry.edgeLengthFt(
                    dims.normalizedPolygonVertices,
                    wall.wallIndex,
                  )
                : dims.lengthForWall(wall.id),
          if (!dims.isPolygon)
            for (final wall in WallId.values) wall.name: dims.lengthForWall(wall),
        },
      },
      'walls': walls,
      'floor': {
        ...design.floor.toJson(),
        'textureDataUrl': await textureUrl(design.floor.texturePath),
      },
      'ceiling': {
        ...design.ceiling.toJson(),
        'textureDataUrl': await textureUrl(design.ceiling.texturePath),
      },
      'doors': doors,
      'windows': design.windows.map((w) => w.toJson()).toList(),
      'curtains': design.curtains.map((c) => c.toJson()).toList(),
      'acUnits': acUnits,
      'wallTvUnits': wallTvUnits,
      'cupboards': const <Map<String, dynamic>>[],
      'lights': design.lights.map((l) => l.toJson()).toList(),
      'fans': design.fans.map((f) => f.toJson()).toList(),
      'furniture': await Future.wait(
        design.furniture.map((f) async {
          return {
            ...f.toJson(),
            'textureDataUrl': await textureUrl(f.texturePath),
          };
        }),
      ),
    };
  }
}

final roomSceneBuilderProvider = Provider<RoomSceneBuilder>((ref) {
  return RoomSceneBuilder(ref.read(textureServiceProvider));
});

final apartmentSceneBuilderProvider = Provider<ApartmentSceneBuilder>((ref) {
  return ApartmentSceneBuilder(ref.read(roomSceneBuilderProvider));
});
