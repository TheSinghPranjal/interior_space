import 'package:flutter/material.dart';

class DimensionSlider extends StatelessWidget {
  const DimensionSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final clampedMax = max < min ? min : max;
    final enabled = onChanged != null;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${value.toStringAsFixed(1)} $suffix'),
          Slider(
            value: value.clamp(min, clampedMax).toDouble(),
            min: min,
            max: clampedMax,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
