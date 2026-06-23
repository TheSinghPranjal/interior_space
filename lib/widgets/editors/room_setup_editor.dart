import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/room_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/room_geometry.dart';
import '../../models/enums.dart';
import '../../providers/project_provider.dart';
import '../../providers/room_design_provider.dart';
import '../common/editor_item_card.dart';
import '../common/section_card.dart';

class RoomSetupEditor extends ConsumerWidget {
  const RoomSetupEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(roomDesignProvider);
    final dims = design.dimensions;
    final notifier = ref.read(roomDesignProvider.notifier);
    final geometry = RoomGeometry.fromDimensions(dims);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SectionCard(
          title: 'Room Dimensions',
          subtitle: dims.useCustomWallLengths
              ? 'Custom wall mode — individual wall lengths'
              : 'Standard mode — Width × Length × Height',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ModeBanner(useCustom: dims.useCustomWallLengths),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Custom Wall Dimensions'),
                subtitle: const Text(
                  'Set each wall length individually (Front, Back, Left, Right)',
                ),
                value: dims.useCustomWallLengths,
                onChanged: notifier.setCustomWallLengthsEnabled,
              ),
              if (!dims.useCustomWallLengths) ...[
                _DimensionSlider(
                  label: 'Width (Front & Back walls)',
                  value: dims.width,
                  min: RoomConstants.minWidth,
                  max: RoomConstants.maxWidth,
                  onChanged: (v) => notifier.updateDimensions(dims.copyWith(width: v)),
                ),
                _DimensionSlider(
                  label: 'Length (Left & Right walls)',
                  value: dims.length,
                  min: RoomConstants.minLength,
                  max: RoomConstants.maxLength,
                  onChanged: (v) => notifier.updateDimensions(dims.copyWith(length: v)),
                ),
              ] else ...[
                _DimensionSlider(
                  label: WallId.front.shortLabel,
                  value: dims.lengthForWall(WallId.front),
                  min: RoomConstants.minWidth,
                  max: RoomConstants.maxWidth,
                  onChanged: (v) => notifier.updateCustomWallLength(WallId.front, v),
                ),
                _DimensionSlider(
                  label: WallId.back.shortLabel,
                  value: dims.lengthForWall(WallId.back),
                  min: RoomConstants.minWidth,
                  max: RoomConstants.maxWidth,
                  onChanged: (v) => notifier.updateCustomWallLength(WallId.back, v),
                ),
                _DimensionSlider(
                  label: WallId.left.shortLabel,
                  value: dims.lengthForWall(WallId.left),
                  min: RoomConstants.minLength,
                  max: RoomConstants.maxLength,
                  onChanged: (v) => notifier.updateCustomWallLength(WallId.left, v),
                ),
                _DimensionSlider(
                  label: WallId.right.shortLabel,
                  value: dims.lengthForWall(WallId.right),
                  min: RoomConstants.minLength,
                  max: RoomConstants.maxLength,
                  onChanged: (v) => notifier.updateCustomWallLength(WallId.right, v),
                ),
                if (!geometry.isValid)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      geometry.validationMessage ?? 'Invalid wall configuration',
                      style: const TextStyle(color: AppTheme.warning, fontSize: 13),
                    ),
                  ),
              ],
              _DimensionSlider(
                label: 'Height',
                value: dims.height,
                min: RoomConstants.minHeight,
                max: RoomConstants.maxHeight,
                onChanged: (v) => notifier.updateDimensions(dims.copyWith(height: v)),
              ),
              if (dims.useCustomWallLengths && geometry.isValid) ...[
                const SizedBox(height: 8),
                _WallSummaryChip(
                  label: 'Floor footprint',
                  value:
                      '${geometry.boundingWidth.toStringAsFixed(1)} × ${geometry.boundingLength.toStringAsFixed(1)} ft',
                ),
                const EditorHelperText(
                  'Use the Walls editor to hide or shorten individual walls for open-plan layouts.',
                ),
              ],
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

class _ModeBanner extends StatelessWidget {
  const _ModeBanner({required this.useCustom});

  final bool useCustom;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: useCustom
            ? AppTheme.secondary.withValues(alpha: 0.18)
            : AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: useCustom
              ? AppTheme.secondary.withValues(alpha: 0.45)
              : AppTheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            useCustom ? Icons.architecture : Icons.crop_square,
            size: 16,
            color: useCustom ? AppTheme.accent : AppTheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              useCustom ? 'Custom wall dimensions active' : 'Standard rectangular room',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: useCustom ? AppTheme.accent : AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WallSummaryChip extends StatelessWidget {
  const _WallSummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(value, style: Theme.of(context).textTheme.labelLarge),
        ],
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
