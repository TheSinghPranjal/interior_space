import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  }) async {
    final layout = project.apartmentLayout;

    final placementResults = await Future.wait(
      layout.placements.map((placement) async {
        final room = project.roomById(placement.roomId);
        if (room == null) return null;

        final roomJson = jsonDecode(
          await _roomSceneBuilder.buildSceneJson(
            room,
            showWallDimensionLabels: showWallDimensionLabels,
          ),
        ) as Map<String, dynamic>;

        return {
          'blueprintX': placement.blueprintX,
          'blueprintY': placement.blueprintY,
          'rotation': placement.rotation,
          'name': room.name,
          'room': roomJson,
        };
      }),
    );

    final placements = placementResults.whereType<Map<String, dynamic>>().toList();

    final scene = {
      'mode': 'apartment',
      'performanceMode': true,
      'showWallDimensionLabels': showWallDimensionLabels,
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
  }) async {
    final cacheKey = jsonEncode({
      'design': design.toJson(),
      'showWallDimensionLabels': showWallDimensionLabels,
    });
    final cached = _sceneCache[cacheKey];
    if (cached != null) return cached;

    final json = await _buildSceneJson(
      design,
      showWallDimensionLabels: showWallDimensionLabels,
    );
    _sceneCache[cacheKey] = json;
    return json;
  }

  Future<String> _buildSceneJson(
    RoomDesign design, {
    bool showWallDimensionLabels = true,
  }) async {
    final walls = <Map<String, dynamic>>[];
    for (final wall in design.walls) {
      walls.add({
        ...wall.toJson(),
        'textureDataUrl':
            await _textureService.resolveTextureDataUrl(wall.wallpaperPath),
      });
    }

    final doors = <Map<String, dynamic>>[];
    for (final door in design.doors) {
      doors.add({
        ...door.toJson(),
        'textureDataUrl':
            await _textureService.resolveTextureDataUrl(door.texturePath),
      });
    }

    final acUnits = <Map<String, dynamic>>[];
    for (final unit in design.acUnits) {
      acUnits.add({
        ...unit.toJson(),
        'textureDataUrl':
            await _textureService.resolveTextureDataUrl(unit.texturePath),
      });
    }

    final dims = design.dimensions;
    final geometry = RoomGeometry.fromDimensions(dims);
    // Only send polygon geometry when custom wall mode is active.
    final floorPolygon = dims.useCustomWallLengths && geometry.isValid
        ? geometry.corners.map((c) => {'x': c.x, 'y': c.y}).toList()
        : null;

    final wallTvUnits = <Map<String, dynamic>>[];
    for (final unit in design.wallTvUnits) {
      wallTvUnits.add({
        ...unit.toJson(),
        'textureDataUrl':
            await _textureService.resolveTextureDataUrl(unit.texturePath),
      });
    }

    final scene = {
      'mode': 'single',
      'showWallDimensionLabels': showWallDimensionLabels,
      'room': {
        ...dims.toJson(),
        'effectiveWidth': dims.effectiveWidth,
        'effectiveLength': dims.effectiveLength,
        if (floorPolygon != null) 'floorPolygon': floorPolygon,
        'wallLengths': {
          for (final wall in WallId.values) wall.name: dims.lengthForWall(wall),
        },
      },
      'walls': walls,
      'floor': {
        ...design.floor.toJson(),
        'textureDataUrl':
            await _textureService.resolveTextureDataUrl(design.floor.texturePath),
      },
      'ceiling': {
        ...design.ceiling.toJson(),
        'textureDataUrl': await _textureService.resolveTextureDataUrl(
          design.ceiling.texturePath,
        ),
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
            'textureDataUrl':
                await _textureService.resolveTextureDataUrl(f.texturePath),
          };
        }),
      ),
    };

    return jsonEncode(scene);
  }
}

final roomSceneBuilderProvider = Provider<RoomSceneBuilder>((ref) {
  return RoomSceneBuilder(ref.read(textureServiceProvider));
});

final apartmentSceneBuilderProvider = Provider<ApartmentSceneBuilder>((ref) {
  return ApartmentSceneBuilder(ref.read(roomSceneBuilderProvider));
});
