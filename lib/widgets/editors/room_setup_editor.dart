import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/room_constants.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/project_provider.dart';
import '../../providers/room_design_provider.dart';
import '../common/section_card.dart';

class RoomSetupEditor extends ConsumerWidget {
  const RoomSetupEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: const [
        _RoomDimensionsSection(),
        SectionCard(
          title: 'Room',
          child: _RoomNameField(),
        ),
        _AiAssistantSection(),
      ],
    );
  }
}

class _RoomDimensionsSection extends ConsumerStatefulWidget {
  const _RoomDimensionsSection();

  @override
  ConsumerState<_RoomDimensionsSection> createState() =>
      _RoomDimensionsSectionState();
}

class _RoomDimensionsSectionState extends ConsumerState<_RoomDimensionsSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final design = ref.watch(roomDesignProvider);
    final dims = design.dimensions;
    final notifier = ref.read(roomDesignProvider.notifier);
    final useCustom = dims.useCustomWallLengths;
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 480;

    final dimensionSummary =
        '${dims.width.toStringAsFixed(1)} × ${dims.length.toStringAsFixed(1)} × ${dims.height.toStringAsFixed(1)} ft';

    final modeChipLabel = useCustom
        ? (compact ? 'Custom walls' : 'Custom wall visibility active')
        : (compact ? 'Standard room' : 'Standard rectangular room dimensions');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.55)),
          boxShadow: AppSpacing.cardShadow(context),
        ),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('Room Dimensions', style: theme.textTheme.titleMedium),
                        _DimensionModeChip(
                          useCustom: useCustom,
                          label: modeChipLabel,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    tooltip: _expanded ? 'Hide dimensions' : 'Show dimensions',
                    onPressed: () => setState(() => _expanded = !_expanded),
                    icon: AnimatedRotation(
                      turns: _expanded ? 0 : 0.5,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down, size: 20),
                    ),
                  ),
                ],
              ),
              if (!_expanded)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(dimensionSummary, style: theme.textTheme.bodySmall),
                ),
              AnimatedCrossFade(
                firstCurve: Curves.easeOut,
                secondCurve: Curves.easeIn,
                sizeCurve: Curves.easeInOut,
                crossFadeState:
                    _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 200),
                firstChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    _DimensionSlider(
                      label: 'Width (Front & Back walls)',
                      value: dims.width,
                      min: RoomConstants.minWidth,
                      max: RoomConstants.maxWidth,
                      onChanged: (v) =>
                          notifier.updateDimensions(dims.copyWith(width: v)),
                    ),
                    _DimensionSlider(
                      label: 'Length (Left & Right walls)',
                      value: dims.length,
                      min: RoomConstants.minLength,
                      max: RoomConstants.maxLength,
                      onChanged: (v) =>
                          notifier.updateDimensions(dims.copyWith(length: v)),
                    ),
                    _DimensionSlider(
                      label: 'Height',
                      value: dims.height,
                      min: RoomConstants.minHeight,
                      max: RoomConstants.maxHeight,
                      onChanged: (v) =>
                          notifier.updateDimensions(dims.copyWith(height: v)),
                    ),
                  ],
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DimensionModeChip extends StatelessWidget {
  const _DimensionModeChip({
    required this.useCustom,
    required this.label,
  });

  final bool useCustom;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Chip(
      avatar: Icon(
        useCustom ? Icons.architecture : Icons.crop_square,
        size: 14,
        color: useCustom ? AppTheme.accent : AppTheme.primary,
      ),
      label: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      backgroundColor: useCustom
          ? AppTheme.secondary.withValues(alpha: 0.18)
          : AppTheme.primary.withValues(alpha: 0.08),
      side: BorderSide(
        color: useCustom
            ? AppTheme.secondary.withValues(alpha: 0.45)
            : AppTheme.primary.withValues(alpha: 0.2),
      ),
    );
  }
}

class _AiAssistantSection extends ConsumerWidget {
  const _AiAssistantSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
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
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)} ft',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primary,
                  ),
            ),
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
