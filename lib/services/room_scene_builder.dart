import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/room_design.dart';
import 'texture_service.dart';

class RoomSceneBuilder {
  RoomSceneBuilder(this._textureService);

  final TextureService _textureService;

  Future<String> buildSceneJson(RoomDesign design) async {
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

    final cupboards = <Map<String, dynamic>>[];
    for (final cupboard in design.cupboards) {
      cupboards.add({
        ...cupboard.toJson(),
        'textureDataUrl':
            await _textureService.resolveTextureDataUrl(cupboard.texturePath),
      });
    }

    final scene = {
      'room': design.dimensions.toJson(),
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
      'wallTvUnits': design.wallTvUnits.map((t) => t.toJson()).toList(),
      'cupboards': cupboards,
      'lights': design.lights.map((l) => l.toJson()).toList(),
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
