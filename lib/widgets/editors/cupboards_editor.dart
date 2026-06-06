import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/cupboard_config.dart';
import '../../models/enums.dart';
import '../../models/room_design.dart';
import '../../providers/room_design_provider.dart';
import '../../services/texture_service.dart';
import '../common/color_picker_field.dart';
import '../common/dimension_slider.dart';
import '../common/item_editor_header.dart';
import '../common/section_card.dart';

class CupboardsEditor extends ConsumerWidget {
  const CupboardsEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(roomDesignProvider);
    final cupboards = design.cupboards;

    return ListView(
      children: [
        SectionCard(
          title: 'Cupboards / Wardrobes',
          subtitle: 'Tap edit icon to adjust parameters • Drag in Blueprint',
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => ref.read(roomDesignProvider.notifier).addCupboard(),
          ),
          child: cupboards.isEmpty
              ? const Text('No cupboards added. Tap + to add.')
              : Column(
                  children: cupboards
                      .map((c) => _CupboardCard(cupboard: c, design: design))
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
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
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Tap edit to change parameters, or drag in Blueprint view',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
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
              FilledButton.icon(
                onPressed: () async {
                  final path = await ref.read(textureServiceProvider).pickAndSaveTexture();
                  if (path != null) {
                    notifier.updateCupboard(cupboard.copyWith(texturePath: path));
                  }
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Texture'),
              ),
          ],
        ),
      ),
    );
  }
}
