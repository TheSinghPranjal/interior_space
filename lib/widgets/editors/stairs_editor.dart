import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/stair_config.dart';
import '../../providers/room_design_provider.dart';
import '../../services/texture_service.dart';
import '../common/color_picker_field.dart';
import '../common/dimension_slider.dart';
import '../common/editor_item_card.dart';
import '../common/item_editor_header.dart';
import '../common/section_card.dart';
import '../common/texture_upload_field.dart';

class StairsEditor extends ConsumerWidget {
  const StairsEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(roomDesignProvider);
    final stairs = design.stairs;

    return ListView(
      children: [
        SectionCard(
          title: 'Stairs',
          subtitle:
              'Evenly spaced steps • ${design.dimensions.height.toStringAsFixed(1)} ft room height • Drag in Blueprint',
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => ref.read(roomDesignProvider.notifier).addStair(),
          ),
          child: stairs.isEmpty
              ? const Text('No stairs added. Tap + to add a staircase.')
              : Column(
                  children: stairs
                      .map((stair) => _StairCard(stair: stair, stairs: stairs))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _StairCard extends ConsumerStatefulWidget {
  const _StairCard({required this.stair, required this.stairs});

  final StairConfig stair;
  final List<StairConfig> stairs;

  @override
  ConsumerState<_StairCard> createState() => _StairCardState();
}

class _StairCardState extends ConsumerState<_StairCard> {
  bool _editingEnabled = false;

  @override
  Widget build(BuildContext context) {
    final stair = widget.stair;
    final design = ref.watch(roomDesignProvider);
    final notifier = ref.read(roomDesignProvider.notifier);
    final enabled = _editingEnabled;
    final steps = stair.safeStepCount;

    return EditorItemCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ItemEditorHeader(
            title: StairConfig.displayLabel(widget.stairs, stair),
            icon: Icons.stairs_outlined,
            editingEnabled: _editingEnabled,
            onToggleEdit: () => setState(() => _editingEnabled = !_editingEnabled),
            onDelete: () => notifier.removeStair(stair.id),
          ),
          if (!enabled)
            const EditorHelperText(
              'Tap edit to change parameters, or drag in Blueprint view',
            ),
          DimensionSlider(
            label: 'Distance from left wall',
            value: stair.positionFromLeftFt(design.dimensions),
            min: 0,
            max: stair.maxPositionFromLeftFt(design.dimensions),
            suffix: 'ft',
            onChanged: enabled
                ? (v) => notifier.updateStair(
                      stair.copyWith(
                        blueprintX: stair.blueprintXFromLeftFt(v, design.dimensions),
                      ),
                    )
                : null,
          ),
          DimensionSlider(
            label: 'Distance from front wall',
            value: stair.positionFromFrontFt(design.dimensions),
            min: 0,
            max: stair.maxPositionFromFrontFt(design.dimensions),
            suffix: 'ft',
            onChanged: enabled
                ? (v) => notifier.updateStair(
                      stair.copyWith(
                        blueprintY: stair.blueprintYFromFrontFt(v, design.dimensions),
                      ),
                    )
                : null,
          ),
          DimensionSlider(
            label: 'Rotation',
            value: stair.rotation,
            min: 0,
            max: 360,
            suffix: '°',
            onChanged: enabled ? (v) => notifier.updateStair(stair.copyWith(rotation: v)) : null,
          ),
          DimensionSlider(
            label: 'Width',
            value: stair.width,
            min: 2,
            max: 8,
            suffix: 'ft',
            onChanged: enabled ? (v) => notifier.updateStair(stair.copyWith(width: v)) : null,
          ),
          DimensionSlider(
            label: 'Total height (rise)',
            value: stair.height,
            min: 2,
            max: design.dimensions.height.clamp(2, 20).toDouble(),
            suffix: 'ft',
            onChanged: enabled ? (v) => notifier.updateStair(stair.copyWith(height: v)) : null,
          ),
          DimensionSlider(
            label: 'Total length (run)',
            value: stair.depth,
            min: 3,
            max: 24,
            suffix: 'ft',
            onChanged: enabled ? (v) => notifier.updateStair(stair.copyWith(depth: v)) : null,
          ),
          DimensionSlider(
            label: 'Total steps',
            value: steps.toDouble(),
            min: 2,
            max: 30,
            suffix: '',
            onChanged: enabled
                ? (v) => notifier.updateStair(stair.copyWith(stepCount: v.round().clamp(2, 30)))
                : null,
          ),
          EditorHelperText(
            'Rise per step: ${stair.risePerStep.toStringAsFixed(2)} ft • '
            'Tread depth: ${stair.treadDepth.toStringAsFixed(2)} ft',
          ),
          DropdownButtonFormField<StairShape>(
            initialValue: stair.shape,
            decoration: const InputDecoration(labelText: 'Stair shape'),
            items: StairShape.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: enabled
                ? (s) {
                    if (s != null) notifier.updateStair(stair.copyWith(shape: s));
                  }
                : null,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Left railing'),
            value: stair.showLeftRailing,
            onChanged: enabled
                ? (v) => notifier.updateStair(stair.copyWith(showLeftRailing: v))
                : null,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Right railing'),
            value: stair.showRightRailing,
            onChanged: enabled
                ? (v) => notifier.updateStair(stair.copyWith(showRightRailing: v))
                : null,
          ),
          ColorPickerField(
            label: 'Color',
            colorHex: stair.color,
            enabled: enabled,
            onChanged: (c) => notifier.updateStair(stair.copyWith(color: c)),
          ),
          DropdownButtonFormField<StairMaterialPreset>(
            initialValue: stair.materialPreset,
            decoration: const InputDecoration(labelText: 'Finish'),
            items: StairMaterialPreset.values
                .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                .toList(),
            onChanged: enabled
                ? (m) {
                    if (m != null) notifier.updateStair(stair.copyWith(materialPreset: m));
                  }
                : null,
          ),
          if (enabled)
            TextureUploadField(
              texturePath: stair.texturePath,
              onPick: () async {
                final path = await ref.read(textureServiceProvider).pickAndSaveTexture();
                if (path != null) {
                  notifier.updateStair(stair.copyWith(texturePath: path));
                }
              },
              onClear: stair.texturePath == null
                  ? null
                  : () => notifier.updateStair(stair.copyWith(clearTexture: true)),
            ),
        ],
      ),
    );
  }
}
