import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/room_constants.dart';
import '../../models/enums.dart';
import '../../models/wall_tv_unit_config.dart';
import '../../providers/room_design_provider.dart';
import '../../services/texture_service.dart';
import '../common/color_picker_field.dart';
import '../common/editor_item_card.dart';
import '../common/dimension_slider.dart';
import '../common/item_editor_header.dart';
import '../common/texture_upload_field.dart';

class WallTvUnitCard extends ConsumerStatefulWidget {
  const WallTvUnitCard({
    super.key,
    required this.unit,
    required this.units,
  });

  final WallTvUnitConfig unit;
  final List<WallTvUnitConfig> units;

  @override
  ConsumerState<WallTvUnitCard> createState() => _WallTvUnitCardState();
}

class _WallTvUnitCardState extends ConsumerState<WallTvUnitCard> {
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
