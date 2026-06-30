import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../common/color_picker_field.dart';
import '../common/editor_item_card.dart';

/// Barrier type selector for custom wall mode (fence / balcony railing).
class WallBarrierTypeField extends StatelessWidget {
  const WallBarrierTypeField({
    super.key,
    required this.barrierType,
    required this.colorHex,
    required this.onBarrierTypeChanged,
    required this.onColorChanged,
  });

  final WallBarrierType barrierType;
  final String colorHex;
  final ValueChanged<WallBarrierType> onBarrierTypeChanged;
  final ValueChanged<String> onColorChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wall type',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<WallBarrierType>(
          segments: WallBarrierType.values
              .map(
                (type) => ButtonSegment(
                  value: type,
                  label: Text(type.label),
                ),
              )
              .toList(),
          selected: {barrierType},
          onSelectionChanged: (selection) {
            onBarrierTypeChanged(selection.first);
          },
        ),
        const SizedBox(height: 8),
        const EditorHelperText(
          'Choose fence or balcony railing for open edges — e.g. balcony, terrace, or garden side.',
        ),
        if (barrierType != WallBarrierType.solid) ...[
          const SizedBox(height: 12),
          ColorPickerField(
            label: 'Barrier color',
            colorHex: colorHex,
            onChanged: onColorChanged,
          ),
        ],
        const Divider(height: 24),
      ],
    );
  }
}
