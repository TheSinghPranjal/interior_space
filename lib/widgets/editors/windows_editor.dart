import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/room_constants.dart';
import '../../models/ac_unit_config.dart';
import '../../models/curtain_config.dart';
import '../../models/enums.dart';
import '../../models/window_config.dart';
import '../../providers/room_design_provider.dart';
import '../../services/texture_service.dart';
import '../common/color_picker_field.dart';
import '../common/editor_item_card.dart';
import '../common/dimension_slider.dart';
import '../common/item_editor_header.dart';
import '../common/section_card.dart';
import '../common/texture_upload_field.dart';

class WindowsEditor extends ConsumerWidget {
  const WindowsEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windows = ref.watch(roomDesignProvider).windows;
    final acUnits = ref.watch(roomDesignProvider).acUnits;
    final curtains = ref.watch(roomDesignProvider).curtains;

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
        SectionCard(
          title: 'Curtains',
          subtitle: 'Wall-mounted curtains • Open or closed states',
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => ref.read(roomDesignProvider.notifier).addCurtain(),
          ),
          child: curtains.isEmpty
              ? const Text('No curtains added. Tap + to add curtains.')
              : Column(
                  children: curtains.map((c) => _CurtainCard(curtain: c)).toList(),
                ),
        ),
        SectionCard(
          title: 'AC Units',
          subtitle: 'Wall-mounted split AC • Drag in Blueprint',
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => ref.read(roomDesignProvider.notifier).addAcUnit(),
          ),
          child: acUnits.isEmpty
              ? const Text('No AC units added. Tap + to add a split AC unit.')
              : Column(
                  children: acUnits.map((a) => _AcUnitCard(unit: a)).toList(),
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

    return EditorItemCard(
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
              const EditorHelperText(
                'Tap edit to change parameters, or drag in Blueprint view',
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
            EditorHelperText(
              'Wall length: ${window.wallLengthFt(design.dimensions).toStringAsFixed(1)} ft',
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
    );
  }
}

class _AcUnitCard extends ConsumerStatefulWidget {
  const _AcUnitCard({required this.unit});

  final AcUnitConfig unit;

  @override
  ConsumerState<_AcUnitCard> createState() => _AcUnitCardState();
}

class _AcUnitCardState extends ConsumerState<_AcUnitCard> {
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
        notifier.updateAcUnit(unit.copyWith(positionFromEdge: clampedPosition));
      });
    }

    return EditorItemCard(
      child: Column(
          children: [
            ItemEditorHeader(
              title: 'Split AC Unit',
              icon: Icons.ac_unit,
              editingEnabled: _editingEnabled,
              onToggleEdit: () => setState(() => _editingEnabled = !_editingEnabled),
              onDelete: () => notifier.removeAcUnit(unit.id),
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
                        notifier.updateAcUnit(
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
              max: 6,
              suffix: 'ft',
              onChanged: enabled
                  ? (v) {
                      final updated = unit.copyWith(width: v);
                      notifier.updateAcUnit(
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
              min: 0.5,
              max: 3,
              suffix: 'ft',
              onChanged: enabled ? (v) => notifier.updateAcUnit(unit.copyWith(height: v)) : null,
            ),
            DimensionSlider(
              label: 'Position from edge',
              value: clampedPosition,
              min: 0,
              max: maxEdge,
              suffix: 'ft',
              onChanged: enabled && maxEdge > 0
                  ? (v) => notifier.updateAcUnit(unit.copyWith(positionFromEdge: v))
                  : null,
            ),
            DimensionSlider(
              label: 'From floor',
              value: unit.positionFromFloor,
              min: 1,
              max: design.dimensions.height.clamp(1, RoomConstants.maxHeight).toDouble(),
              suffix: 'ft',
              onChanged: enabled
                  ? (v) => notifier.updateAcUnit(unit.copyWith(positionFromFloor: v))
                  : null,
            ),
            DimensionSlider(
              label: 'Rotation',
              value: unit.rotation,
              min: 0,
              max: 360,
              suffix: '°',
              onChanged: enabled ? (v) => notifier.updateAcUnit(unit.copyWith(rotation: v)) : null,
            ),
            EditorHelperText(
              'Wall length: ${unit.wallLengthFt(design.dimensions).toStringAsFixed(1)} ft',
            ),
            ColorPickerField(
              label: 'AC Color',
              colorHex: unit.color,
              enabled: enabled,
              onChanged: (c) => notifier.updateAcUnit(unit.copyWith(color: c)),
            ),
            if (enabled)
              TextureUploadField(
                texturePath: unit.texturePath,
                uploadLabel: 'Upload AC Image',
                changeLabel: 'Change AC Image',
                onPick: () async {
                  final path = await ref.read(textureServiceProvider).pickAndSaveTexture();
                  if (path != null) {
                    notifier.updateAcUnit(unit.copyWith(texturePath: path));
                  }
                },
                onClear: unit.texturePath == null
                    ? null
                    : () => notifier.updateAcUnit(unit.copyWith(texturePath: null)),
              ),
          ],
      ),
    );
  }
}

class _CurtainCard extends ConsumerStatefulWidget {
  const _CurtainCard({required this.curtain});

  final CurtainConfig curtain;

  @override
  ConsumerState<_CurtainCard> createState() => _CurtainCardState();
}

class _CurtainCardState extends ConsumerState<_CurtainCard> {
  bool _editingEnabled = false;

  @override
  Widget build(BuildContext context) {
    final curtain = widget.curtain;
    final design = ref.watch(roomDesignProvider);
    final notifier = ref.read(roomDesignProvider.notifier);
    final enabled = _editingEnabled;
    final maxEdge = curtain.maxPositionFromEdge(design.dimensions);
    final clampedPosition = curtain.positionFromEdge.clamp(0, maxEdge).toDouble();

    if (clampedPosition != curtain.positionFromEdge) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.updateCurtain(curtain.copyWith(positionFromEdge: clampedPosition));
      });
    }

    return EditorItemCard(
      child: Column(
          children: [
            ItemEditorHeader(
              title: 'Curtains',
              icon: Icons.curtains,
              editingEnabled: _editingEnabled,
              onToggleEdit: () => setState(() => _editingEnabled = !_editingEnabled),
              onDelete: () => notifier.removeCurtain(curtain.id),
            ),
            DropdownButtonFormField<WallId>(
              value: curtain.wall,
              decoration: const InputDecoration(labelText: 'Wall'),
              items: WallId.values
                  .map((w) => DropdownMenuItem(value: w, child: Text(w.label)))
                  .toList(),
              onChanged: enabled
                  ? (w) {
                      if (w != null) {
                        final updated = curtain.copyWith(wall: w);
                        notifier.updateCurtain(
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
              value: curtain.width,
              min: 2,
              max: 10,
              suffix: 'ft',
              onChanged: enabled
                  ? (v) {
                      final updated = curtain.copyWith(width: v);
                      notifier.updateCurtain(
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
              value: curtain.height,
              min: 3,
              max: 10,
              suffix: 'ft',
              onChanged: enabled ? (v) => notifier.updateCurtain(curtain.copyWith(height: v)) : null,
            ),
            DimensionSlider(
              label: 'Position from edge',
              value: clampedPosition,
              min: 0,
              max: maxEdge,
              suffix: 'ft',
              onChanged: enabled && maxEdge > 0
                  ? (v) => notifier.updateCurtain(curtain.copyWith(positionFromEdge: v))
                  : null,
            ),
            DimensionSlider(
              label: 'From floor',
              value: curtain.positionFromFloor,
              min: 0,
              max: design.dimensions.height.clamp(1, RoomConstants.maxHeight).toDouble(),
              suffix: 'ft',
              onChanged: enabled
                  ? (v) => notifier.updateCurtain(curtain.copyWith(positionFromFloor: v))
                  : null,
            ),
            DimensionSlider(
              label: 'Rotation',
              value: curtain.rotation,
              min: 0,
              max: 360,
              suffix: '°',
              onChanged: enabled ? (v) => notifier.updateCurtain(curtain.copyWith(rotation: v)) : null,
            ),
            DropdownButtonFormField<CurtainState>(
              value: curtain.state,
              decoration: const InputDecoration(labelText: 'Curtain State'),
              items: CurtainState.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: enabled
                  ? (s) {
                      if (s != null) notifier.updateCurtain(curtain.copyWith(state: s));
                    }
                  : null,
            ),
            ColorPickerField(
              label: 'Curtain Color',
              colorHex: curtain.color,
              enabled: enabled,
              onChanged: (c) => notifier.updateCurtain(curtain.copyWith(color: c)),
            ),
          ],
      ),
    );
  }
}
