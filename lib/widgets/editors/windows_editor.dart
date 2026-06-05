import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../providers/room_design_provider.dart';
import '../common/color_picker_field.dart';
import '../common/section_card.dart';

class WindowsEditor extends ConsumerWidget {
  const WindowsEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windows = ref.watch(roomDesignProvider).windows;

    return ListView(
      children: [
        SectionCard(
          title: 'Windows',
          subtitle: 'Creates actual openings in walls',
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => ref.read(roomDesignProvider.notifier).addWindow(),
          ),
          child: windows.isEmpty
              ? const Text('No windows added. Tap + to add a window.')
              : Column(
                  children: windows.map((w) => _WindowCard(window: w)).toList(),
                ),
        ),
      ],
    );
  }
}

class _WindowCard extends ConsumerWidget {
  const _WindowCard({required this.window});

  final dynamic window;

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
                const Expanded(child: Text('Window', style: TextStyle(fontWeight: FontWeight.w600))),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => ref.read(roomDesignProvider.notifier).removeWindow(window.id),
                ),
              ],
            ),
            DropdownButtonFormField<WallId>(
              value: window.wall,
              decoration: const InputDecoration(labelText: 'Wall'),
              items: WallId.values
                  .map((w) => DropdownMenuItem(value: w, child: Text(w.label)))
                  .toList(),
              onChanged: (w) {
                if (w != null) {
                  ref.read(roomDesignProvider.notifier).updateWindow(window.copyWith(wall: w));
                }
              },
            ),
            _Slider(label: 'Width', value: window.width, min: 2, max: 8, onChanged: (v) {
              ref.read(roomDesignProvider.notifier).updateWindow(window.copyWith(width: v));
            }),
            _Slider(label: 'Height', value: window.height, min: 2, max: 6, onChanged: (v) {
              ref.read(roomDesignProvider.notifier).updateWindow(window.copyWith(height: v));
            }),
            _Slider(label: 'From edge', value: window.positionFromEdge, min: 0, max: 10, onChanged: (v) {
              ref.read(roomDesignProvider.notifier).updateWindow(window.copyWith(positionFromEdge: v));
            }),
            _Slider(label: 'From floor', value: window.positionFromFloor, min: 1, max: 8, onChanged: (v) {
              ref.read(roomDesignProvider.notifier).updateWindow(window.copyWith(positionFromFloor: v));
            }),
            ColorPickerField(
              label: 'Glass Color',
              colorHex: window.glassColor,
              onChanged: (c) => ref.read(roomDesignProvider.notifier).updateWindow(window.copyWith(glassColor: c)),
            ),
            ColorPickerField(
              label: 'Frame Color',
              colorHex: window.frameColor,
              onChanged: (c) => ref.read(roomDesignProvider.notifier).updateWindow(window.copyWith(frameColor: c)),
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
