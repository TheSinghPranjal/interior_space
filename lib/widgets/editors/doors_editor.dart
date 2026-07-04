import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/room_constants.dart';
import '../../models/door_config.dart';
import '../../models/enums.dart';
import '../../providers/room_design_provider.dart';
import '../common/color_picker_field.dart';
import '../common/editor_item_card.dart';
import '../common/dimension_slider.dart';
import '../common/item_editor_header.dart';
import '../common/section_card.dart';
import '../common/texture_picker_widget.dart';

class DoorsEditor extends ConsumerWidget {
  const DoorsEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doors = ref.watch(roomDesignProvider).doors;

    return ListView(
      children: [
        SectionCard(
          title: 'Doors',
          subtitle: 'Tap edit icon to adjust parameters • Drag in Blueprint',
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => ref.read(roomDesignProvider.notifier).addDoor(),
          ),
          child: doors.isEmpty
              ? const Text('No doors added. Tap + to add a door.')
              : Column(
                  children: doors
                      .map((door) => _DoorCard(door: door, doors: doors))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _DoorCard extends ConsumerStatefulWidget {
  const _DoorCard({required this.door, required this.doors});

  final DoorConfig door;
  final List<DoorConfig> doors;

  @override
  ConsumerState<_DoorCard> createState() => _DoorCardState();
}

class _DoorCardState extends ConsumerState<_DoorCard> {
  bool _editingEnabled = false;

  @override
  Widget build(BuildContext context) {
    final door = widget.door;
    final design = ref.watch(roomDesignProvider);
    final notifier = ref.read(roomDesignProvider.notifier);
    final enabled = _editingEnabled;
    final maxEdge = door.maxPositionFromEdge(design.dimensions);
    final clampedPosition = door.positionFromEdge.clamp(0, maxEdge).toDouble();

    if (clampedPosition != door.positionFromEdge) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.updateDoor(door.copyWith(positionFromEdge: clampedPosition));
      });
    }

    return EditorItemCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ItemEditorHeader(
            title: DoorConfig.displayLabel(widget.doors, door),
            icon: Icons.door_front_door,
            editingEnabled: _editingEnabled,
            onToggleEdit: () => setState(() => _editingEnabled = !_editingEnabled),
            onDelete: () => notifier.removeDoor(door.id),
          ),
          if (!enabled)
            const EditorHelperText(
              'Tap edit to change parameters, or drag in Blueprint view',
            ),
            DropdownButtonFormField<WallId>(
              value: door.wall,
              decoration: const InputDecoration(labelText: 'Wall'),
              items: WallId.values
                  .map((w) => DropdownMenuItem(value: w, child: Text(w.label)))
                  .toList(),
              onChanged: enabled
                  ? (w) {
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
                    }
                  : null,
            ),
          SizedBox(height: 10),
            DimensionSlider(
              label: 'Width',
              value: door.width,
              min: RoomConstants.minDoorWidth,
              max: RoomConstants.maxDoorWidth,
              suffix: 'ft',
              onChanged: enabled
                  ? (v) {
                      final updated = door.copyWith(width: v);
                      notifier.updateDoor(
                        updated.copyWith(
                          positionFromEdge: updated.positionFromEdge
                              .clamp(0, updated.maxPositionFromEdge(design.dimensions))
                              .toDouble(),
                        ),
                      );
                    }
                  : null,
            ),
            DimensionSlider(
              label: 'Height',
              value: door.height,
              min: 5,
              max: design.dimensions.height.clamp(5, RoomConstants.maxHeight).toDouble(),
              suffix: 'ft',
              onChanged: enabled ? (v) => notifier.updateDoor(door.copyWith(height: v)) : null,
            ),
            DimensionSlider(
              label: 'Position from edge',
              value: clampedPosition,
              min: 0,
              max: maxEdge,
              suffix: 'ft',
              onChanged: enabled && maxEdge > 0
                  ? (v) => notifier.updateDoor(door.copyWith(positionFromEdge: v))
                  : null,
            ),
            DimensionSlider(
              label: 'Rotation',
              value: door.rotation,
              min: 0,
              max: 360,
              suffix: '°',
              onChanged: enabled ? (v) => notifier.updateDoor(door.copyWith(rotation: v)) : null,
            ),
            EditorHelperText(
              'Wall length: ${door.wallLengthFt(design.dimensions).toStringAsFixed(1)} ft',
            ),
            DropdownButtonFormField<DoorSwingDirection>(
              initialValue: door.swingDirection,
              decoration: const InputDecoration(labelText: 'Open direction'),
              items: DoorSwingDirection.values
                  .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
                  .toList(),
              onChanged: enabled
                  ? (d) {
                      if (d != null) notifier.updateDoor(door.copyWith(swingDirection: d));
                    }
                  : null,
            ),
            DropdownButtonFormField<DoorHingeSide>(
              initialValue: door.hingeSide,
              decoration: const InputDecoration(labelText: 'Hinge side'),
              items: DoorHingeSide.values
                  .map((h) => DropdownMenuItem(value: h, child: Text(h.label)))
                  .toList(),
              onChanged: enabled
                  ? (h) {
                      if (h != null) notifier.updateDoor(door.copyWith(hingeSide: h));
                    }
                  : null,
            ),
            ColorPickerField(
              label: 'Door Color',
              colorHex: door.color,
              enabled: enabled,
              onChanged: (c) => notifier.updateDoor(door.copyWith(color: c)),
            ),
            DropdownButtonFormField<DoorMaterial>(
              value: door.material,
              decoration: const InputDecoration(labelText: 'Material'),
              items: DoorMaterial.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                  .toList(),
              onChanged: enabled
                  ? (m) {
                      if (m != null) notifier.updateDoor(door.copyWith(material: m));
                    }
                  : null,
            ),
          SizedBox(height: 10),
            if (enabled)
              TexturePickerWidget(
                texturePath: door.texturePath,
                uploadLabel: 'Upload Door Texture',
                changeLabel: 'Change Door Texture',
                onTextureSelected: (path) {
                  notifier.updateDoor(door.copyWith(texturePath: path));
                },
                onClear: door.texturePath == null
                    ? null
                    : () => notifier.updateDoor(door.copyWith(clearTexture: true)),
              ),
        ],
      ),
    );
  }
}
