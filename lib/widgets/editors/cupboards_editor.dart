import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../providers/room_design_provider.dart';
import '../../services/texture_service.dart';
import '../common/color_picker_field.dart';
import '../common/section_card.dart';

class CupboardsEditor extends ConsumerWidget {
  const CupboardsEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cupboards = ref.watch(roomDesignProvider).cupboards;

    return ListView(
      children: [
        SectionCard(
          title: 'Cupboards / Wardrobes',
          subtitle: 'Drag to reposition in Blueprint view',
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => ref.read(roomDesignProvider.notifier).addCupboard(),
          ),
          child: cupboards.isEmpty
              ? const Text('No cupboards added. Tap + to add.')
              : Column(
                  children: cupboards.map((c) => _CupboardCard(cupboard: c)).toList(),
                ),
        ),
      ],
    );
  }
}

class _CupboardCard extends ConsumerWidget {
  const _CupboardCard({required this.cupboard});

  final dynamic cupboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  onPressed: () => ref.read(roomDesignProvider.notifier).removeCupboard(cupboard.id),
                ),
              ],
            ),
            DropdownButtonFormField<WallId>(
              value: cupboard.wall,
              decoration: const InputDecoration(labelText: 'Wall'),
              items: WallId.values
                  .map((w) => DropdownMenuItem(value: w, child: Text(w.label)))
                  .toList(),
              onChanged: (w) {
                if (w != null) {
                  ref.read(roomDesignProvider.notifier).updateCupboard(cupboard.copyWith(wall: w));
                }
              },
            ),
            _Slider(label: 'Width', value: cupboard.width, min: 2, max: 12, onChanged: (v) {
              ref.read(roomDesignProvider.notifier).updateCupboard(cupboard.copyWith(width: v));
            }),
            _Slider(label: 'Height', value: cupboard.height, min: 3, max: 9, onChanged: (v) {
              ref.read(roomDesignProvider.notifier).updateCupboard(cupboard.copyWith(height: v));
            }),
            _Slider(label: 'Depth', value: cupboard.depth, min: 1, max: 4, onChanged: (v) {
              ref.read(roomDesignProvider.notifier).updateCupboard(cupboard.copyWith(depth: v));
            }),
            ColorPickerField(
              label: 'Color',
              colorHex: cupboard.color,
              onChanged: (c) => ref.read(roomDesignProvider.notifier).updateCupboard(cupboard.copyWith(color: c)),
            ),
            DropdownButtonFormField<CupboardTexture>(
              value: cupboard.texture,
              decoration: const InputDecoration(labelText: 'Finish'),
              items: CupboardTexture.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (t) {
                if (t != null) {
                  ref.read(roomDesignProvider.notifier).updateCupboard(cupboard.copyWith(texture: t));
                }
              },
            ),
            FilledButton.icon(
              onPressed: () async {
                final path = await ref.read(textureServiceProvider).pickAndSaveTexture();
                if (path != null) {
                  ref.read(roomDesignProvider.notifier).updateCupboard(
                        cupboard.copyWith(texturePath: path),
                      );
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
