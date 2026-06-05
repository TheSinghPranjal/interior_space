import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/furniture_item.dart';
import '../../models/room_design.dart';
import '../../providers/room_design_provider.dart';
import '../../services/texture_service.dart';
import '../common/color_picker_field.dart';
import '../common/section_card.dart';

class FurnitureEditor extends ConsumerWidget {
  const FurnitureEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(roomDesignProvider);
    final furniture = design.furniture;

    return ListView(
      children: [
        SectionCard(
          title: 'Furniture Placement',
          subtitle: 'Wall items attach to walls • Bed/Table/Chair go anywhere',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FurnitureType.values.map((type) {
              return ActionChip(
                avatar: Icon(type.icon, size: 18),
                label: Text(type.label),
                onPressed: () => ref.read(roomDesignProvider.notifier).addFurniture(type),
              );
            }).toList(),
          ),
        ),
        if (furniture.isNotEmpty)
          SectionCard(
            title: 'Placed Items',
            child: Column(
              children: furniture
                  .map(
                    (item) => _FurnitureCard(
                      item: item,
                      design: design,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _FurnitureCard extends ConsumerWidget {
  const _FurnitureCard({
    required this.item,
    required this.design,
  });

  final FurnitureItem item;
  final RoomDesign design;

  double get roomWidth => design.dimensions.width;
  double get roomLength => design.dimensions.length;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(roomDesignProvider.notifier);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(item.type.icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.type.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => notifier.removeFurniture(item.id),
                ),
              ],
            ),
            if (item.isWallMounted) ...[
              DropdownButtonFormField<WallId>(
                value: item.wall ?? WallId.left,
                decoration: const InputDecoration(labelText: 'Wall'),
                items: WallId.values
                    .map((w) => DropdownMenuItem(value: w, child: Text(w.label)))
                    .toList(),
                onChanged: (w) {
                  if (w != null) notifier.updateFurniture(item.copyWith(wall: w));
                },
              ),
              _Slider(
                label: 'Position from wall edge',
                value: item.positionFromEdge,
                min: 0,
                max: 12,
                suffix: 'ft',
                onChanged: (v) => notifier.updateFurniture(item.copyWith(positionFromEdge: v)),
              ),
            ] else ...[
              _Slider(
                label: 'Distance from left wall',
                value: item.positionFromLeftFt(design.dimensions),
                min: 0,
                max: (roomWidth - item.width).clamp(0, roomWidth),
                suffix: 'ft',
                onChanged: (v) {
                  final bx = (v + item.width / 2) / roomWidth;
                  notifier.updateFurniture(item.copyWith(blueprintX: bx.clamp(0.05, 0.95)));
                },
              ),
              _Slider(
                label: 'Distance from front wall',
                value: item.positionFromFrontFt(design.dimensions),
                min: 0,
                max: (roomLength - item.depth).clamp(0, roomLength),
                suffix: 'ft',
                onChanged: (v) {
                  final by = (v + item.depth / 2) / roomLength;
                  notifier.updateFurniture(item.copyWith(blueprintY: by.clamp(0.05, 0.95)));
                },
              ),
              _Slider(
                label: 'Rotation',
                value: item.rotation,
                min: 0,
                max: 360,
                suffix: '°',
                onChanged: (v) => notifier.updateFurniture(item.copyWith(rotation: v)),
              ),
              Text(
                'Or drag freely in Blueprint view',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
            _Slider(
              label: 'Width',
              value: item.width,
              min: 1,
              max: 12,
              suffix: 'ft',
              onChanged: (v) => notifier.updateFurniture(item.copyWith(width: v)),
            ),
            _Slider(
              label: 'Height',
              value: item.height,
              min: 1,
              max: 9,
              suffix: 'ft',
              onChanged: (v) => notifier.updateFurniture(item.copyWith(height: v)),
            ),
            _Slider(
              label: 'Depth',
              value: item.depth,
              min: 1,
              max: 8,
              suffix: 'ft',
              onChanged: (v) => notifier.updateFurniture(item.copyWith(depth: v)),
            ),
            ColorPickerField(
              label: 'Color',
              colorHex: item.color,
              onChanged: (c) => notifier.updateFurniture(item.copyWith(color: c)),
            ),
            if (item.isWallMounted)
              FilledButton.icon(
                onPressed: () async {
                  final path = await ref.read(textureServiceProvider).pickAndSaveTexture();
                  if (path != null) {
                    notifier.updateFurniture(item.copyWith(texturePath: path));
                  }
                },
                icon: const Icon(Icons.upload_file),
                label: Text(item.texturePath == null ? 'Upload Texture' : 'Change Texture'),
              ),
          ],
        ),
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  const _Slider({
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
    final clampedMax = max < min ? min : max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(1)} $suffix'),
        Slider(
          value: value.clamp(min, clampedMax),
          min: min,
          max: clampedMax,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
