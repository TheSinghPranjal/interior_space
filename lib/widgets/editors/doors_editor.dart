import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/room_constants.dart';
import '../../models/door_config.dart';
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
          subtitle: 'Long-press doors in Blueprint to move and rotate',
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

  final DoorConfig door;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(roomDesignProvider);
    final notifier = ref.read(roomDesignProvider.notifier);
    final maxEdge = door.maxPositionFromEdge(design.dimensions);
    final clampedPosition = door.positionFromEdge.clamp(0, maxEdge).toDouble();

    if (clampedPosition != door.positionFromEdge) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.updateDoor(door.copyWith(positionFromEdge: clampedPosition));
      });
    }

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
                  onPressed: () => notifier.removeDoor(door.id),
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
                  final updated = door.copyWith(wall: w);
                  notifier.updateDoor(
                    updated.copyWith(
                      positionFromEdge: updated.positionFromEdge
                          .clamp(0, updated.maxPositionFromEdge(design.dimensions))
                          .toDouble(),
                    ),
                  );
                }
              },
            ),
            _Slider(
              label: 'Width',
              value: door.width,
              min: 2,
              max: 6,
              suffix: 'ft',
              onChanged: (v) {
                final updated = door.copyWith(width: v);
                notifier.updateDoor(
                  updated.copyWith(
                    positionFromEdge: updated.positionFromEdge
                        .clamp(0, updated.maxPositionFromEdge(design.dimensions))
                        .toDouble(),
                  ),
                );
              },
            ),
            _Slider(
              label: 'Height',
              value: door.height,
              min: 5,
              max: design.dimensions.height.clamp(5, RoomConstants.maxHeight).toDouble(),
              suffix: 'ft',
              onChanged: (v) => notifier.updateDoor(door.copyWith(height: v)),
            ),
            _Slider(
              label: 'Position from edge',
              value: clampedPosition,
              min: 0,
              max: maxEdge,
              suffix: 'ft',
              onChanged: maxEdge <= 0
                  ? null
                  : (v) => notifier.updateDoor(door.copyWith(positionFromEdge: v)),
            ),
            _Slider(
              label: 'Rotation',
              value: door.rotation,
              min: 0,
              max: 360,
              suffix: '°',
              onChanged: (v) => notifier.updateDoor(door.copyWith(rotation: v)),
            ),
            Text(
              'Wall length: ${door.wallLengthFt(design.dimensions).toStringAsFixed(1)} ft',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            ColorPickerField(
              label: 'Door Color',
              colorHex: door.color,
              onChanged: (c) => notifier.updateDoor(door.copyWith(color: c)),
            ),
            DropdownButtonFormField<DoorMaterial>(
              value: door.material,
              decoration: const InputDecoration(labelText: 'Material'),
              items: DoorMaterial.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                  .toList(),
              onChanged: (m) {
                if (m != null) notifier.updateDoor(door.copyWith(material: m));
              },
            ),
            FilledButton.icon(
              onPressed: () async {
                final path = await ref.read(textureServiceProvider).pickAndSaveTexture();
                if (path != null) {
                  notifier.updateDoor(door.copyWith(texturePath: path));
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
    required this.suffix,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final clampedMax = max < min ? min : max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(1)} $suffix'),
        Slider(
          value: value.clamp(min, clampedMax).toDouble(),
          min: min,
          max: clampedMax,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
