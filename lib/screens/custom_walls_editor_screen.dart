import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_spacing.dart';
import '../core/utils/polygon_room_geometry.dart';
import '../models/enums.dart';
import '../models/wall_config.dart';
import '../providers/room_design_provider.dart';
import '../widgets/common/color_picker_field.dart';
import '../widgets/common/dimension_slider.dart';
import '../widgets/common/section_card.dart';
import '../widgets/common/texture_picker_widget.dart';
import '../widgets/common/editor_item_card.dart' show EditorHelperText;
import '../widgets/editors/wall_barrier_type_field.dart';

/// Per-wall editor for polygon/custom rooms — one card per wall edge.
class CustomWallsEditorScreen extends ConsumerWidget {
  const CustomWallsEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(roomDesignProvider);
    final dims = design.dimensions;
    final walls = design.walls;
    final notifier = ref.read(roomDesignProvider.notifier);
    final theme = Theme.of(context);

    if (!dims.isPolygon) {
      return Scaffold(
        appBar: AppBar(title: const Text('Custom Room Walls')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Create a custom room shape first from Room Setup → Custom room shape.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final vertices = dims.normalizedPolygonVertices;
    final lengths = PolygonRoomGeometry.edgeLengthsFt(vertices);

    return Scaffold(
      appBar: AppBar(title: const Text('Custom Room Walls')),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          SectionCard(
            title: 'Polygon room',
            subtitle:
                '${walls.length} walls • ${dims.effectiveWidth.toStringAsFixed(1)} × '
                '${dims.effectiveLength.toStringAsFixed(1)} ft footprint',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Each wall matches an edge of your custom shape. '
                  'Doors and windows on polygon walls are coming in a later update.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.visibility_off, size: 16),
                      label: const Text('Hide all'),
                      onPressed: () => notifier.setAllWallsVisibility(0),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Show all'),
                      onPressed: () => notifier.setAllWallsVisibility(1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ...List.generate(walls.length, (i) {
            final wall = walls[i];
            final lenFt = i < lengths.length ? lengths[i] : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SectionCard(
                title: 'Wall ${wall.displayNumber}',
                subtitle: '${lenFt.toStringAsFixed(2)} ft',
                child: _PolygonWallFields(wall: wall),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PolygonWallFields extends ConsumerWidget {
  const _PolygonWallFields({required this.wall});

  final WallConfig wall;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(roomDesignProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Wall visibility', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Hidden'),
              selected: wall.isFullyHidden,
              onSelected: (_) => notifier.updateWall(wall.copyWith(visibleFraction: 0)),
            ),
            FilterChip(
              label: const Text('50%'),
              selected: (wall.visibleFraction - 0.5).abs() < 0.05,
              onSelected: (_) => notifier.updateWall(wall.copyWith(visibleFraction: 0.5)),
            ),
            FilterChip(
              label: const Text('Full'),
              selected: wall.visibleFraction >= 0.99,
              onSelected: (_) => notifier.updateWall(wall.copyWith(visibleFraction: 1)),
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
        ],
        const Divider(height: 24),
        WallBarrierTypeField(
          barrierType: wall.barrierType,
          colorHex: wall.color,
          onBarrierTypeChanged: (type) =>
              notifier.updateWall(wall.copyWith(barrierType: type)),
          onColorChanged: (c) => notifier.updateWall(wall.copyWith(color: c)),
        ),
        if (!wall.isBarrier) ...[
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
          TexturePickerWidget(
            texturePath: wall.wallpaperPath,
            uploadLabel: 'Upload Wallpaper',
            changeLabel: 'Change Wallpaper',
            onTextureSelected: (path) {
              notifier.updateWall(
                wall.copyWith(surfaceType: SurfaceType.wallpaper, wallpaperPath: path),
              );
            },
            onClear: wall.wallpaperPath == null
                ? null
                : () => notifier.updateWall(wall.copyWith(clearWallpaper: true)),
          ),
          ColorPickerField(
            label: 'Tint',
            colorHex: wall.color,
            onChanged: (c) => notifier.updateWall(wall.copyWith(color: c)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tile wallpaper'),
            value: wall.tileWallpaper,
            onChanged: (v) => notifier.updateWall(wall.copyWith(tileWallpaper: v)),
          ),
        ],
        ],
      ],
    );
  }
}
