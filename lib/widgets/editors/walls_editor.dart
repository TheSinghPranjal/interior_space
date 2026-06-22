import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/wall_config.dart';
import '../../providers/room_design_provider.dart';
import '../../services/texture_service.dart';
import '../common/color_picker_field.dart';
import '../common/dimension_slider.dart';
import '../common/section_card.dart';
import '../common/texture_upload_field.dart';

class WallsEditor extends ConsumerWidget {
  const WallsEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(roomDesignProvider);
    final walls = design.walls;
    final customWalls = design.dimensions.useCustomWallLengths;

    return ListView(
      children: [
        if (customWalls)
          SectionCard(
            title: 'Wall Visibility',
            subtitle: 'Hide or shorten walls for open-plan layouts (custom wall mode)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.visibility_off, size: 18),
                      label: const Text('Hide all walls'),
                      onPressed: () => ref.read(roomDesignProvider.notifier).setAllWallsVisibility(0),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Show all walls'),
                      onPressed: () => ref.read(roomDesignProvider.notifier).setAllWallsVisibility(1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Per wall: set visibility to 0% (open), 50%, or 100%. '
                  'Hide shared walls on adjacent rooms (e.g. kitchen ↔ utility).',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ...WallId.values
            .map((id) => walls.firstWhere((w) => w.id == id))
            .map((wall) => _WallEditorCard(wall: wall, showVisibility: customWalls))
            .toList(),
      ],
    );
  }
}

class _WallEditorCard extends ConsumerWidget {
  const _WallEditorCard({
    required this.wall,
    required this.showVisibility,
  });

  final WallConfig wall;
  final bool showVisibility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(roomDesignProvider.notifier);

    return SectionCard(
      title: wall.id.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showVisibility) ...[
            Text(
              'Wall visibility',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _VisibilityChip(
                  label: 'Hidden',
                  selected: wall.isFullyHidden,
                  onTap: () => notifier.updateWall(wall.copyWith(visibleFraction: 0)),
                ),
                _VisibilityChip(
                  label: '50%',
                  selected: (wall.visibleFraction - 0.5).abs() < 0.05,
                  onTap: () => notifier.updateWall(wall.copyWith(visibleFraction: 0.5)),
                ),
                _VisibilityChip(
                  label: 'Full',
                  selected: wall.visibleFraction >= 0.99,
                  onTap: () => notifier.updateWall(wall.copyWith(visibleFraction: 1)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DimensionSlider(
              label: 'Visible length (${(wall.visibleFraction * 100).round()}%)',
              value: wall.visibleFraction.clamp(0, 1),
              min: 0,
              max: 1,
              suffix: 'fraction',
              onChanged: (v) => notifier.updateWall(wall.copyWith(visibleFraction: v)),
            ),
            if (wall.isPartial) ...[
              const SizedBox(height: 8),
              SegmentedButton<WallVisibleAlign>(
                segments: const [
                  ButtonSegment(value: WallVisibleAlign.start, label: Text('Start')),
                  ButtonSegment(value: WallVisibleAlign.center, label: Text('Center')),
                  ButtonSegment(value: WallVisibleAlign.end, label: Text('End')),
                ],
                selected: {wall.visibleAlign},
                onSelectionChanged: (s) {
                  notifier.updateWall(wall.copyWith(visibleAlign: s.first));
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Which part of the wall stays solid — e.g. End keeps the segment toward the back/right.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ),
            ],
            const Divider(height: 24),
          ],
          SegmentedButton<SurfaceType>(
            segments: const [
              ButtonSegment(value: SurfaceType.solidColor, label: Text('Color')),
              ButtonSegment(value: SurfaceType.texture, label: Text('Texture')),
              ButtonSegment(value: SurfaceType.wallpaper, label: Text('Wallpaper')),
            ],
            selected: {wall.surfaceType},
            onSelectionChanged: (s) {
              notifier.updateWall(wall.copyWith(surfaceType: s.first));
            },
          ),
          const SizedBox(height: 12),
          if (wall.surfaceType == SurfaceType.solidColor)
            ColorPickerField(
              label: 'Wall Color',
              colorHex: wall.color,
              onChanged: (c) => notifier.updateWall(wall.copyWith(color: c)),
            ),
          if (wall.surfaceType == SurfaceType.texture) ...[
            DropdownButtonFormField<WallTexture>(
              initialValue: wall.texture,
              decoration: const InputDecoration(labelText: 'Texture'),
              items: WallTexture.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (t) {
                if (t != null) notifier.updateWall(wall.copyWith(texture: t));
              },
            ),
            ColorPickerField(
              label: 'Base Tint',
              colorHex: wall.color,
              onChanged: (c) => notifier.updateWall(wall.copyWith(color: c)),
            ),
          ],
          if (wall.surfaceType == SurfaceType.wallpaper) ...[
            TextureUploadField(
              texturePath: wall.wallpaperPath,
              uploadLabel: 'Upload Wallpaper',
              changeLabel: 'Change Wallpaper',
              onPick: () async {
                final path = await ref.read(textureServiceProvider).pickAndSaveTexture();
                if (path != null) {
                  notifier.updateWall(
                    wall.copyWith(
                      surfaceType: SurfaceType.wallpaper,
                      wallpaperPath: path,
                    ),
                  );
                }
              },
              onClear: wall.wallpaperPath == null
                  ? null
                  : () => notifier.updateWall(
                        wall.copyWith(clearWallpaper: true),
                      ),
            ),
            ColorPickerField(
              label: 'Tint',
              colorHex: wall.color,
              onChanged: (c) => notifier.updateWall(wall.copyWith(color: c)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tile wallpaper'),
              subtitle: const Text(
                'Off: stretch one image across the wall. On: repeat the image in a grid.',
              ),
              value: wall.tileWallpaper,
              onChanged: (v) => notifier.updateWall(wall.copyWith(tileWallpaper: v)),
            ),
          ],
        ],
      ),
    );
  }
}

class _VisibilityChip extends StatelessWidget {
  const _VisibilityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
