import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/wall_config.dart';
import '../../providers/room_design_provider.dart';
import '../../services/texture_service.dart';
import '../common/color_picker_field.dart';
import '../common/section_card.dart';

class WallsEditor extends ConsumerWidget {
  const WallsEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walls = ref.watch(roomDesignProvider).walls;

    return ListView(
      children: WallId.values
          .map((id) => walls.firstWhere((w) => w.id == id))
          .map((wall) => _WallEditorCard(wall: wall))
          .toList(),
    );
  }
}

class _WallEditorCard extends ConsumerWidget {
  const _WallEditorCard({required this.wall});

  final WallConfig wall;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      title: wall.id.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<SurfaceType>(
            segments: const [
              ButtonSegment(value: SurfaceType.solidColor, label: Text('Color')),
              ButtonSegment(value: SurfaceType.texture, label: Text('Texture')),
              ButtonSegment(value: SurfaceType.wallpaper, label: Text('Wallpaper')),
            ],
            selected: {wall.surfaceType},
            onSelectionChanged: (s) {
              ref.read(roomDesignProvider.notifier).updateWall(
                    wall.copyWith(surfaceType: s.first),
                  );
            },
          ),
          const SizedBox(height: 12),
          if (wall.surfaceType == SurfaceType.solidColor)
            ColorPickerField(
              label: 'Wall Color',
              colorHex: wall.color,
              onChanged: (c) => ref.read(roomDesignProvider.notifier).updateWall(
                    wall.copyWith(color: c),
                  ),
            ),
          if (wall.surfaceType == SurfaceType.texture) ...[
            DropdownButtonFormField<WallTexture>(
              value: wall.texture,
              decoration: const InputDecoration(labelText: 'Texture'),
              items: WallTexture.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (t) {
                if (t != null) {
                  ref.read(roomDesignProvider.notifier).updateWall(
                        wall.copyWith(texture: t),
                      );
                }
              },
            ),
            ColorPickerField(
              label: 'Base Tint',
              colorHex: wall.color,
              onChanged: (c) => ref.read(roomDesignProvider.notifier).updateWall(
                    wall.copyWith(color: c),
                  ),
            ),
          ],
          if (wall.surfaceType == SurfaceType.wallpaper) ...[
            FilledButton.icon(
              onPressed: () async {
                final path = await ref.read(textureServiceProvider).pickAndSaveTexture();
                if (path != null) {
                  ref.read(roomDesignProvider.notifier).updateWall(
                        wall.copyWith(
                          surfaceType: SurfaceType.wallpaper,
                          wallpaperPath: path,
                        ),
                      );
                }

              },
              icon: const Icon(Icons.upload_file),
              label: Text(wall.wallpaperPath == null ? 'Upload Wallpaper' : 'Change Wallpaper'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tile wallpaper'),
              value: wall.tileWallpaper,
              onChanged: (v) => ref.read(roomDesignProvider.notifier).updateWall(
                    wall.copyWith(tileWallpaper: v),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
