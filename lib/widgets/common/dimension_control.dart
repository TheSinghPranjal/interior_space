import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Formats a dimension in feet (supports quarter-foot steps).
String formatDimensionFt(double value) {
  final rounded = (value * 4).round() / 4;
  if (rounded == rounded.roundToDouble()) {
    return rounded.toStringAsFixed(0);
  }
  return rounded.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}

/// Snaps [value] to the nearest [step] increment within [min]–[max].
double snapDimension(double value, {required double min, required double max, required double step}) {
  if (step <= 0) return value.clamp(min, max).toDouble();
  final steps = ((value - min) / step).round();
  return (min + steps * step).clamp(min, max).toDouble();
}

/// Dimension control with slider, stepper buttons, and numeric field.
class DimensionControl extends StatefulWidget {
  const DimensionControl({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 0.25,
    this.suffix = 'ft',
    this.enabled = true,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final double step;
  final String suffix;
  final bool enabled;

  @override
  State<DimensionControl> createState() => _DimensionControlState();
}

class _DimensionControlState extends State<DimensionControl> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: formatDimensionFt(widget.value));
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant DimensionControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _controller.text = formatDimensionFt(widget.value);
    }
    if (!widget.enabled && _focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _commitText();
  }

  void _commitText() {
    if (!widget.enabled) return;
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed == null) {
      _controller.text = formatDimensionFt(widget.value);
      return;
    }
    final snapped = snapDimension(
      parsed,
      min: widget.min,
      max: widget.max,
      step: widget.step,
    );
    _controller.text = formatDimensionFt(snapped);
    if (snapped != widget.value) widget.onChanged(snapped);
  }

  void _nudge(double delta) {
    if (!widget.enabled) return;
    final next = snapDimension(
      widget.value + delta,
      min: widget.min,
      max: widget.max,
      step: widget.step,
    );
    widget.onChanged(next);
    _controller.text = formatDimensionFt(next);
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
    final sliderValue = snapDimension(
      widget.value,
      min: widget.min,
      max: clampedMax,
      step: widget.step,
    );
    final divisions = ((clampedMax - widget.min) / widget.step).round().clamp(1, 400);
    final atMin = sliderValue <= widget.min + 1e-9;
    final atMax = sliderValue >= clampedMax - 1e-9;

    return Opacity(
      opacity: widget.enabled ? 1 : 0.55,
      child: Column(
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
                onPressed: !widget.enabled || atMin ? null : () => _nudge(-widget.step),
              ),
              SizedBox(
                width: 72,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  readOnly: !widget.enabled,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
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
                onPressed: !widget.enabled || atMax ? null : () => _nudge(widget.step),
              ),
            ],
          ),
          Slider(
            value: sliderValue,
            min: widget.min,
            max: clampedMax,
            divisions: divisions,
            onChanged: widget.enabled
                ? (v) {
                    final snapped = snapDimension(
                      v,
                      min: widget.min,
                      max: clampedMax,
                      step: widget.step,
                    );
                    _controller.text = formatDimensionFt(snapped);
                    widget.onChanged(snapped);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
