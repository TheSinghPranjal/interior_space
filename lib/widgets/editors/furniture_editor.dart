import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../providers/room_design_provider.dart';
import '../common/color_picker_field.dart';
import '../common/section_card.dart';

class FurnitureEditor extends ConsumerWidget {
  const FurnitureEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final furniture = ref.watch(roomDesignProvider).furniture;

    return ListView(
      children: [
        SectionCard(
          title: 'Furniture Placement',
          subtitle: 'Place items in Blueprint, view in 3D Model',
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
              children: furniture.map((item) => _FurnitureCard(item: item)).toList(),
            ),
          ),
      ],
    );
  }
}

class _FurnitureCard extends ConsumerWidget {
  const _FurnitureCard({required this.item});

  final dynamic item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  onPressed: () => ref.read(roomDesignProvider.notifier).removeFurniture(item.id),
                ),
              ],
            ),
            _Slider(label: 'Width', value: item.width, min: 1, max: 10, onChanged: (v) {
              ref.read(roomDesignProvider.notifier).updateFurniture(item.copyWith(width: v));
            }),
            _Slider(label: 'Height', value: item.height, min: 1, max: 8, onChanged: (v) {
              ref.read(roomDesignProvider.notifier).updateFurniture(item.copyWith(height: v));
            }),
            _Slider(label: 'Depth', value: item.depth, min: 1, max: 10, onChanged: (v) {
              ref.read(roomDesignProvider.notifier).updateFurniture(item.copyWith(depth: v));
            }),
            _Slider(label: 'Rotation', value: item.rotation, min: 0, max: 360, onChanged: (v) {
              ref.read(roomDesignProvider.notifier).updateFurniture(item.copyWith(rotation: v));
            }),
            ColorPickerField(
              label: 'Color',
              colorHex: item.color,
              onChanged: (c) => ref.read(roomDesignProvider.notifier).updateFurniture(item.copyWith(color: c)),
            ),
            Text(
              'Drag in Blueprint view to reposition',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(1)}'),
        Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}
