import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../providers/room_design_provider.dart';
import '../common/color_picker_field.dart';
import '../common/section_card.dart';
import '../common/texture_picker_widget.dart';

class CeilingEditor extends ConsumerWidget {
  const CeilingEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ceiling = ref.watch(roomDesignProvider).ceiling;

    return ListView(
      children: [
        SectionCard(
          title: 'Ceiling',
          child: Column(
            children: [
              ColorPickerField(
                label: 'Ceiling Color',
                colorHex: ceiling.color,
                onChanged: (c) => ref.read(roomDesignProvider.notifier).updateCeiling(
                      ceiling.copyWith(color: c),
                    ),
              ),
              DropdownButtonFormField<CeilingMaterial>(
                value: ceiling.material,
                decoration: const InputDecoration(labelText: 'Ceiling Material'),
                items: CeilingMaterial.values
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                    .toList(),
                onChanged: (m) {
                  if (m != null) {
                    ref.read(roomDesignProvider.notifier).updateCeiling(
                          ceiling.copyWith(material: m),
                        );
                  }
                },
              ),
              SizedBox(height: 10),
              TexturePickerWidget(
                texturePath: ceiling.texturePath,
                onTextureSelected: (path) {
                  ref.read(roomDesignProvider.notifier).updateCeiling(
                        ceiling.copyWith(texturePath: path),
                      );
                },
                onClear: ceiling.texturePath == null
                    ? null
                    : () => ref.read(roomDesignProvider.notifier).updateCeiling(
                          ceiling.copyWith(clearTexture: true),
                        ),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'False Ceiling',
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable False Ceiling'),
                value: ceiling.falseCeilingEnabled,
                onChanged: (v) => ref.read(roomDesignProvider.notifier).updateCeiling(
                      ceiling.copyWith(
                        falseCeilingEnabled: v,
                        falseCeilingType: v ? FalseCeilingType.singleLayer : FalseCeilingType.none,
                      ),
                    ),
              ),
              if (ceiling.falseCeilingEnabled) ...[
                DropdownButtonFormField<FalseCeilingType>(
                  value: ceiling.falseCeilingType,
                  decoration: const InputDecoration(labelText: 'False Ceiling Type'),
                  items: FalseCeilingType.values
                      .where((t) => t != FalseCeilingType.none)
                      .map((t) => DropdownMenuItem(value: t, child: Text(_label(t))))
                      .toList(),
                  onChanged: (t) {
                    if (t != null) {
                      ref.read(roomDesignProvider.notifier).updateCeiling(
                            ceiling.copyWith(falseCeilingType: t),
                          );
                    }
                  },
                ),
                _Slider(
                  label: 'Depth',
                  value: ceiling.falseCeilingDepth,
                  onChanged: (v) => ref.read(roomDesignProvider.notifier).updateCeiling(
                        ceiling.copyWith(falseCeilingDepth: v),
                      ),
                ),
                _Slider(
                  label: 'Thickness',
                  value: ceiling.falseCeilingThickness,
                  onChanged: (v) => ref.read(roomDesignProvider.notifier).updateCeiling(
                        ceiling.copyWith(falseCeilingThickness: v),
                      ),
                ),
                ColorPickerField(
                  label: 'False Ceiling Color',
                  colorHex: ceiling.falseCeilingColor,
                  onChanged: (c) => ref.read(roomDesignProvider.notifier).updateCeiling(
                        ceiling.copyWith(falseCeilingColor: c),
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _label(FalseCeilingType t) => switch (t) {
        FalseCeilingType.singleLayer => 'Single Layer',
        FalseCeilingType.doubleLayer => 'Double Layer',
        FalseCeilingType.cove => 'Cove Ceiling',
        FalseCeilingType.tray => 'Tray Ceiling',
        FalseCeilingType.floating => 'Floating Ceiling',
        FalseCeilingType.none => 'None',
      };
}

class _Slider extends StatelessWidget {
  const _Slider({required this.label, required this.value, required this.onChanged});

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: theme.textTheme.labelMedium),
            ),
            Text(
              '${value.toStringAsFixed(1)} ft',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Slider(value: value, min: 0.5, max: 3, onChanged: onChanged),
      ],
    );
  }
}
