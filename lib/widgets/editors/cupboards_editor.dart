import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/cupboard_config.dart';
import '../../models/enums.dart';
import '../../models/room_design.dart';
import '../../providers/room_design_provider.dart';
import '../../services/texture_service.dart';
import '../common/color_picker_field.dart';
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
          subtitle: 'Place anywhere • Drag to reposition in Blueprint view',
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => ref.read(roomDesignProvider.notifier).addCupboard(),
          ),
          child: cupboards.isEmpty
              ? const Text('No cupboards added. Tap + to add.')
              : Column(
                  children: cupboards
                      .map(
                        (c) => _CupboardCard(
                          cupboard: c,
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

class _CupboardCard extends ConsumerWidget {
  const _CupboardCard({
    required this.cupboard,
    required this.design,
  });

  final CupboardConfig cupboard;
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
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Cupboard', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => notifier.removeCupboard(cupboard.id),
                ),
              ],
            ),
            _Slider(
              label: 'Distance from left wall',
              value: cupboard.positionFromLeftFt(design.dimensions),
              min: 0,
              max: (roomWidth - cupboard.width).clamp(0, roomWidth),
              suffix: 'ft',
              onChanged: (v) {
                final bx = (v + cupboard.width / 2) / roomWidth;
                notifier.updateCupboard(cupboard.copyWith(blueprintX: bx.clamp(0.05, 0.95)));
              },
            ),
            _Slider(
              label: 'Distance from front wall',
              value: cupboard.positionFromFrontFt(design.dimensions),
              min: 0,
              max: (roomLength - cupboard.depth).clamp(0, roomLength),
              suffix: 'ft',
              onChanged: (v) {
                final by = (v + cupboard.depth / 2) / roomLength;
                notifier.updateCupboard(cupboard.copyWith(blueprintY: by.clamp(0.05, 0.95)));
              },
            ),
            _Slider(
              label: 'Rotation',
              value: cupboard.rotation,
              min: 0,
              max: 360,
              suffix: '°',
              onChanged: (v) => notifier.updateCupboard(cupboard.copyWith(rotation: v)),
            ),
            Text(
              'Or drag freely in Blueprint view',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            _Slider(
              label: 'Width',
              value: cupboard.width,
              min: 2,
              max: 12,
              suffix: 'ft',
              onChanged: (v) => notifier.updateCupboard(cupboard.copyWith(width: v)),
            ),
            _Slider(
              label: 'Height',
              value: cupboard.height,
              min: 3,
              max: 9,
              suffix: 'ft',
              onChanged: (v) => notifier.updateCupboard(cupboard.copyWith(height: v)),
            ),
            _Slider(
              label: 'Depth',
              value: cupboard.depth,
              min: 1,
              max: 4,
              suffix: 'ft',
              onChanged: (v) => notifier.updateCupboard(cupboard.copyWith(depth: v)),
            ),
            ColorPickerField(
              label: 'Color',
              colorHex: cupboard.color,
              onChanged: (c) => notifier.updateCupboard(cupboard.copyWith(color: c)),
            ),
            DropdownButtonFormField<CupboardTexture>(
              value: cupboard.texture,
              decoration: const InputDecoration(labelText: 'Finish'),
              items: CupboardTexture.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (t) {
                if (t != null) {
                  notifier.updateCupboard(cupboard.copyWith(texture: t));
                }
              },
            ),
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
