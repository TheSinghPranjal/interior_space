import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../core/utils/color_utils.dart';

class ColorPickerField extends StatelessWidget {
  const ColorPickerField({
    super.key,
    required this.label,
    required this.colorHex,
    required this.onChanged,
  });

  final String label;
  final String colorHex;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.fromHex(colorHex);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        '${ColorUtils.toHex(color)}  •  '
        'RGB(${(color.r * 255).round()}, ${(color.g * 255).round()}, ${(color.b * 255).round()})',
      ),
      trailing: GestureDetector(
        onTap: () => _showPicker(context, color),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
      ),
      onTap: () => _showPicker(context, color),
    );
  }

  void _showPicker(BuildContext context, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick $label'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: color,
            onColorChanged: (c) => onChanged(ColorUtils.toHex(c)),
            enableAlpha: false,
            displayThumbColor: true,
            pickerAreaHeightPercent: 0.7,
            hexInputBar: true,
            labelTypes: const [ColorLabelType.rgb, ColorLabelType.hsv, ColorLabelType.hex],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
