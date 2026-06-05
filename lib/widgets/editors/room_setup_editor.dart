import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/room_constants.dart';
import '../../providers/project_provider.dart';
import '../../providers/room_design_provider.dart';
import '../common/section_card.dart';

class RoomSetupEditor extends ConsumerWidget {
  const RoomSetupEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(roomDesignProvider);
    final dims = design.dimensions;

    return ListView(
      children: [
        SectionCard(
          title: 'Room Dimensions',
          subtitle: 'Default: 16 × 8 × 10 ft',
          child: Column(
            children: [
              _DimensionSlider(
                label: 'Width',
                value: dims.width,
                min: RoomConstants.minWidth,
                max: RoomConstants.maxWidth,
                onChanged: (v) => ref.read(roomDesignProvider.notifier).updateDimensions(
                      dims.copyWith(width: v),
                    ),
              ),
              _DimensionSlider(
                label: 'Length',
                value: dims.length,
                min: RoomConstants.minLength,
                max: RoomConstants.maxLength,
                onChanged: (v) => ref.read(roomDesignProvider.notifier).updateDimensions(
                      dims.copyWith(length: v),
                    ),
              ),
              _DimensionSlider(
                label: 'Height',
                value: dims.height,
                min: RoomConstants.minHeight,
                max: RoomConstants.maxHeight,
                onChanged: (v) => ref.read(roomDesignProvider.notifier).updateDimensions(
                      dims.copyWith(height: v),
                    ),
              ),
            ],
          ),
        ),
        const SectionCard(
          title: 'Room',
          child: _RoomNameField(),
        ),
        SectionCard(
          title: 'AI Assistant (Future Ready)',
          subtitle: 'Try: "Make room modern" or "Generate luxury bedroom"',
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Design prompt',
              hintText: 'Describe your ideal room...',
              suffixIcon: Icon(Icons.auto_awesome),
            ),
            onSubmitted: ref.read(roomDesignProvider.notifier).applyAiSuggestion,
          ),
        ),
      ],
    );
  }
}

class _RoomNameField extends ConsumerStatefulWidget {
  const _RoomNameField();

  @override
  ConsumerState<_RoomNameField> createState() => _RoomNameFieldState();
}

class _RoomNameFieldState extends ConsumerState<_RoomNameField> {
  TextEditingController? _controller;
  int? _trackedRoomIndex;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final design = ref.watch(roomDesignProvider);
    final roomIndex = ref.watch(projectProvider).safeActiveIndex;

    _controller ??= TextEditingController(text: design.name);
    _trackedRoomIndex ??= roomIndex;

    if (_trackedRoomIndex != roomIndex) {
      _trackedRoomIndex = roomIndex;
      _controller!
        ..text = design.name
        ..selection = TextSelection.collapsed(offset: design.name.length);
    }

    return TextField(
      controller: _controller,
      decoration: const InputDecoration(labelText: 'Room Name'),
      onChanged: ref.read(roomDesignProvider.notifier).setName,
    );
  }
}

class _DimensionSlider extends StatelessWidget {
  const _DimensionSlider({
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('${value.toStringAsFixed(1)} ft'),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: ((max - min) * 2).toInt(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
