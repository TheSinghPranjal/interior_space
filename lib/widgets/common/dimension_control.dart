import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dimension control with slider, stepper buttons, and numeric field.
class DimensionControl extends StatefulWidget {
  const DimensionControl({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1.0,
    this.suffix = 'ft',
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final double step;
  final String suffix;

  @override
  State<DimensionControl> createState() => _DimensionControlState();
}

class _DimensionControlState extends State<DimensionControl> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(1));
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant DimensionControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _controller.text = widget.value.toStringAsFixed(1);
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _commitText();
  }

  void _commitText() {
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed == null) {
      _controller.text = widget.value.toStringAsFixed(1);
      return;
    }
    final clamped = parsed.clamp(widget.min, widget.max).toDouble();
    _controller.text = clamped.toStringAsFixed(1);
    if (clamped != widget.value) widget.onChanged(clamped);
  }

  void _nudge(double delta) {
    final next = (widget.value + delta).clamp(widget.min, widget.max).toDouble();
    widget.onChanged(next);
    _controller.text = next.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clampedMax = widget.max < widget.min ? widget.min : widget.max;
    final sliderValue = widget.value.clamp(widget.min, clampedMax).toDouble();
    final divisions = ((clampedMax - widget.min) / widget.step).round().clamp(1, 400);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: 'Decrease',
              onPressed: widget.value <= widget.min ? null : () => _nudge(-widget.step),
            ),
            SizedBox(
              width: 72,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                ],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  suffixText: widget.suffix,
                  suffixStyle: Theme.of(context).textTheme.labelSmall,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _commitText(),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Increase',
              onPressed: widget.value >= clampedMax ? null : () => _nudge(widget.step),
            ),
          ],
        ),
        Slider(
          value: sliderValue,
          min: widget.min,
          max: clampedMax,
          divisions: divisions,
          onChanged: (v) {
            _controller.text = v.toStringAsFixed(1);
            widget.onChanged(v);
          },
        ),
      ],
    );
  }
}
