import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/room_constants.dart';
import '../../models/cupboard_config.dart';
import '../../models/enums.dart';
import '../../models/room_design.dart';
import '../../models/wall_tv_unit_config.dart';
import '../../providers/room_design_provider.dart';
import '../../services/texture_service.dart';
import '../common/color_picker_field.dart';
import '../common/editor_item_card.dart';
import '../common/dimension_slider.dart';
import '../common/item_editor_header.dart';
import '../common/section_card.dart';
import '../common/texture_upload_field.dart';

class CupboardsEditor extends ConsumerWidget {
  const CupboardsEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(roomDesignProvider);
    final cupboards = design.cupboards;
    final wallTvUnits = design.wallTvUnits;
    final notifier = ref.read(roomDesignProvider.notifier);

    return ListView(
      children: [
        SectionCard(
          title: 'Furniture Placement',
          subtitle: 'Tap to add items • Drag in Blueprint',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.kitchen, size: 16),
                label: const Text('Cupboard'),
                onPressed: notifier.addCupboard,
              ),
              ActionChip(
                avatar: const Icon(Icons.tv, size: 16),
                label: const Text('Wall TV'),
                onPressed: notifier.addWallTvUnit,
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Cupboards / Wardrobes',
          subtitle: 'Tap edit icon to adjust parameters • Drag in Blueprint',
          child: cupboards.isEmpty
              ? const Text('No cupboards added. Tap Cupboard above to add.')
              : Column(
                  children: cupboards
                      .map((c) => _CupboardCard(cupboard: c, design: design))
                      .toList(),
                ),
        ),
        if (wallTvUnits.isNotEmpty)
          SectionCard(
            title: 'Wall TV Units',
            subtitle: 'Tap edit icon to adjust parameters • Drag in Blueprint',
            child: Column(
              children: wallTvUnits
                  .map((unit) => _WallTvUnitCard(unit: unit, units: wallTvUnits))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _CupboardCard extends ConsumerStatefulWidget {
  const _CupboardCard({required this.cupboard, required this.design});

  final CupboardConfig cupboard;
  final RoomDesign design;

  @override
  ConsumerState<_CupboardCard> createState() => _CupboardCardState();
}

class _CupboardCardState extends ConsumerState<_CupboardCard> {
  bool _editingEnabled = false;

  @override
  Widget build(BuildContext context) {
    final cupboard = widget.cupboard;
    final design = widget.design;
    final notifier = ref.read(roomDesignProvider.notifier);
    final enabled = _editingEnabled;

    return EditorItemCard(
      child: Column(
          children: [
            ItemEditorHeader(
              title: 'Cupboard',
              icon: Icons.kitchen,
              editingEnabled: _editingEnabled,
              onToggleEdit: () => setState(() => _editingEnabled = !_editingEnabled),
              onDelete: () => notifier.removeCupboard(cupboard.id),
            ),
            if (!enabled)
              const EditorHelperText(
                'Tap edit to change parameters, or drag in Blueprint view',
              ),
            DimensionSlider(
              label: 'Distance from left wall',
              value: cupboard.positionFromLeftFt(design.dimensions),
              min: 0,
              max: cupboard.maxPositionFromLeftFt(design.dimensions),
              suffix: 'ft',
              onChanged: enabled
                  ? (v) => notifier.updateCupboard(
                        cupboard.copyWith(
                          blueprintX: cupboard.blueprintXFromLeftFt(v, design.dimensions),
                        ),
                      )
                  : null,
            ),
            DimensionSlider(
              label: 'Distance from front wall',
              value: cupboard.positionFromFrontFt(design.dimensions),
              min: 0,
              max: cupboard.maxPositionFromFrontFt(design.dimensions),
              suffix: 'ft',
              onChanged: enabled
                  ? (v) => notifier.updateCupboard(
                        cupboard.copyWith(
                          blueprintY: cupboard.blueprintYFromFrontFt(v, design.dimensions),
                        ),
                      )
                  : null,
            ),
            DimensionSlider(
              label: 'Rotation',
              value: cupboard.rotation,
              min: 0,
              max: 360,
              suffix: '°',
              onChanged: enabled ? (v) => notifier.updateCupboard(cupboard.copyWith(rotation: v)) : null,
            ),
            DimensionSlider(
              label: 'Width',
              value: cupboard.width,
              min: 2,
              max: 12,
              suffix: 'ft',
              onChanged: enabled ? (v) => notifier.updateCupboard(cupboard.copyWith(width: v)) : null,
            ),
            DimensionSlider(
              label: 'Height',
              value: cupboard.height,
              min: 3,
              max: 9,
              suffix: 'ft',
              onChanged: enabled ? (v) => notifier.updateCupboard(cupboard.copyWith(height: v)) : null,
            ),
            DimensionSlider(
              label: 'Depth',
              value: cupboard.depth,
              min: 1,
              max: 4,
              suffix: 'ft',
              onChanged: enabled ? (v) => notifier.updateCupboard(cupboard.copyWith(depth: v)) : null,
            ),
            ColorPickerField(
              label: 'Color',
              colorHex: cupboard.color,
              enabled: enabled,
              onChanged: (c) => notifier.updateCupboard(cupboard.copyWith(color: c)),
            ),
            DropdownButtonFormField<CupboardTexture>(
              value: cupboard.texture,
              decoration: const InputDecoration(labelText: 'Finish'),
              items: CupboardTexture.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: enabled
                  ? (t) {
                      if (t != null) notifier.updateCupboard(cupboard.copyWith(texture: t));
                    }
                  : null,
            ),
            if (enabled)
              TextureUploadField(
                texturePath: cupboard.texturePath,
                onPick: () async {
                  final path = await ref.read(textureServiceProvider).pickAndSaveTexture();
                  if (path != null) {
                    notifier.updateCupboard(cupboard.copyWith(texturePath: path));
                  }
                },
                onClear: cupboard.texturePath == null
                    ? null
                    : () => notifier.updateCupboard(
                          cupboard.copyWith(clearTexture: true),
                        ),
              ),
          ],
      ),
    );
  }
}

class _WallTvUnitCard extends ConsumerStatefulWidget {
  const _WallTvUnitCard({required this.unit, required this.units});

  final WallTvUnitConfig unit;
  final List<WallTvUnitConfig> units;

  @override
  ConsumerState<_WallTvUnitCard> createState() => _WallTvUnitCardState();
}

class _WallTvUnitCardState extends ConsumerState<_WallTvUnitCard> {
  bool _editingEnabled = false;

  @override
  Widget build(BuildContext context) {
    final unit = widget.unit;
    final design = ref.watch(roomDesignProvider);
    final notifier = ref.read(roomDesignProvider.notifier);
    final enabled = _editingEnabled;
    final maxEdge = unit.maxPositionFromEdge(design.dimensions);
    final clampedPosition = unit.positionFromEdge.clamp(0, maxEdge).toDouble();

    if (clampedPosition != unit.positionFromEdge) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.updateWallTvUnit(unit.copyWith(positionFromEdge: clampedPosition));
      });
    }

    return EditorItemCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ItemEditorHeader(
              title: WallTvUnitConfig.displayLabel(widget.units, unit),
              icon: Icons.tv,
              editingEnabled: _editingEnabled,
              onToggleEdit: () => setState(() => _editingEnabled = !_editingEnabled),
              onDelete: () => notifier.removeWallTvUnit(unit.id),
            ),
            if (!enabled)
              const EditorHelperText(
                'Tap edit to change parameters, or drag in Blueprint view',
              ),
            DropdownButtonFormField<WallId>(
              value: unit.wall,
              decoration: const InputDecoration(labelText: 'Wall'),
              items: WallId.values
                  .map((w) => DropdownMenuItem(value: w, child: Text(w.label)))
                  .toList(),
              onChanged: enabled
                  ? (w) {
                      if (w != null) {
                        final updated = unit.copyWith(wall: w);
                        notifier.updateWallTvUnit(
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
            DimensionSlider(
              label: 'Width',
              value: unit.width,
              min: 2,
              max: 10,
              suffix: 'ft',
              onChanged: enabled
                  ? (v) {
                      final updated = unit.copyWith(width: v);
                      notifier.updateWallTvUnit(
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
              value: unit.height,
              min: 1,
              max: design.dimensions.height.clamp(1, RoomConstants.maxHeight).toDouble(),
              suffix: 'ft',
              onChanged: enabled ? (v) => notifier.updateWallTvUnit(unit.copyWith(height: v)) : null,
            ),
            DimensionSlider(
              label: 'Position from edge',
              value: clampedPosition,
              min: 0,
              max: maxEdge,
              suffix: 'ft',
              onChanged: enabled && maxEdge > 0
                  ? (v) => notifier.updateWallTvUnit(unit.copyWith(positionFromEdge: v))
                  : null,
            ),
            DimensionSlider(
              label: 'From floor',
              value: unit.positionFromFloor,
              min: 1,
              max: design.dimensions.height.clamp(1, RoomConstants.maxHeight).toDouble(),
              suffix: 'ft',
              onChanged: enabled ? (v) => notifier.updateWallTvUnit(unit.copyWith(positionFromFloor: v)) : null,
            ),
            DimensionSlider(
              label: 'Rotation',
              value: unit.rotation,
              min: 0,
              max: 360,
              suffix: '°',
              onChanged: enabled ? (v) => notifier.updateWallTvUnit(unit.copyWith(rotation: v)) : null,
            ),
            EditorHelperText(
              'Wall length: ${unit.wallLengthFt(design.dimensions).toStringAsFixed(1)} ft',
            ),
            ColorPickerField(
              label: 'Color',
              colorHex: unit.color,
              enabled: enabled,
              onChanged: (c) => notifier.updateWallTvUnit(unit.copyWith(color: c)),
            ),
            if (enabled)
              TextureUploadField(
                texturePath: unit.texturePath,
                onPick: () async {
                  final path = await ref.read(textureServiceProvider).pickAndSaveTexture();
                  if (path != null) {
                    notifier.updateWallTvUnit(unit.copyWith(texturePath: path));
                  }
                },
                onClear: unit.texturePath == null
                    ? null
                    : () => notifier.updateWallTvUnit(unit.copyWith(clearTexture: true)),
              ),
          ],
      ),
    );
  }
}
