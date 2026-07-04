import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../providers/room_design_provider.dart';
import '../common/color_picker_field.dart';
import '../common/section_card.dart';
import '../common/texture_picker_widget.dart';

class FlooringEditor extends ConsumerWidget {
  const FlooringEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final floor = ref.watch(roomDesignProvider).floor;

    return ListView(
      children: [
        SectionCard(
          title: 'Flooring',
          subtitle: 'Material affects reflection & roughness',
          child: Column(
            children: [
              SegmentedButton<SurfaceType>(
                segments: const [
                  ButtonSegment(value: SurfaceType.solidColor, label: Text('Color')),
                  ButtonSegment(value: SurfaceType.texture, label: Text('Tile/Texture')),
                ],
                selected: {floor.surfaceType},
                onSelectionChanged: (s) {
                  ref.read(roomDesignProvider.notifier).updateFloor(
                        floor.copyWith(surfaceType: s.first),
                      );
                },
              ),
              const SizedBox(height: 12),
              ColorPickerField(
                label: 'Floor Color',
                colorHex: floor.color,
                onChanged: (c) => ref.read(roomDesignProvider.notifier).updateFloor(
                      floor.copyWith(color: c),
                    ),
              ),
              DropdownButtonFormField<FloorMaterial>(
                value: floor.material,
                decoration: const InputDecoration(labelText: 'Material Type'),
                items: FloorMaterial.values
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                    .toList(),
                onChanged: (m) {
                  if (m != null) {
                    final props = _materialProps(m);
                    ref.read(roomDesignProvider.notifier).updateFloor(
                          floor.copyWith(
                            material: m,
                            reflection: props.$1,
                            roughness: props.$2,
                          ),
                        );
                  }
                },
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<FloorPattern>(
                value: floor.pattern,
                decoration: const InputDecoration(labelText: 'Tile Pattern'),
                items: FloorPattern.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (p) {
                  if (p != null) {
                    ref.read(roomDesignProvider.notifier).updateFloor(
                          floor.copyWith(pattern: p),
                        );
                  }
                },
              ),
              SizedBox(height: 10),
              _SliderRow(
                label: 'Tile Length',
                value: floor.tileLength,
                min: 1,
                max: 6,
                suffix: 'ft',
                onChanged: (v) => ref.read(roomDesignProvider.notifier).updateFloor(
                      floor.copyWith(tileLength: v),
                    ),
              ),
              SizedBox(height: 10),
              _SliderRow(
                label: 'Tile Width',
                value: floor.tileWidth,
                min: 1,
                max: 6,
                suffix: 'ft',
                onChanged: (v) => ref.read(roomDesignProvider.notifier).updateFloor(
                      floor.copyWith(tileWidth: v),
                    ),
              ),
              TexturePickerWidget(
                texturePath: floor.texturePath,
                uploadLabel: 'Upload Tile Texture',
                changeLabel: 'Change Texture',
                onTextureSelected: (path) {
                  ref.read(roomDesignProvider.notifier).updateFloor(
                        floor.copyWith(
                          surfaceType: SurfaceType.texture,
                          texturePath: path,
                        ),
                      );
                },
                onClear: floor.texturePath == null
                    ? null
                    : () => ref.read(roomDesignProvider.notifier).updateFloor(
                          floor.copyWith(clearTexture: true),
                        ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  (double, double) _materialProps(FloorMaterial m) => switch (m) {
        FloorMaterial.marble => (0.7, 0.15),
        FloorMaterial.granite => (0.5, 0.25),
        FloorMaterial.wooden => (0.2, 0.7),
        FloorMaterial.vinyl => (0.3, 0.4),
        FloorMaterial.ceramic => (0.4, 0.35),
        FloorMaterial.porcelain => (0.6, 0.2),
      };
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            Text(
              '${value.toStringAsFixed(1)} $suffix',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}
