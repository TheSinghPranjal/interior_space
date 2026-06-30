import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/room_constants.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../providers/project_provider.dart';
import '../../providers/room_design_provider.dart';
import '../../screens/custom_room_shape_screen.dart';
import '../../screens/custom_walls_editor_screen.dart';
import '../common/dimension_control.dart';
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
          child: _RoomIdentityFields(),
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
  bool _editingEnabled = false;

  @override
  Widget build(BuildContext context) {
    final design = ref.watch(roomDesignProvider);
    final dims = design.dimensions;
    final notifier = ref.read(roomDesignProvider.notifier);
    final useCustom = dims.useCustomWallLengths;
    final isPolygon = dims.isPolygon;
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 480;

    final dimensionSummary =
        '${formatDimensionFt(dims.width)} × ${formatDimensionFt(dims.length)} × ${formatDimensionFt(dims.height)} ft';

    final modeChipLabel = isPolygon
        ? (compact ? 'Custom polygon' : 'Custom polygon room')
        : useCustom
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
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    tooltip: _editingEnabled ? 'Lock dimensions' : 'Edit dimensions',
                    icon: Icon(
                      _editingEnabled ? Icons.edit_off_outlined : Icons.edit_outlined,
                      size: 18,
                    ),
                    style: IconButton.styleFrom(
                      foregroundColor:
                          _editingEnabled ? AppTheme.warning : theme.colorScheme.primary,
                      backgroundColor: _editingEnabled
                          ? AppTheme.warning.withValues(alpha: 0.12)
                          : theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                    ),
                    onPressed: () => setState(() => _editingEnabled = !_editingEnabled),
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
                    if (!_editingEnabled)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          'Tap edit to adjust width, length, and height.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    DimensionControl(
                      label: 'Width (Front & Back walls)',
                      value: dims.width,
                      min: RoomConstants.minWidth,
                      max: RoomConstants.maxWidth,
                      enabled: _editingEnabled && !isPolygon,
                      onChanged: (v) =>
                          notifier.updateDimensions(dims.copyWith(width: v)),
                    ),
                    DimensionControl(
                      label: 'Length (Left & Right walls)',
                      value: dims.length,
                      min: RoomConstants.minLength,
                      max: RoomConstants.maxLength,
                      enabled: _editingEnabled && !isPolygon,
                      onChanged: (v) =>
                          notifier.updateDimensions(dims.copyWith(length: v)),
                    ),
                    DimensionControl(
                      label: 'Height',
                      value: dims.height,
                      min: RoomConstants.minHeight,
                      max: RoomConstants.maxHeight,
                      enabled: _editingEnabled,
                      onChanged: (v) =>
                          notifier.updateDimensions(dims.copyWith(height: v)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Custom room shape', style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isPolygon
                          ? 'Polygon room with ${dims.polygonVertices.length} corners and '
                              '${dims.polygonVertices.length} walls.'
                          : 'Draw any shape (3+ walls) on a 20×20 ft grid. '
                              'Corners snap every ${RoomConstants.customRoomGridSnapFt} ft.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => const CustomRoomShapeScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.pentagon_outlined, size: 18),
                          label: Text(isPolygon ? 'Edit shape' : 'Draw custom room'),
                        ),
                        if (isPolygon)
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CustomWallsEditorScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.wallpaper_outlined, size: 18),
                            label: const Text('Edit walls'),
                          ),
                        if (isPolygon)
                          TextButton(
                            onPressed: () {
                              showDialog<void>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Switch to rectangular room?'),
                                  content: const Text(
                                    'This removes the custom polygon and resets to a standard 4-wall room.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        notifier.setRectangularRoom();
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text('Reset'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('Use rectangular room'),
                          ),
                      ],
                    ),
                    if (isPolygon)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          'Footprint: ${formatDimensionFt(dims.effectiveWidth)} × '
                          '${formatDimensionFt(dims.effectiveLength)} ft',
                          style: theme.textTheme.bodySmall,
                        ),
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

class _RoomIdentityFields extends ConsumerWidget {
  const _RoomIdentityFields();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _RoomNameField()),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: _RoomTypeField()),
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

class _RoomTypeField extends ConsumerWidget {
  const _RoomTypeField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(roomDesignProvider);
    final roomIndex = ref.watch(projectProvider).safeActiveIndex;

    return DropdownButtonFormField<RoomType>(
      key: ValueKey('room-type-$roomIndex-${design.roomType?.name}'),
      initialValue: design.roomType,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Room Type'),
      hint: const Text(
        'Select room type',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      selectedItemBuilder: (context) => RoomType.values
          .map(
            (type) => Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                type.label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      items: RoomType.values
          .map(
            (type) => DropdownMenuItem(
              value: type,
              child: Text(type.label),
            ),
          )
          .toList(),
      onChanged: ref.read(roomDesignProvider.notifier).setRoomType,
    );
  }
}
