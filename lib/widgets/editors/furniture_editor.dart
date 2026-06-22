import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/furniture_item.dart';
import '../../models/room_design.dart';
import '../../providers/room_design_provider.dart';
import '../../services/texture_service.dart';
import '../common/color_picker_field.dart';
import '../common/dimension_slider.dart';
import '../common/item_editor_header.dart';
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
          subtitle: 'Tap edit icon to adjust parameters • Drag in Blueprint',
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

class _FurnitureCard extends ConsumerStatefulWidget {
  const _FurnitureCard({
    required this.item,
    required this.design,
  });

  final FurnitureItem item;
  final RoomDesign design;

  @override
  ConsumerState<_FurnitureCard> createState() => _FurnitureCardState();
}

class _FurnitureCardState extends ConsumerState<_FurnitureCard> {
  bool _editingEnabled = false;

  FurnitureItem get item => widget.item;
  RoomDesign get design => widget.design;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(roomDesignProvider.notifier);
    final enabled = _editingEnabled;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ItemEditorHeader(
              title: item.type.label,
              icon: item.type.icon,
              editingEnabled: _editingEnabled,
              onToggleEdit: () => setState(() => _editingEnabled = !_editingEnabled),
              onDelete: () => notifier.removeFurniture(item.id),
            ),
            if (!enabled)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Tap edit to change parameters, or drag in Blueprint view',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            if (item.isWallMounted) ...[
              DropdownButtonFormField<WallId>(
                value: item.wall ?? WallId.left,
                decoration: const InputDecoration(labelText: 'Wall'),
                items: WallId.values
                    .map((w) => DropdownMenuItem(value: w, child: Text(w.label)))
                    .toList(),
                onChanged: enabled
                    ? (w) {
                        if (w != null) notifier.updateFurniture(item.copyWith(wall: w));
                      }
                    : null,
              ),
              DimensionSlider(
                label: 'Position from wall edge',
                value: item.positionFromEdge,
                min: 0,
                max: 12,
                suffix: 'ft',
                onChanged: enabled
                    ? (v) => notifier.updateFurniture(item.copyWith(positionFromEdge: v))
                    : null,
              ),
            ] else ...[
              DimensionSlider(
                label: 'Distance from left wall',
                value: item.positionFromLeftFt(design.dimensions),
                min: 0,
                max: item.maxPositionFromLeftFt(design.dimensions),
                suffix: 'ft',
                onChanged: enabled
                    ? (v) => notifier.updateFurniture(
                          item.copyWith(
                            blueprintX: item.blueprintXFromLeftFt(v, design.dimensions),
                          ),
                        )
                    : null,
              ),
              DimensionSlider(
                label: 'Distance from front wall',
                value: item.positionFromFrontFt(design.dimensions),
                min: 0,
                max: item.maxPositionFromFrontFt(design.dimensions),
                suffix: 'ft',
                onChanged: enabled
                    ? (v) => notifier.updateFurniture(
                          item.copyWith(
                            blueprintY: item.blueprintYFromFrontFt(v, design.dimensions),
                          ),
                        )
                    : null,
              ),
              DimensionSlider(
                label: 'Rotation',
                value: item.rotation,
                min: 0,
                max: 360,
                suffix: '°',
                onChanged: enabled
                    ? (v) => notifier.updateFurniture(item.copyWith(rotation: v))
                    : null,
              ),
            ],
            DimensionSlider(
              label: 'Width',
              value: item.width,
              min: 1,
              max: 12,
              suffix: 'ft',
              onChanged: enabled ? (v) => notifier.updateFurniture(item.copyWith(width: v)) : null,
            ),
            DimensionSlider(
              label: 'Height',
              value: item.height,
              min: 1,
              max: 9,
              suffix: 'ft',
              onChanged: enabled ? (v) => notifier.updateFurniture(item.copyWith(height: v)) : null,
            ),
            DimensionSlider(
              label: 'Depth',
              value: item.depth,
              min: 1,
              max: 8,
              suffix: 'ft',
              onChanged: enabled ? (v) => notifier.updateFurniture(item.copyWith(depth: v)) : null,
            ),
            if (item.supportsHeightFromFloor)
              DimensionSlider(
                label: 'Height from floor',
                value: item.heightFromFloor,
                min: 0,
                max: item.maxHeightFromFloorFt(design.dimensions),
                suffix: 'ft',
                onChanged: enabled
                    ? (v) => notifier.updateFurniture(item.copyWith(heightFromFloor: v))
                    : null,
              ),
            ..._typeSpecificFields(item, enabled, notifier),
            ColorPickerField(
              label: 'Color',
              colorHex: item.color,
              enabled: enabled,
              onChanged: (c) => notifier.updateFurniture(item.copyWith(color: c)),
            ),
            if (item.isWallMounted && enabled)
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
            if (item.supportsTextureUpload && enabled)
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

  List<Widget> _typeSpecificFields(
    FurnitureItem item,
    bool enabled,
    RoomDesignNotifier notifier,
  ) {
    return switch (item.type) {
      FurnitureType.diningTable => [
          DropdownButtonFormField<DiningTableShape>(
            value: item.diningTableShape,
            decoration: const InputDecoration(labelText: 'Table Shape'),
            items: DiningTableShape.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: enabled
                ? (s) {
                    if (s != null) {
                      notifier.updateFurniture(item.copyWith(variant: s.name));
                    }
                  }
                : null,
          ),
        ],
      FurnitureType.storageUnit => [
          DropdownButtonFormField<StorageUnitStyle>(
            value: item.storageUnitStyle,
            decoration: const InputDecoration(labelText: 'Cabinet Style'),
            items: StorageUnitStyle.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: enabled
                ? (s) {
                    if (s != null) {
                      notifier.updateFurniture(item.copyWith(variant: s.name));
                    }
                  }
                : null,
          ),
          DropdownButtonFormField<FurnitureMaterialPreset>(
            value: item.material,
            decoration: const InputDecoration(labelText: 'Material'),
            items: <FurnitureMaterialPreset>[
              FurnitureMaterialPreset.wood,
              FurnitureMaterialPreset.whiteMatte,
              FurnitureMaterialPreset.glossy,
              FurnitureMaterialPreset.metallic,
            ].map((m) => DropdownMenuItem(value: m, child: Text(m.label))).toList(),
            onChanged: enabled
                ? (m) {
                    if (m != null) {
                      notifier.updateFurniture(item.copyWith(materialPreset: m.name));
                    }
                  }
                : null,
          ),
        ],
      FurnitureType.kitchenChimney => [
          DropdownButtonFormField<KitchenChimneyStyle>(
            value: item.chimneyStyle,
            decoration: const InputDecoration(labelText: 'Chimney Style'),
            items: KitchenChimneyStyle.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: enabled
                ? (s) {
                    if (s != null) {
                      notifier.updateFurniture(item.copyWith(variant: s.name));
                    }
                  }
                : null,
          ),
          DropdownButtonFormField<FurnitureMaterialPreset>(
            value: item.material,
            decoration: const InputDecoration(labelText: 'Finish'),
            items: <FurnitureMaterialPreset>[
              FurnitureMaterialPreset.stainlessSteel,
              FurnitureMaterialPreset.black,
              FurnitureMaterialPreset.white,
              FurnitureMaterialPreset.glossy,
            ].map((m) => DropdownMenuItem(value: m, child: Text(m.label))).toList(),
            onChanged: enabled
                ? (m) {
                    if (m != null) {
                      notifier.updateFurniture(item.copyWith(materialPreset: m.name));
                    }
                  }
                : null,
          ),
        ],
      _ => const <Widget>[],
    };
  }
}
