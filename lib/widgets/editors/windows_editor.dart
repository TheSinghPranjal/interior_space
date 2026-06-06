import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/room_constants.dart';
import '../../models/enums.dart';
import '../../models/window_config.dart';
import '../../providers/room_design_provider.dart';
import '../common/color_picker_field.dart';
import '../common/dimension_slider.dart';
import '../common/item_editor_header.dart';
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
          subtitle: 'Tap edit icon to adjust parameters • Drag in Blueprint',
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

class _WindowCard extends ConsumerStatefulWidget {
  const _WindowCard({required this.window});

  final WindowConfig window;

  @override
  ConsumerState<_WindowCard> createState() => _WindowCardState();
}

class _WindowCardState extends ConsumerState<_WindowCard> {
  bool _editingEnabled = false;

  @override
  Widget build(BuildContext context) {
    final window = widget.window;
    final design = ref.watch(roomDesignProvider);
    final notifier = ref.read(roomDesignProvider.notifier);
    final enabled = _editingEnabled;
    final maxEdge = window.maxPositionFromEdge(design.dimensions);
    final clampedPosition = window.positionFromEdge.clamp(0, maxEdge).toDouble();

    if (clampedPosition != window.positionFromEdge) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.updateWindow(window.copyWith(positionFromEdge: clampedPosition));
      });
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ItemEditorHeader(
              title: 'Window',
              icon: Icons.window,
              editingEnabled: _editingEnabled,
              onToggleEdit: () => setState(() => _editingEnabled = !_editingEnabled),
              onDelete: () => notifier.removeWindow(window.id),
            ),
            if (!enabled)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Tap edit to change parameters, or drag in Blueprint view',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            DropdownButtonFormField<WallId>(
              value: window.wall,
              decoration: const InputDecoration(labelText: 'Wall'),
              items: WallId.values
                  .map((w) => DropdownMenuItem(value: w, child: Text(w.label)))
                  .toList(),
              onChanged: enabled
                  ? (w) {
                      if (w != null) {
                        final updated = window.copyWith(wall: w);
                        notifier.updateWindow(
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
              value: window.width,
              min: 2,
              max: 8,
              suffix: 'ft',
              onChanged: enabled
                  ? (v) {
                      final updated = window.copyWith(width: v);
                      notifier.updateWindow(
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
              value: window.height,
              min: 2,
              max: 6,
              suffix: 'ft',
              onChanged: enabled ? (v) => notifier.updateWindow(window.copyWith(height: v)) : null,
            ),
            DimensionSlider(
              label: 'Position from edge',
              value: clampedPosition,
              min: 0,
              max: maxEdge,
              suffix: 'ft',
              onChanged: enabled && maxEdge > 0
                  ? (v) => notifier.updateWindow(window.copyWith(positionFromEdge: v))
                  : null,
            ),
            DimensionSlider(
              label: 'From floor',
              value: window.positionFromFloor,
              min: 1,
              max: design.dimensions.height.clamp(1, RoomConstants.maxHeight).toDouble(),
              suffix: 'ft',
              onChanged: enabled ? (v) => notifier.updateWindow(window.copyWith(positionFromFloor: v)) : null,
            ),
            DimensionSlider(
              label: 'Rotation',
              value: window.rotation,
              min: 0,
              max: 360,
              suffix: '°',
              onChanged: enabled ? (v) => notifier.updateWindow(window.copyWith(rotation: v)) : null,
            ),
            Text(
              'Wall length: ${window.wallLengthFt(design.dimensions).toStringAsFixed(1)} ft',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            ColorPickerField(
              label: 'Glass Color',
              colorHex: window.glassColor,
              enabled: enabled,
              onChanged: (c) => notifier.updateWindow(window.copyWith(glassColor: c)),
            ),
            ColorPickerField(
              label: 'Frame Color',
              colorHex: window.frameColor,
              enabled: enabled,
              onChanged: (c) => notifier.updateWindow(window.copyWith(frameColor: c)),
            ),
          ],
        ),
      ),
    );
  }
}
