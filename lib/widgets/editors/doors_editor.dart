import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/room_constants.dart';
import '../../models/enums.dart';
import '../../providers/room_design_provider.dart';
import '../../services/texture_service.dart';
import '../common/color_picker_field.dart';
import '../common/section_card.dart';

class DoorsEditor extends ConsumerWidget {
  const DoorsEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doors = ref.watch(roomDesignProvider).doors;

    return ListView(
      children: [
        SectionCard(
          title: 'Doors',
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => ref.read(roomDesignProvider.notifier).addDoor(),
          ),
          child: doors.isEmpty
              ? const Text('No doors added. Tap + to add a door.')
              : Column(
                  children: doors.map((door) => _DoorCard(door: door)).toList(),
                ),
        ),
      ],
    );
  }
}

class _DoorCard extends ConsumerWidget {
  const _DoorCard({required this.door});

  final dynamic door;

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
                const Expanded(child: Text('Door', style: TextStyle(fontWeight: FontWeight.w600))),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => ref.read(roomDesignProvider.notifier).removeDoor(door.id),
                ),
              ],
            ),
            DropdownButtonFormField<WallId>(
              value: door.wall,
              decoration: const InputDecoration(labelText: 'Wall'),
              items: WallId.values
                  .map((w) => DropdownMenuItem(value: w, child: Text(w.label)))
                  .toList(),
              onChanged: (w) {
                if (w != null) {
                  ref.read(roomDesignProvider.notifier).updateDoor(door.copyWith(wall: w));
                }
              },
            ),
            _Slider(
              label: 'Width',
              value: door.width,
              min: 2,
              max: 6,
              onChanged: (v) => ref.read(roomDesignProvider.notifier).updateDoor(door.copyWith(width: v)),
            ),
            _Slider(
              label: 'Height',
              value: door.height,
              min: 5,
              max: RoomConstants.defaultHeight,
              onChanged: (v) => ref.read(roomDesignProvider.notifier).updateDoor(door.copyWith(height: v)),
            ),
            _Slider(
              label: 'Position from edge',
              value: door.positionFromEdge,
              min: 0,
              max: 10,
              onChanged: (v) => ref.read(roomDesignProvider.notifier).updateDoor(
                    door.copyWith(positionFromEdge: v),
                  ),
            ),
            ColorPickerField(
              label: 'Door Color',
              colorHex: door.color,
              onChanged: (c) => ref.read(roomDesignProvider.notifier).updateDoor(door.copyWith(color: c)),
            ),
            DropdownButtonFormField<DoorMaterial>(
              value: door.material,
              decoration: const InputDecoration(labelText: 'Material'),
              items: DoorMaterial.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                  .toList(),
              onChanged: (m) {
                if (m != null) {
                  ref.read(roomDesignProvider.notifier).updateDoor(door.copyWith(material: m));
                }
              },
            ),
            FilledButton.icon(
              onPressed: () async {
                final path = await ref.read(textureServiceProvider).pickAndSaveTexture();
                if (path != null) {
                  ref.read(roomDesignProvider.notifier).updateDoor(door.copyWith(texturePath: path));
                }
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Door Texture'),
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
        Text('$label: ${value.toStringAsFixed(1)} ft'),
        Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}
